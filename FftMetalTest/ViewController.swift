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
//    var spectrumAnalyzer: SpectrumAnalyzer?

    override func viewDidLoad() {
        super.viewDidLoad()
        let analyzerView = SpectrumAnalyzerView(frame: view.bounds)
        view.addSubview(analyzerView)
    }
}
