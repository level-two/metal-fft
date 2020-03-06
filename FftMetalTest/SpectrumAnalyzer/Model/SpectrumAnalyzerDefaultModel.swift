//
//  SpectrumAnalyzerDefaultModel.swift
//  FftMetalTest
//
//  Created by Yauheni Lychkouski on 3/5/20.
//  Copyright © 2020 Yauheni Lychkouski. All rights reserved.
//

import Foundation

class SpectrumAnalyzerDefaultModel {
    fileprivate var samplingFourierCalculator: SamplingFourierCalculator?
}

extension SpectrumAnalyzerDefaultModel: SpectrumAnalyzerModel {
    func allocateResources(order: Int) {
        samplingFourierCalculator = SamplingFourierCalculator(order: order)
        samplingFourierCalculator?.delegate = self
    }

    func deallocateResources() {
        samplingFourierCalculator = nil
    }
}

extension SpectrumAnalyzerDefaultModel: SpectrumAnalyzerSamplesConsumer {
    func addSamples(_ samples: [Double]) {
        samplingFourierCalculator?.addSamples(samples)
    }
}

extension SpectrumAnalyzerDefaultModel: SamplingFourierCalculatorDelegate {
    func onFourierCalculated(_ spectrumValues: [Double]) {

    }
}
