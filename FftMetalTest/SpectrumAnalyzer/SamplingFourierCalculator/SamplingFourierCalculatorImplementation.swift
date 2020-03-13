//
//  ViewController.swift
//  MetalTestApp
//
//  Created by Yauheni Lychkouski on 2/19/20.
//  Copyright © 2020 Yauheni Lychkouski. All rights reserved.
//

import Metal

final class SamplingFourierCalculatorImplementation: SamplingFourierCalculator {
    let inputSamples = Pipe<[Double]>()
    let outputSpectrum = Pipe<[Double]>()

    init?(order: Int) {
        self.order = order
        self.samplesNum = 1 << order
        self.reorderedSamples = [Float32].init(repeating: 0, count: samplesNum)

        guard
            let device = MTLCreateSystemDefaultDevice(),
            let defaultLibrary = device.makeDefaultLibrary(),
            let fftFunction = defaultLibrary.makeFunction(name: "fftStep"),
            let fftPipelineState = try? device.makeComputePipelineState(function: fftFunction),
            let modulusFunction = defaultLibrary.makeFunction(name: "modulus"),
            let modulusPipelineState = try? device.makeComputePipelineState(function: modulusFunction),
            let commandQueue = device.makeCommandQueue()
            else { return nil }

        self.device = device
        self.defaultLibrary = defaultLibrary
        self.fftFunction = fftFunction
        self.fftPipelineState = fftPipelineState
        self.modulusFunction = modulusFunction
        self.modulusPipelineState = modulusPipelineState
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
    private let modulusFunction: MTLFunction
    private let modulusPipelineState: MTLComputePipelineState
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
                self.reorderedSamples[inversedSampleIndex] = Float32(samples[idx])
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

        let commandBuffer = commandQueue.makeCommandBuffer()

        let inputBufferContents = sharedBuffer.contents().assumingMemoryBound(to: Float32.self)
        for i in 0 ..< samplesNum {
            inputBufferContents[i << 1] = reorderedSamples[i]
            inputBufferContents[(i << 1) + 1] = 0
        }

        // copy input to the private buffer
        let inputCopyCommandEncoder = commandBuffer?.makeBlitCommandEncoder()
        let bufferSize = samplesNum * MemoryLayout<Float32>.size * 2
        inputCopyCommandEncoder?.copy(from: sharedBuffer, sourceOffset: 0,
                                      to: privateBuffer1, destinationOffset: 0,
                                      size: bufferSize)
        inputCopyCommandEncoder?.endEncoding()

        let gridSize = MTLSizeMake(samplesNum, 1, 1)
        let threadGroupSize = MTLSizeMake(min(fftPipelineState.maxTotalThreadsPerThreadgroup, samplesNum), 1, 1)
        let buf = [privateBuffer1, privateBuffer2]

        for step in 0..<order {
            let inputBuffer = buf[step % 2]
            let resultBuffer = buf[(step+1) % 2]

            let argEncoder = fftFunction.makeArgumentEncoder(bufferIndex: 0)
            let argBuffer = device.makeBuffer(length: argEncoder.encodedLength, options: [])
            
            argEncoder.setArgumentBuffer(argBuffer, offset: 0)
            argEncoder.constantData(at: 0).assumingMemoryBound(to: Int32.self).pointee = Int32(order)
            argEncoder.constantData(at: 1).assumingMemoryBound(to: Int32.self).pointee = Int32(step)
            argEncoder.constantData(at: 2).assumingMemoryBound(to: Int32.self).pointee = Int32(samplesNum)

            let computeEncoder = commandBuffer?.makeComputeCommandEncoder()
            computeEncoder?.setComputePipelineState(fftPipelineState)
            computeEncoder?.setBuffer(argBuffer, offset: 0, index: 0)
            computeEncoder?.setBuffer(inputBuffer, offset: 0, index: 1)
            computeEncoder?.setBuffer(resultBuffer, offset: 0, index: 2)
            computeEncoder?.dispatchThreads(gridSize, threadsPerThreadgroup: threadGroupSize)
            computeEncoder?.endEncoding()
        }

        let modulusGridSize = MTLSizeMake(samplesNum/2, 1, 1)
        let modulusThreadGroupSize = MTLSizeMake(min(modulusPipelineState.maxTotalThreadsPerThreadgroup, samplesNum/2), 1, 1)
        let modulusEncoder = commandBuffer?.makeComputeCommandEncoder()
        modulusEncoder?.setComputePipelineState(modulusPipelineState)
        modulusEncoder?.setBuffer(buf[order % 2], offset: 0, index: 0)
        modulusEncoder?.setBuffer(sharedBuffer, offset: 0, index: 1)
        modulusEncoder?.dispatchThreads(modulusGridSize, threadsPerThreadgroup: modulusThreadGroupSize)
        modulusEncoder?.endEncoding()

        commandBuffer?.addCompletedHandler { [weak self] _ in
            guard let self = self else { return }

            let resultContent = self.sharedBuffer.contents().assumingMemoryBound(to: Float32.self)
            var spectrumData = [Double].init(repeating: 0, count: self.samplesNum/2)
            for i in 0 ..< self.samplesNum/2 {
                spectrumData[i] = Double(resultContent[i])
            }
            self.outputSpectrum.push(spectrumData)
            self.isRunning = false
        }

        commandBuffer?.commit()
    }
}
