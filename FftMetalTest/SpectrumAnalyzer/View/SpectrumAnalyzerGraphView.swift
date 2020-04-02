//
//  SpectrumAnalyzerGraphView.swift
//  FftMetalTest
//
//  Created by Yauheni Lychkouski on 3/31/20.
//  Copyright © 2020 Yauheni Lychkouski. All rights reserved.
//

import Foundation

import Cocoa

@IBDesignable public final class SpectrumAnalyzerGraphView: NSView {
    //    override public func awakeFromNib() {
    //        super.awakeFromNib()
    //        setup()
    //    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    func configure(with viewModel: SpectrumAnalyzerViewModel) {
        minFreq = viewModel.freqRange.min
        maxFreq = viewModel.freqRange.max
        samplesNum = viewModel.samplesNumber/2
        minSampleVal = viewModel.sampleValuesRange.min
        maxSampleVal = viewModel.sampleValuesRange.max

        precalculateXValues()
    }

    func update(with viewModel: SpectrumAnalyzerViewModel) {
        samples = viewModel.samples
        self.setNeedsDisplay(bounds)
    }

    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        plot(points: plotPoints)
    }

    private var minFreq: CGFloat?
    private var maxFreq: CGFloat?
    private var samplesNum: CGFloat?
    private var minSampleVal: CGFloat?
    private var maxSampleVal: CGFloat?
    private var samples: [CGFloat] = []

    private var frameChangeObservationToken: NSKeyValueObservation?
    private var roundedXValues = [CGFloat]()
}

fileprivate extension SpectrumAnalyzerGraphView {
    func setup() {
        observeFrameChange()
    }

    func observeFrameChange() {
        frameChangeObservationToken = observe(\.frame) { [weak self] _, _ in
            guard let self = self else { return }
            self.precalculateXValues()
            self.setNeedsDisplay(self.bounds)
        }
    }
}


fileprivate extension SpectrumAnalyzerGraphView {
    func plot(points: [NSPoint]) {
        guard points.count != 0 else { return }
        NSColor(red: 158/255, green: 137/255, blue: 43/255, alpha: 1).setStroke()
        let graph = NSBezierPath()
        graph.move(to: points[0])
        points.forEach(graph.line)
        graph.stroke()
    }
}

fileprivate extension SpectrumAnalyzerGraphView {
    func precalculateXValues() {
        guard let minFreq = minFreq,
            let maxFreq = maxFreq,
            let samplesNum = samplesNum
            else { return }

        let logFreqValues = stride(from: 0, to: samplesNum, by: 1).map {
            log10(minFreq + (maxFreq - minFreq) * $0 / samplesNum)
        }

        let minLogFreq = logFreqValues.first!
        let maxLogFreq = logFreqValues.last!

        let xValues = logFreqValues.map {
            ($0 - minLogFreq)/(maxLogFreq - minLogFreq) * bounds.width
        }

        roundedXValues = xValues.map { $0.rounded(.down) }
    }

    var plotPoints: [NSPoint] {
        guard let minFreq = minFreq,
            let maxFreq = maxFreq,
            let samplesNum = samplesNum,
            let minSampleVal = minSampleVal,
            let maxSampleVal = maxSampleVal
            else { return [] }

        func y(for val: CGFloat) -> CGFloat {
            let clampedVal = val.clamped(in: minSampleVal...maxSampleVal)
            return bounds.height * (clampedVal - minSampleVal) / (maxSampleVal - minSampleVal)
        }

        var prevX = CGFloat(-1)
        var maxVal = -CGFloat.infinity
        var points = [NSPoint]()

        for i in 0..<samples.count {
            let x = roundedXValues[i]
            let val = samples[i]

            if x == prevX {
                maxVal = max(maxVal, val)
                points[points.count - 1] = NSPoint(x: x, y: y(for: maxVal))
                continue
            }

            points.append(NSPoint(x: x, y: y(for: val)))
            prevX = x
            maxVal = val
        }
        return points
    }
}
