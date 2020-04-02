//
//  ViewController.swift
//  MetalTestApp
//
//  Created by Yauheni Lychkouski on 2/19/20.
//  Copyright © 2020 Yauheni Lychkouski. All rights reserved.
//

import Metal

final class SamplingFourierCalculatorImplementation: SamplingFourierCalculator {
    let inputSamples = Pipe<[Float32]>()
    let outputSpectrum = Pipe<[Float32]>()

    init?(order: Int) {
        self.order = order
        self.samplesNum = 1 << order
        self.reorderedSamples = [Float32].init(repeating: 0, count: samplesNum)

        guard
            let device = MTLCreateSystemDefaultDevice(),
            let defaultLibrary = device.makeDefaultLibrary(),
            let fftFunction = defaultLibrary.makeFunction(name: "fftStep"),
            let fftPipelineState = try? device.makeComputePipelineState(function: fftFunction),
            let applyWindowFunction = defaultLibrary.makeFunction(name: "applyWindow"),
            let applyWindowPipelineState = try? device.makeComputePipelineState(function: applyWindowFunction),
            let dbFsFunction = defaultLibrary.makeFunction(name: "dbFs"),
            let dbFsPipelineState = try? device.makeComputePipelineState(function: dbFsFunction),
            let commandQueue = device.makeCommandQueue()
            else { return nil }

        self.device = device
        self.defaultLibrary = defaultLibrary
        self.fftFunction = fftFunction
        self.fftPipelineState = fftPipelineState
        self.applyWindowFunction = applyWindowFunction
        self.applyWindowPipelineState = applyWindowPipelineState
        self.dbFsFunction = dbFsFunction
        self.dbFsPipelineState = dbFsPipelineState
        self.commandQueue = commandQueue

        let bufferSize = samplesNum * MemoryLayout<Float32>.size * 2

        guard
            let sharedBuffer = device.makeBuffer(length: bufferSize, options: .storageModeShared),
            let windowBuffer = device.makeBuffer(length: bufferSize/2, options: .storageModeShared),
            let privateBuffer1 = device.makeBuffer(length: bufferSize, options: .storageModePrivate),
            let privateBuffer2 = device.makeBuffer(length: bufferSize, options: .storageModePrivate)
            else { return nil }

        self.sharedBuffer = sharedBuffer
        self.windowBuffer = windowBuffer
        self.privateBuffer1 = privateBuffer1
        self.privateBuffer2 = privateBuffer2

        setupWindowFunction()
        setupBindings()
        //testRun()
    }

    private let samplesNum: Int
    private let order: Int

    private let device: MTLDevice
    private let defaultLibrary: MTLLibrary

    private let fftFunction: MTLFunction
    private let fftPipelineState: MTLComputePipelineState
    private let applyWindowFunction: MTLFunction
    private let applyWindowPipelineState: MTLComputePipelineState
    private let dbFsFunction: MTLFunction
    private let dbFsPipelineState: MTLComputePipelineState

    private let commandQueue: MTLCommandQueue

    private let sharedBuffer: MTLBuffer
    private let windowBuffer: MTLBuffer
    private var windowSum: Float32 = 0
    private let fullScaleValue: Float32 = 2 // as sample can have values in range -1...1
    private let privateBuffer1: MTLBuffer
    private let privateBuffer2: MTLBuffer

    private var reorderedSamples: [Float32]
    private var sampleIndex: Int = 0

    private var isRunning = false
}

fileprivate extension SamplingFourierCalculatorImplementation {
    func setupWindowFunction() {
        let windowBufferContents = windowBuffer.contents().assumingMemoryBound(to: Float32.self)
        for i in 0 ..< samplesNum {
            windowBufferContents[i] = 1
        }
        windowSum = Float32(samplesNum)
    }

    func setupBindings() {
        inputSamples.bind { [unowned self] samples in
            for idx in 0..<samples.count {
                let inversedSampleIndex = self.sampleIndex.binaryInversed(numberOfDigits: self.order)
                self.reorderedSamples[inversedSampleIndex] = samples[idx]
                self.sampleIndex += 1
                if self.sampleIndex == self.samplesNum {
                    self.sampleIndex = 0
                    self.claculateFourier()
                }
            }
        }
    }

    func claculateFourier() {
        guard !isRunning else { return print("💩") }
        isRunning = true

        let inputBufferContents = sharedBuffer.contents().assumingMemoryBound(to: Float32.self)
        for i in 0 ..< samplesNum {
            inputBufferContents[i] = reorderedSamples[i]
        }

        let commandBuffer = commandQueue.makeCommandBuffer()

        commandBuffer?.computeCommand(applyWindowPipelineState) { encoder in
            encoder.setBuffer(sharedBuffer, offset: 0, index: 0)
            encoder.setBuffer(windowBuffer, offset: 0, index: 1)
            encoder.setBuffer(privateBuffer1, offset: 0, index: 2)
            encoder.dispatchThreads(MTLSizeMake(samplesNum, 1, 1),
                threadsPerThreadgroup: MTLSizeMake(min(applyWindowPipelineState.maxTotalThreadsPerThreadgroup, samplesNum), 1, 1))
        }

        for step in 0..<order {
            commandBuffer?.computeCommand(fftPipelineState) { encoder in
                let argEncoder = fftFunction.makeArgumentEncoder(bufferIndex: 0)
                let argBuffer = device.makeBuffer(length: argEncoder.encodedLength, options: [])
                argEncoder.setArgumentBuffer(argBuffer, offset: 0)
                argEncoder.constantData(at: 0).assumingMemoryBound(to: Int32.self).pointee = Int32(order)
                argEncoder.constantData(at: 1).assumingMemoryBound(to: Int32.self).pointee = Int32(step)
                argEncoder.constantData(at: 2).assumingMemoryBound(to: Int32.self).pointee = Int32(samplesNum)

                let inputBuffer = step.even ? privateBuffer1 : privateBuffer2
                let resultBuffer = step.even ? privateBuffer2 : privateBuffer1
                encoder.setBuffer(argBuffer, offset: 0, index: 0)
                encoder.setBuffer(inputBuffer, offset: 0, index: 1)
                encoder.setBuffer(resultBuffer, offset: 0, index: 2)
                encoder.dispatchThreads(MTLSizeMake(samplesNum, 1, 1),
                    threadsPerThreadgroup: MTLSizeMake(min(fftPipelineState.maxTotalThreadsPerThreadgroup, samplesNum), 1, 1))
            }
        }

        commandBuffer?.computeCommand(dbFsPipelineState) { encoder in
            let argEncoder = dbFsFunction.makeArgumentEncoder(bufferIndex: 0)
            let argBuffer = device.makeBuffer(length: argEncoder.encodedLength, options: [])
            argEncoder.setArgumentBuffer(argBuffer, offset: 0)
            argEncoder.constantData(at: 0).assumingMemoryBound(to: Float32.self).pointee = windowSum
            argEncoder.constantData(at: 1).assumingMemoryBound(to: Float32.self).pointee = fullScaleValue
            encoder.setBuffer(argBuffer, offset: 0, index: 0)

            let inputBuffer = order.even ? privateBuffer1 : privateBuffer2
            encoder.setBuffer(inputBuffer, offset: 0, index: 1)
            encoder.setBuffer(sharedBuffer, offset: 0, index: 2)
            encoder.dispatchThreads(MTLSizeMake(samplesNum/2, 1, 1),
                threadsPerThreadgroup: MTLSizeMake(min(dbFsPipelineState.maxTotalThreadsPerThreadgroup, samplesNum/2), 1, 1))
        }

        commandBuffer?.addCompletedHandler { [weak self] _ in
            guard let self = self else { return }

            let resultContent = self.sharedBuffer.contents().assumingMemoryBound(to: Float32.self)
            var spectrumData = [Float32].init(repeating: 0, count: self.samplesNum/2)
            for i in 0 ..< self.samplesNum/2 {
                spectrumData[i] = resultContent[i]
            }
            self.outputSpectrum.push(spectrumData)
            self.isRunning = false
        }

        commandBuffer?.commit()
    }
}
