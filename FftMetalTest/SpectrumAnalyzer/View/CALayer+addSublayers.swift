//
//  CALayer+addSublayers.swift
//  FftMetalTest
//
//  Created by Yauheni Lychkouski on 3/5/20.
//  Copyright © 2020 Yauheni Lychkouski. All rights reserved.
//

import Cocoa

extension CALayer {
    func addSublayers(_ layers: CALayer?...) {
        layers.compactMap({ $0 }).forEach(self.addSublayer)
    }
}
