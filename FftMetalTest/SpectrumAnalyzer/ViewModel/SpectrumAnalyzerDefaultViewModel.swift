//
//  SpectrumAnalyzerDefaultViewModel.swift
//  FftMetalTest
//
//  Created by Yauheni Lychkouski on 3/5/20.
//  Copyright © 2020 Yauheni Lychkouski. All rights reserved.
//

import Foundation

class SpectrumAnalyzerDefaultViewModel: SpectrumAnalyzerViewModel {
    struct State {
        var isVisible: Bool
        var isPlaying: Bool

        var isOnAir: Bool {
            return isVisible && isPlaying
        }

        static var initial: State {
            return State(isVisible: false, isPlaying: false)
        }
    }

    var samples: [Double]
    var delegate: SpectrumAnalyzerViewModelDelegate?
    var order: Int {
        didSet {
            guard oldValue != order, state.isOnAir else { return }
            deallocateFourierCalculator()
            instantiateFourierCalculator(order: self.order)
        }
    }

    init() {
        order = 12
        samples = []
        state = .initial

        interactor = SpectrumAnalyzerDefaultInteractor()

        interactor.isPlaying.bind { [weak self] isPlaying in
            self?.state.isPlaying = isPlaying
        }
        
        interactor.samples.bind { [weak self] samples in
            self?.samplingFourierCalculator?.pushSamples(samples)
        }
    }

    func viewVisibilityChanged(isVisible: Bool) {
        state.isVisible = isVisible
    }

    func getInteractor() -> SpectrumAnalyzerInteractor {
        return interactor
    }

    private var state: State {
        didSet {
            guard state.isOnAir else { return }

            deallocateFourierCalculator()
            instantiateFourierCalculator(order: self.order)
        }
    }

    private var samplingFourierCalculator: SamplingFourierCalculator?
    private let interactor: SpectrumAnalyzerInteractor
}

extension SpectrumAnalyzerDefaultViewModel: SamplingFourierCalculatorDelegate {
    func onFourierCalculated(_ spectrumData: [Double]) {
        self.samples = spectrumData
        delegate?.redraw()
    }
}

fileprivate extension SpectrumAnalyzerDefaultViewModel {
    func instantiateFourierCalculator(order: Int) {
        samplingFourierCalculator = SamplingFourierCalculatorImplementation(order: order)
        samplingFourierCalculator?.delegate = self
    }

    func deallocateFourierCalculator() {
        samplingFourierCalculator = nil
    }
}
