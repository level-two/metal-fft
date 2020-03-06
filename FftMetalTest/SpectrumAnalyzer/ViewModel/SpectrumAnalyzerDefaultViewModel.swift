//
//  SpectrumAnalyzerDefaultViewModel.swift
//  FftMetalTest
//
//  Created by Yauheni Lychkouski on 3/5/20.
//  Copyright © 2020 Yauheni Lychkouski. All rights reserved.
//

import Foundation

class SpectrumAnalyzerDefaultViewModel: SpectrumAnalyzerViewModel {
    var samples: [Double]
    var delegate: SpectrumAnalyzerViewModelDelegate?

    init() {
        isVisible = false
        isPlaying = false
        order = 12

        samples = []

        interactor = SpectrumAnalyzerDefaultInteractor()

        interactor.isPlaying.bind { [weak self] isPlaying in
            DispatchQueue.main.async { [weak self] in
                self?.isPlaying = isPlaying
            }
        }

        interactor.samples.bind { [weak self] samples in
            DispatchQueue.main.async { [weak self] in
                self?.samplingFourierCalculator?.pushSamples(samples)
            }
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

extension SpectrumAnalyzerDefaultViewModel: SamplingFourierCalculatorDelegate {
    func onFourierCalculated(_ spectrumData: [Double]) {
        DispatchQueue.main.async { [weak self] in
            self?.samples = spectrumData
            self?.delegate?.redraw()
        }
    }
}

fileprivate extension SpectrumAnalyzerDefaultViewModel {
    func stateChanged() {
        assert(Thread.isMainThread)

        samplingFourierCalculator = nil

        if isVisible, isPlaying {
            samplingFourierCalculator = SamplingFourierCalculatorImplementation(order: order)
            samplingFourierCalculator?.delegate = self
        }
    }
}
