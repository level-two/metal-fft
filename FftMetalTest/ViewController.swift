//
//  ViewController.swift
//  MetalTestApp
//
//  Created by Yauheni Lychkouski on 2/19/20.
//  Copyright © 2020 Yauheni Lychkouski. All rights reserved.
//

import Cocoa
import Metal

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let order = 12
        let samplesNum = 1 << order
        let sampleRate = Float(44100.0)
        let toneFreq = Float(1234.0)

        guard let device = MTLCreateSystemDefaultDevice(),
            let defaultLibrary = device.makeDefaultLibrary(),
            let fftFunction = defaultLibrary.makeFunction(name: "fft"),
            let pipelineState = try? device.makeComputePipelineState(function: fftFunction),
            let commandQueue = device.makeCommandQueue(),
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let computeEncoder = commandBuffer.makeComputeCommandEncoder()
            else { fatalError() }

        let argumentEncoder = fftFunction.makeArgumentEncoder(bufferIndex: 0)
        let argumentBufferLength = argumentEncoder.encodedLength
        let argumentBuffer = device.makeBuffer(length: argumentBufferLength, options: [])
        argumentEncoder.setArgumentBuffer(argumentBuffer, offset: 0)
        let orderArgument = argumentEncoder.constantData(at: 0).assumingMemoryBound(to: Int.self)
        orderArgument.pointee = order

        let bufferSize = samplesNum * MemoryLayout<Float>.size
        guard let inputBuffer = device.makeBuffer(length: bufferSize, options: .storageModeShared),
            let stepBuffer = device.makeBuffer(length: bufferSize * 2, options: .storageModePrivate),
            let resultBuffer = device.makeBuffer(length: bufferSize, options: .storageModeShared)
            else { fatalError() }

        let inputBufferContent = inputBuffer.contents().assumingMemoryBound(to: Float.self)
        for i in 0 ..< samplesNum {
            inputBufferContent[i] = sin(2 * .pi * Float(i) * toneFreq / sampleRate)
        }

        print("🔥")

        computeEncoder.setComputePipelineState(pipelineState)
        computeEncoder.setBuffer(argumentBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(inputBuffer, offset: 0, index: 1)
        computeEncoder.setBuffer(stepBuffer, offset: 0, index: 2)
        computeEncoder.setBuffer(resultBuffer, offset: 0, index: 3)

        let gridSize = MTLSizeMake(bufferSize, 1, 1)
        let threadGroupSize = MTLSizeMake(min(pipelineState.maxTotalThreadsPerThreadgroup, bufferSize), 1, 1)

        computeEncoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadGroupSize)
        computeEncoder.endEncoding()

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        print("🔥🔥")

        let resultBufContents = resultBuffer.contents().assumingMemoryBound(to: Float.self)

        var resultArray = [Float](repeating: 0, count: samplesNum)
        for i in 0..<samplesNum {
            resultArray[i] = resultBufContents[i]
        }

        print("\(resultArray)")

        exit(0)
    }
}

