//
//  ViewController.swift
//  MetalTestApp
//
//  Created by Yauheni Lychkouski on 2/19/20.
//  Copyright © 2020 Yauheni Lychkouski. All rights reserved.
//

import Metal

final class SamplingFourierCalculator {
    weak var delegate: SamplingFourierCalculatorDelegate?

    init?(order: Int) {
        self.order = order
        self.samplesNum = 1 << order
        self.reorderedSamples = [Float32].init(repeating: 0, count: samplesNum)

        guard
            let device = MTLCreateSystemDefaultDevice(),
            let defaultLibrary = device.makeDefaultLibrary(),
            let fftFunction = defaultLibrary.makeFunction(name: "fftStep"),
            let pipelineState = try? device.makeComputePipelineState(function: fftFunction),
            let commandQueue = device.makeCommandQueue()
            else { return nil }

        self.device = device
        self.defaultLibrary = defaultLibrary
        self.fftFunction = fftFunction
        self.pipelineState = pipelineState
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
    }

    func addSamples(_ samples: [Double]) {
        for idx in 0..<samples.count {
            let inversedSampleIndex = sampleIndex.binaryInversed(numberOfDigits: order)
            reorderedSamples[inversedSampleIndex] = Float32(samples[idx])
            sampleIndex += 1
            if sampleIndex == reorderedSamples.count {
                sampleIndex = 0
                claculateFourier()
            }
        }
    }

    private let samplesNum: Int
    private let order: Int

    private let device: MTLDevice
    private let defaultLibrary: MTLLibrary
    private let fftFunction: MTLFunction
    private let pipelineState: MTLComputePipelineState
    private let commandQueue: MTLCommandQueue

    private let sharedBuffer: MTLBuffer
    private let privateBuffer1: MTLBuffer
    private let privateBuffer2: MTLBuffer

    private var reorderedSamples: [Float32]
    private var sampleIndex: Int = 0
}

extension SamplingFourierCalculator {

    fileprivate func claculateFourier() {
        let commandBuffer = commandQueue.makeCommandBuffer()

        let inputBufferContents = sharedBuffer.contents().assumingMemoryBound(to: Float32.self)
        for i in 0 ..< samplesNum {
            inputBufferContents[i << 1] = reorderedSamples[i]
            inputBufferContents[(i << 1) + 1] = 0
        }

        // copy input to the private buffer
        let inputCopyCommandEncoder = commandBuffer?.makeBlitCommandEncoder()
        inputCopyCommandEncoder?.copy(from: sharedBuffer, sourceOffset: 0,
                                      to: privateBuffer1, destinationOffset: 0,
                                      size: samplesNum)
        inputCopyCommandEncoder?.endEncoding()

        let gridSize = MTLSizeMake(samplesNum, 1, 1)
        let threadGroupSize = MTLSizeMake(min(pipelineState.maxTotalThreadsPerThreadgroup, samplesNum), 1, 1)
        let buf = [privateBuffer1, privateBuffer2]

        for step in 0..<order {
            let argEncoder = fftFunction.makeArgumentEncoder(bufferIndex: 0)
            let argBuffer = device.makeBuffer(length: argEncoder.encodedLength, options: [])
            argEncoder.setArgumentBuffer(argBuffer, offset: 0)
            argEncoder.constantData(at: 0).assumingMemoryBound(to: Int32.self).pointee = Int32(order)
            argEncoder.constantData(at: 1).assumingMemoryBound(to: Int32.self).pointee = Int32(step)
            argEncoder.constantData(at: 2).assumingMemoryBound(to: Int32.self).pointee = Int32(samplesNum)

            let computeEncoder = commandBuffer?.makeComputeCommandEncoder()
            computeEncoder?.setComputePipelineState(pipelineState)
            computeEncoder?.setBuffer(argBuffer, offset: 0, index: 0)
            computeEncoder?.setBuffer(buf[step % 2], offset: 0, index: 1)
            computeEncoder?.setBuffer(buf[(step+1) % 2], offset: 0, index: 2)
            computeEncoder?.dispatchThreads(gridSize, threadsPerThreadgroup: threadGroupSize)
            computeEncoder?.endEncoding()
        }

        // TODO: later change it to calculating of modulus and returnign result in the shared buffer
        // if there will be no way to calculate fft using single call to compute kernel

        let outputCopyCommandEncoder = commandBuffer?.makeBlitCommandEncoder()
        outputCopyCommandEncoder?.copy(from: buf[order % 2], sourceOffset: 0,
                                       to: sharedBuffer, destinationOffset: 0,
                                       size: samplesNum)
        outputCopyCommandEncoder?.endEncoding()

        commandBuffer?.addCompletedHandler { [weak self] _ in
            guard let self = self else { return }
            print("🔥")

            let resultContent = self.sharedBuffer.contents().assumingMemoryBound(to: Float32.self)
            var resultData = [Double].init(repeating: 0, count: self.samplesNum)
            for i in 0..<self.samplesNum {
                let modulus = sqrt(resultContent[i*2]*resultContent[i*2] + resultContent[i*2+1]*resultContent[i*2+1])
                resultData[i] = Double(modulus)
            }

            self.delegate?.onFourierCalculated(resultData)
        }

        commandBuffer?.commit()
    }
}
