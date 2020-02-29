//
//  ViewController.swift
//  MetalTestApp
//
//  Created by Yauheni Lychkouski on 2/19/20.
//  Copyright © 2020 Yauheni Lychkouski. All rights reserved.
//

import Cocoa
import CoreFoundation
import Metal

struct AAPLVertex {
    var position: (Float32, Float32)
    var textureCoordinate: (Float32, Float32)
}



class ViewController: NSViewController {
    var device: MTLDevice?
    var metalLayer: CAMetalLayer?
    var defaultLibrary: MTLLibrary?

//    MTLFunction
//    MTLComputePipelineState
//    MTLCommandQueue
//    var timer: CADisplayLink?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMetal()
        setupMetalLayer()
        setupRenderingPipeline()
    }

    func setupMetal() {
        device = MTLCreateSystemDefaultDevice()
        defaultLibrary = device?.makeDefaultLibrary()
    }


    func setupMetalLayer() {
        metalLayer = {
            let layer = CAMetalLayer()
            layer.device = device
            layer.pixelFormat = .bgra8Unorm
            layer.framebufferOnly = false
            layer.frame = view.layer?.frame ?? .zero
            view.layer?.addSublayer(layer)
            return layer
        }()
    }

    func setupRenderingPipeline() {
        guard let frame = view.layer?.frame else { return }

        var viewportSize = MTLSize(width: Int(frame.width), height: Int(frame.height), depth: 0)

        let fftResults = sendMetalCommands()
        let texture = fftTexture(from: fftResults, samplesNum: 4096, size: viewportSize)

        let vertexData: [Float32] = [
             Float32(frame.width), -Float32(frame.height), 1, 1,
            -Float32(frame.width), -Float32(frame.height), 0, 1,
            -Float32(frame.width),  Float32(frame.height), 0, 0,
             Float32(frame.width), -Float32(frame.height), 1, 1,
            -Float32(frame.width),  Float32(frame.height), 0, 0,
             Float32(frame.width),  Float32(frame.height), 1, 0,
            ]

        let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
        let vertexBuffer = device?.makeBuffer(bytes: vertexData, length: dataSize, options: [])

        let vertexProgram = defaultLibrary?.makeFunction(name: "vertexShader")
        let fragmentProgram = defaultLibrary?.makeFunction(name: "samplingShader")

        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        guard let device = device,
            let pipelineState = try? device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
            else { return }

        guard let drawable = metalLayer?.nextDrawable() else { return }
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(
            red: 0.0,
            green: 104.0/255.0,
            blue: 55.0/255.0,
            alpha: 1.0)

        guard let commandQueue = device.makeCommandQueue(),
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
            else { return }

        //        [renderEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, -1.0, 1.0 }];
        renderEncoder.setViewport(MTLViewport(originX: 0, originY: 0, width: Double(viewportSize.width), height: Double(viewportSize.height), znear: -1, zfar: 1))

        //        [renderEncoder setRenderPipelineState:_pipelineState];
        renderEncoder.setRenderPipelineState(pipelineState)

        //        [renderEncoder setVertexBuffer:_vertices offset:0 atIndex:AAPLVertexInputIndexVertices]; // 0
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

        //        [renderEncoder setVertexBytes:&_viewportSize length:sizeof(_viewportSize) atIndex:AAPLVertexInputIndexViewportSize]; // 1
        renderEncoder.setVertexBytes(&viewportSize, length: MemoryLayout<MTLSize>.stride, index: 1)

        //        // Set the texture object.  The AAPLTextureIndexBaseColor enum value corresponds
        //        ///  to the 'colorMap' argument in the 'samplingShader' function because its
        //        //   texture attribute qualifier also uses AAPLTextureIndexBaseColor for its index.
        //        [renderEncoder setFragmentTexture:_texture atIndex:AAPLTextureIndexBaseColor]; // 0
        renderEncoder.setFragmentTexture(texture, index: 0)

        //        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_numVertices];
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexData.count/4, instanceCount: 1)


        commandBuffer.present(drawable)
        commandBuffer.commit()

    }

/*
    func setupRenderingPipeline() {
        let vertexData: [Float32] = [
            250, -250, 1, 1,
            -250, -250, 0, 1,
            -250,  250, 0, 0,
            250, -250, 1, 1,
            -250,  250, 0, 0,
            250,  250, 1, 0,
            ]

        let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
        let vertexBuffer = device?.makeBuffer(bytes: vertexData, length: dataSize, options: [])

        let vertexProgram = defaultLibrary?.makeFunction(name: "vertexShader")
        let fragmentProgram = defaultLibrary?.makeFunction(name: "samplingShader")

        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        guard let device = device,
            let pipelineState = try? device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
            else { return }

        guard let drawable = metalLayer?.nextDrawable() else { return }
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 104.0/255.0, blue: 55.0/255.0, alpha: 1.0)

        guard let commandQueue = device.makeCommandQueue(),
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
            else { return }


//        [renderEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, -1.0, 1.0 }];
        renderEncoder.setViewport(MTLViewport(originX: 0, originY: 0, width: view.layer.frame.width, height: view.layer.frame.height, znear: -1, zfar: 1))

//        [renderEncoder setRenderPipelineState:_pipelineState];
        renderEncoder.setRenderPipelineState(pipelineState)

//        [renderEncoder setVertexBuffer:_vertices offset:0 atIndex:AAPLVertexInputIndexVertices];
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

//        [renderEncoder setVertexBytes:&_viewportSize length:sizeof(_viewportSize) atIndex:AAPLVertexInputIndexViewportSize];
        renderEncoder.setVertexBytes(<#T##bytes: UnsafeRawPointer##UnsafeRawPointer#>, length: <#T##Int#>, index: <#T##Int#>)
//        // Set the texture object.  The AAPLTextureIndexBaseColor enum value corresponds
//        ///  to the 'colorMap' argument in the 'samplingShader' function because its
//        //   texture attribute qualifier also uses AAPLTextureIndexBaseColor for its index.
//        [renderEncoder setFragmentTexture:_texture atIndex:AAPLTextureIndexBaseColor];

//        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_numVertices];
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexData.count, instanceCount: 1)

//        [renderEncoder endEncoding];
        renderEncoder.endEncoding()






        commandBuffer.present(drawable)
        commandBuffer.commit()

    }
*/

/*
    func render() {
        guard
            let device = device,
            let defaultLibrary = defaultLibrary
            else { return }

        let vertexData: [Float32] = [
            250, -250, 1, 1,
            -250, -250, 0, 1,
            -250,  250, 0, 0,
            250, -250, 1, 1,
            -250,  250, 0, 0,
            250,  250, 1, 0,
            ]

        let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
        let vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: [])

        /// Create the render pipeline

        let vertexFunction = defaultLibrary.makeFunction(name: "vertexShader")
        let fragmentFunction = defaultLibrary.makeFunction(name: "samplingShader")

        // Set up a descriptor for creating a pipeline state object
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.label = "Texturing Pipeline"
        pipelineStateDescriptor.vertexFunction = vertexFunction
        pipelineStateDescriptor.fragmentFunction = fragmentFunction
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        guard
            let pipelineState = try? device.makeRenderPipelineState(descriptor: pipelineStateDescriptor),
            let commandQueue = device.makeCommandQueue(),
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let renderPassDescriptor = view.currentRenderPassDescriptor
            else { return }

        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoder.label = "MyRenderEncoder"

        // Set the region of the drawable to draw into.
        renderEncoder
        [renderEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, -1.0, 1.0 }];

        [renderEncoder setRenderPipelineState:_pipelineState];

        [renderEncoder setVertexBuffer:_vertices
            offset:0
            atIndex:AAPLVertexInputIndexVertices];

        [renderEncoder setVertexBytes:&_viewportSize
            length:sizeof(_viewportSize)
            atIndex:AAPLVertexInputIndexViewportSize];

        // Set the texture object.  The AAPLTextureIndexBaseColor enum value corresponds
        ///  to the 'colorMap' argument in the 'samplingShader' function because its
        //   texture attribute qualifier also uses AAPLTextureIndexBaseColor for its index.
        [renderEncoder setFragmentTexture:_texture
            atIndex:AAPLTextureIndexBaseColor];

        // Draw the triangles.
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
            vertexStart:0
            vertexCount:_numVertices];

        [renderEncoder endEncoding];

        // Schedule a present once the framebuffer is complete using the current drawable
        [commandBuffer presentDrawable:view.currentDrawable];

        // Finalize rendering here & push the command buffer to the GPU
        [commandBuffer commit];
    }
*/

//    func setupRenderingLoop() {
//        timer = CADisplayLink(target: self, selector: #selector(renderingLoop))
//        timer?.add(to: RunLoop.main, forMode: .default)
//    }

//    @objc func renderingLoop() {
//        autoreleasepool {
//            self.render()
//        }
//    }

//    func render() {
//    }

    func sendMetalCommands() -> MTLBuffer {
        let order = 12
        let samplesNum = 1 << order
        let sampleRate = Float(44100.0)
        let toneFreq = Float(1234.0)

        guard let device = device,
            let defaultLibrary = defaultLibrary,
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
        return buf[stepsNum % 2]
        print("🔥🔥🔥")
//
//        let resultContent = buf[stepsNum % 2].contents().assumingMemoryBound(to: Float32.self)
//        for i in 0..<samplesNum {
////            print("\(resultContent[i*2]), \(resultContent[i*2+1])")
//            print("\(i) \(sqrt(resultContent[i*2]*resultContent[i*2] + resultContent[i*2+1]*resultContent[i*2+1]))")
//        }
    }



    func fftTexture(from buffer: MTLBuffer, samplesNum: Int, size: MTLSize) -> MTLTexture? {
        let bytesPerPixel = 4

        var data = Data(repeating: 255, count: bytesPerPixel * size.width * size.height)

        let content = buffer.contents().assumingMemoryBound(to: Float32.self)

        var maxVal = Float32(0)
        for i in 0..<samplesNum/2 where content[i] > maxVal {
            maxVal = content[i]
        }

        for i in 0..<samplesNum/2 {
            let x = (i * size.width) / (samplesNum/2)
            let y = content[i] * Float32(size.height) / maxVal
            let startBytePos = (Int(y) * size.width + x) * bytesPerPixel
            data.replaceSubrange(startBytePos ..< startBytePos + bytesPerPixel,
                                 with: [UInt8].init(repeating: 0, count: bytesPerPixel))
        }

        let texture = createTexture(size: size)
        let region = MTLRegion(origin: .zero, size: size)
        let bytesPerRow = 4*size.width
        texture?.replace(region: region, mipmapLevel: 0, withBytes: (data as NSData).bytes, bytesPerRow: bytesPerRow)

        return texture
    }

    func createTexture(size: MTLSize) -> MTLTexture? {
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = .bgra8Unorm
        textureDescriptor.width = size.width
        textureDescriptor.height = size.height
        return device?.makeTexture(descriptor: textureDescriptor)
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

extension MTLOrigin {
    static var zero: MTLOrigin {
        return .init(x: 0, y: 0, z: 0)
    }
}
