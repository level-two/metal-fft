//
//  MTLCommandBuffer+makeEncoder.swift
//  FftMetalTest
//
//  Created by Yauheni Lychkouski on 4/2/20.
//  Copyright © 2020 Yauheni Lychkouski. All rights reserved.
//

import MetalKit

extension MTLCommandBuffer {
    func computeCommand(_ state: MTLComputePipelineState , commandSetup: (MTLComputeCommandEncoder) -> Void) {
        guard let encoder = makeComputeCommandEncoder() else { return }
        encoder.setComputePipelineState(state)
        commandSetup(encoder)
        encoder.endEncoding()
    }

    func blitCommand(commandSetup: (MTLBlitCommandEncoder) -> Void) {
        guard let encoder = makeBlitCommandEncoder() else { return }
        commandSetup(encoder)
        encoder.endEncoding()
    }
}
