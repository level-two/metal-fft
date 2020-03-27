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
    let samplesFifo = Fifo<[Double]>(capacity: 1000)
    var currentTime: Double = 0

    var renderingBlockSimTimer: Timer?
    var pollingTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        let analyzerView = SpectrumAnalyzerView(frame: view.bounds)
        view.addSubview(analyzerView)
        analyzerView.bindFrameToSuperviewBounds()

        let interactor = analyzerView.getInteractor()

        let samplesPerRenderingCall = 512
        let toneFreq = 15000.0
        let sampleRate = 44100.0

        let refreshRate = 10.0

//        interactor.isPlaying.push(true)

        renderingBlockSimTimer = Timer.scheduledTimer(withTimeInterval: Double(samplesPerRenderingCall)/sampleRate, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            var samples = [Double].init(repeating: 0, count: samplesPerRenderingCall)

            for i in 0 ..< samplesPerRenderingCall {
                samples[i] = sin(2 * .pi * self.currentTime * toneFreq)
                self.currentTime += 1/sampleRate
            }

            do {
                try self.samplesFifo.push(samples)
            } catch {
                fatalError(error.localizedDescription)
            }
        }

        pollingTimer = Timer.scheduledTimer(withTimeInterval: 1/refreshRate, repeats: true) { [weak self] timer in
            guard let self = self else { return }

            while !self.samplesFifo.isEmpty {
                do {
                    let samples = try self.samplesFifo.pop()
                    interactor.samples.push(samples)
                } catch {
                    fatalError(error.localizedDescription)
                }
            }
        }

    }
}
