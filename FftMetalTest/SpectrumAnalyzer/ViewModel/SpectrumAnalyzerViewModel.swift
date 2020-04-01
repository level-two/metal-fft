//
//  SpectrumAnalyzerViewModel.swift
//  FftMetalTest
//
//  Created by Yauheni Lychkouski on 3/5/20.
//  Copyright © 2020 Yauheni Lychkouski. All rights reserved.
//

import Foundation

protocol SpectrumAnalyzerViewModel: class {
    func getInteractor() -> SpectrumAnalyzerInteractor

    var samples: [CGFloat] { get }
    var sampleRate: CGFloat { get }
    var samplesNumber: CGFloat { get }
    var freqRange: (min: CGFloat, max: CGFloat) { get }
    var sampleValuesRange: (min: CGFloat, max: CGFloat) { get }
    
    var delegate: SpectrumAnalyzerViewModelDelegate? { get set }

    func viewVisibilityChanged(isVisible: Bool)
    func setOrder(_ order: Int)
}
