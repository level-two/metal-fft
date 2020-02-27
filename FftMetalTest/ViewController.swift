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
            let fftFunction = defaultLibrary.makeFunction(name: "fftStep"),
            let pipelineState = try? device.makeComputePipelineState(function: fftFunction),
            let commandQueue = device.makeCommandQueue(),
            let commandBuffer = commandQueue.makeCommandBuffer()
            else { fatalError() }

        let bufferSize = samplesNum * MemoryLayout<Float32>.size * 2
        guard let buffer1 = device.makeBuffer(length: bufferSize, options: .storageModeShared),
            let buffer2 = device.makeBuffer(length: bufferSize, options: .storageModeShared)
            else { fatalError() }

        let inputContent = buffer1.contents().assumingMemoryBound(to: Float32.self)
        for i in 0 ..< samplesNum {
            let idx = i.binaryInversed(numberOfDigits: order)
            inputContent[idx << 1] = sin(2 * .pi * Float(i) * toneFreq / sampleRate)
            inputContent[(idx << 1) + 1] = 0
        }

        print("🔥")

        let gridSize = MTLSizeMake(samplesNum, 1, 1)
        let threadGroupSize = MTLSizeMake(min(pipelineState.maxTotalThreadsPerThreadgroup, samplesNum), 1, 1)
        let buf = [buffer1, buffer2]

        let stepsNum = order

        for step in 0..<stepsNum {
            let argEncoder = fftFunction.makeArgumentEncoder(bufferIndex: 0)

            guard let argBuffer = device.makeBuffer(length: argEncoder.encodedLength, options: []) else { fatalError() }

            argEncoder.setArgumentBuffer(argBuffer, offset: 0)
            argEncoder.constantData(at: 0).assumingMemoryBound(to: Int32.self).pointee = Int32(order)
            argEncoder.constantData(at: 1).assumingMemoryBound(to: Int32.self).pointee = Int32(step)
            argEncoder.constantData(at: 2).assumingMemoryBound(to: Int32.self).pointee = Int32(samplesNum)

            guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { fatalError() }

            computeEncoder.setComputePipelineState(pipelineState)
            computeEncoder.setBuffer(argBuffer, offset: 0, index: 0)
            computeEncoder.setBuffer(buf[step % 2], offset: 0, index: 1)
            computeEncoder.setBuffer(buf[(step+1) % 2], offset: 0, index: 2)
            computeEncoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadGroupSize)
            computeEncoder.endEncoding()
        }

        print("🔥🔥")

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        print("🔥🔥🔥")

        let resultContent = buf[stepsNum % 2].contents().assumingMemoryBound(to: Float32.self)
        for i in 0..<samplesNum {
//            print("\(resultContent[i*2]), \(resultContent[i*2+1])")
            print("\(i) \(sqrt(resultContent[i*2]*resultContent[i*2] + resultContent[i*2+1]*resultContent[i*2+1]))")
        }

        exit(0)
    }

}

extension Int {
    func binaryInversed(numberOfDigits: Int) -> Int {
        var value = self
        var result = 0
        for _ in 0 ..< numberOfDigits {
            result = (result << 1) | (value & 0x1)
            value = value >> 1
        }
        return result
    }
}
