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
    var interactor: SpectrumAnalyzerInteractor?

    override func viewDidLoad() {
        super.viewDidLoad()
        let analyzerView = SpectrumAnalyzerView(frame: view.bounds)
        view.addSubview(analyzerView)
        analyzerView.bindFrameToSuperviewBounds()

        let interactor = analyzerView.getInteractor()

        let samplesNum = 5000
        let toneFreq = 1234.0
        let sampleRate = 44100.0

        var samples = [Double].init(repeating: 0, count: 512)
        var idx = 0

        interactor.isPlaying.push(true)

        for i in 0 ..< samplesNum {
            let sample = sin(2 * .pi * Double(i) * toneFreq / sampleRate)

            samples[idx] = sample
            idx += 1
            if idx == samples.count {
                idx = 0
                interactor.samples.push(samples)
            }
        }
    }
}
