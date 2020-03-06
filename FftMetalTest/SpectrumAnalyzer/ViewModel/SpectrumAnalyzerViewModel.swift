//
//  SpectrumAnalyzerViewModel.swift
//  FftMetalTest
//
//  Created by Yauheni Lychkouski on 3/5/20.
//  Copyright © 2020 Yauheni Lychkouski. All rights reserved.
//

import Foundation

protocol SpectrumAnalyzerViewModel {
    var delegate: SpectrumAnalyzerViewModelDelegate? { get set }
    func viewVisibilityChanged(isVisible: Bool)
}
