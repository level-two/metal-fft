//
//  SpectrumAnalyzerDefaultViewModel.swift
//  FftMetalTest
//
//  Created by Yauheni Lychkouski on 3/5/20.
//  Copyright © 2020 Yauheni Lychkouski. All rights reserved.
//

import Foundation

class SpectrumAnalyzerDefaultViewModel: SpectrumAnalyzerViewModel {
    var samples: [CGFloat]
    var sampleRate: CGFloat
    var freqRange: (min: CGFloat, max: CGFloat)
    var sampleValuesRange: (min: CGFloat, max: CGFloat)
    var delegate: SpectrumAnalyzerViewModelDelegate?

    init() {
        isVisible = false
        isPlaying = false

        // TODO: Calc those values or get them from model
        order = 12
        sampleRate = CGFloat(1 << order)
        freqRange = (min: 10, max: 22050)
        sampleValuesRange = (min:-150, max: 10)

        samples = []

        interactor = SpectrumAnalyzerDefaultInteractor()
        interactor.isPlaying.bindOnMain { [weak self] isPlaying in
            self?.isPlaying = isPlaying
        }
    }

    func viewVisibilityChanged(isVisible: Bool) {
        assert(Thread.isMainThread)
        self.isVisible = isVisible
    }

    func setOrder(_ order: Int) {
        assert(Thread.isMainThread)
        guard order > 8, order <= 14 else { return }
        self.order = order
    }

    func getInteractor() -> SpectrumAnalyzerInteractor {
        return interactor
    }

    private var isVisible: Bool { didSet { stateChanged() } }
    private var isPlaying: Bool { didSet { stateChanged() } }
    private var order: Int { didSet { stateChanged() } }

    private var samplingFourierCalculator: SamplingFourierCalculator?
    private let interactor: SpectrumAnalyzerInteractor
}

fileprivate extension SpectrumAnalyzerDefaultViewModel {
    func stateChanged() {
        assert(Thread.isMainThread)

        samplingFourierCalculator = nil

        if isVisible, isPlaying {
            samplingFourierCalculator = SamplingFourierCalculatorImplementation(order: order)
            interactor.samples.bindOnMain(to: samplingFourierCalculator?.inputSamples)
            samplingFourierCalculator?.outputSpectrum.bindOnMain { [weak self] spectrumData in
                self?.samples = spectrumData.map(CGFloat.init)
                self?.delegate?.redraw()
            }
        }
    }
}
