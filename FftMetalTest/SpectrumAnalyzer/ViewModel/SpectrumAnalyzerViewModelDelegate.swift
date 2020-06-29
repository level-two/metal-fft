//
//  SpectrumAnalyzerViewModelDelegate.swift
//  FftMetalTest
//
//  Created by Yauheni Lychkouski on 3/5/20.
//  Copyright © 2020 Yauheni Lychkouski. All rights reserved.
//

import Foundation

protocol SpectrumAnalyzerViewModelDelegate: class {
    func draw(spectrumData: [Double])
}
