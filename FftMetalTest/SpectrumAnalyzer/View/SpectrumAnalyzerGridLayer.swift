//
//  SpectrumAnalyzerGridLayer.swift
//  FftMetalTest
//
//  Created by Yauheni Lychkouski on 3/5/20.
//  Copyright © 2020 Yauheni Lychkouski. All rights reserved.
//

import Cocoa

class SpectrumAnalyzerGridLayer: CALayer {
    override init() {
        super.init()
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    override func draw(in ctx: CGContext) {

    }
}

extension SpectrumAnalyzerGridLayer {
    fileprivate func commonInit() {
        needsDisplayOnBoundsChange = true
    }
}
