//
//  ViewController.swift
//  MetalTestApp
//
//  Created by Yauheni Lychkouski on 2/19/20.
//  Copyright © 2020 Yauheni Lychkouski. All rights reserved.
//

import Cocoa
import CoreFoundation

class ViewController: NSViewController {
    var spectrumAnalyzer: SpectrumAnalyzer?

    override func viewDidLoad() {
        super.viewDidLoad()
        let order = 12
        let samplesNum = 1 << order

        spectrumAnalyzer = SpectrumAnalyzer(order: order, samplesNum: samplesNum)
        spectrumAnalyzer?.onCalculationCompleted = { data in
            print(data)
        }

        let sampleRate = 44100.0
        let toneFreq = 1234.0

        for i in 0 ..< samplesNum {
            let sample = sin(2 * .pi * Double(i) * toneFreq / sampleRate)
            spectrumAnalyzer?.addSample(sample)
        }
    }
}
