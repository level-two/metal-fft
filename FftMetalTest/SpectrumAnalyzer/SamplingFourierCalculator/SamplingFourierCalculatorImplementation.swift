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
            let modLgFunction = defaultLibrary.makeFunction(name: "modLg"),
            let modLgPipelineState = try? device.makeComputePipelineState(function: modLgFunction),
            let commandQueue = device.makeCommandQueue()
            else { return nil }

        self.device = device
        self.defaultLibrary = defaultLibrary
        self.fftFunction = fftFunction
        self.fftPipelineState = fftPipelineState
        self.modLgFunction = modLgFunction
        self.modLgPipelineState = modLgPipelineState
        self.commandQueue = commandQueue

        let bufferSize = samplesNum * MemoryLayout<Float32>.size * 2

        guard
            let sharedBuffer = device.makeBuffer(length: bufferSize, options: .storageModeShared),
            let privateBuffer1 = device.makeBuffer(length: bufferSize, options: .storageModePrivate),
            let privateBuffer2 = device.makeBuffer(length: bufferSize, options: .storageModePrivate)
            else { return nil }

        self.sharedBuffer = sharedBuffer
        self.privateBuffer1 = privateBuffer1
        self.privateBuffer2 = privateBuffer2

        setupBindings()
    }

    private let samplesNum: Int
    private let order: Int

    private let device: MTLDevice
    private let defaultLibrary: MTLLibrary
    private let fftFunction: MTLFunction
    private let fftPipelineState: MTLComputePipelineState
    private let modLgFunction: MTLFunction
    private let modLgPipelineState: MTLComputePipelineState
    private let commandQueue: MTLCommandQueue

    private let sharedBuffer: MTLBuffer
    private let privateBuffer1: MTLBuffer
    private let privateBuffer2: MTLBuffer

    private var reorderedSamples: [Float32]
    private var sampleIndex: Int = 0

    private var isRunning = false
}

fileprivate extension SamplingFourierCalculatorImplementation {

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
            inputBufferContents[i << 1] = reorderedSamples[i]
            inputBufferContents[(i << 1) + 1] = 0
        }

        let commandBuffer = commandQueue.makeCommandBuffer()

        commandBuffer?.blitCommand {
            let bufferSize = samplesNum * MemoryLayout<Float32>.size * 2
            $0.copy(from: sharedBuffer, sourceOffset: 0, to: privateBuffer1, destinationOffset: 0, size: bufferSize)
        }

        for step in 0..<order {
            let argEncoder = fftFunction.makeArgumentEncoder(bufferIndex: 0)
            let argBuffer = device.makeBuffer(length: argEncoder.encodedLength, options: [])
            argEncoder.setArgumentBuffer(argBuffer, offset: 0)
            argEncoder.constantData(at: 0).assumingMemoryBound(to: Int32.self).pointee = Int32(order)
            argEncoder.constantData(at: 1).assumingMemoryBound(to: Int32.self).pointee = Int32(step)
            argEncoder.constantData(at: 2).assumingMemoryBound(to: Int32.self).pointee = Int32(samplesNum)

            let inputBuffer = step.even ? privateBuffer1 : privateBuffer2
            let resultBuffer = step.even ? privateBuffer2 : privateBuffer1

            let gridSize = MTLSizeMake(samplesNum, 1, 1)
            let threadGroupSize = MTLSizeMake(min(fftPipelineState.maxTotalThreadsPerThreadgroup, samplesNum), 1, 1)

            commandBuffer?.computeCommand(fftPipelineState) {
                $0.setBuffer(argBuffer, offset: 0, index: 0)
                $0.setBuffer(inputBuffer, offset: 0, index: 1)
                $0.setBuffer(resultBuffer, offset: 0, index: 2)
                $0.dispatchThreads(gridSize, threadsPerThreadgroup: threadGroupSize)
            }
        }

        let gridSize = MTLSizeMake(samplesNum/2, 1, 1)
        let threadGroupSize = MTLSizeMake(min(modLgPipelineState.maxTotalThreadsPerThreadgroup, samplesNum/2), 1, 1)
        let inputBuffer = order.even ? privateBuffer1 : privateBuffer2

        commandBuffer?.computeCommand(modLgPipelineState) {
            $0.setBuffer(inputBuffer, offset: 0, index: 0)
            $0.setBuffer(sharedBuffer, offset: 0, index: 1)
            $0.dispatchThreads(gridSize, threadsPerThreadgroup: threadGroupSize)
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
