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

    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        plot(points: plotPoints)
    }

    private var boundsChangeObservationToken: NSKeyValueObservation?
    private var roundedXValues = [CGFloat]()
}

fileprivate extension SpectrumAnalyzerGraphView {
    func setup() {
        // TBD
    }

    func observeBoundsChange() {
        boundsChangeObservationToken = observe(\.bounds) { [weak self] _, _ in
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
        let minFreq = viewModel.freqRange.min
        let maxFreq = viewModel.freqRange.max
        let samplesNum = viewModel.sampleRate/2

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
        let minSampleVal = viewModel.sampleValuesRange.min
        let maxSampleVal = viewModel.sampleValuesRange.max

        func y(for val: CGFloat) -> CGFloat {
            return bounds.height * val / (maxSampleVal - minSampleVal)
        }

        var prevX = CGFloat(-1)
        var maxVal = -CGFloat.infinity
        var points = [NSPoint]()

        for i in 0..<viewModel.samples.count {
            let x = roundedXValues[i]
            let val = viewModel.samples[i]

            guard x != prevX else {
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

