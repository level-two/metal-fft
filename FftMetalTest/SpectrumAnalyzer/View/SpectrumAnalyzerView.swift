//
//  SpectrumAnalyzerView.swift
//  FftMetalTest
//
//  Created by Yauheni Lychkouski on 3/5/20.
//  Copyright © 2020 Yauheni Lychkouski. All rights reserved.
//

import Cocoa

@IBDesignable public final class SpectrumAnalyzerView: NSView {
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

    override public var intrinsicContentSize: CGSize {
        return CGSize(width: 100, height: 100)
    }

    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        plot(points: plotPoints)
    }

    private var observationTokens = [NSKeyValueObservation]()
    private let viewModel: SpectrumAnalyzerViewModel = SpectrumAnalyzerDefaultViewModel()
    private var roundedXValues = [CGFloat]()
}

extension SpectrumAnalyzerView {
    // TODO: Refactor this to make it publicly accessiblie - probably using protocol
    // to introduce particular interface conformance for the view instantiated from the nib
    func getInteractor() -> SpectrumAnalyzerInteractor {
        return viewModel.getInteractor()
    }
}

extension SpectrumAnalyzerView: SpectrumAnalyzerViewModelDelegate {
    func redraw() {
        self.setNeedsDisplay(bounds)
    }
}

fileprivate extension SpectrumAnalyzerView {
    func setup() {
        setViewModelDelegate()
        setObservationCallbacks()
        precalculateXValues()
        notifyViewModelOfVisibilityState()
    }

    func setViewModelDelegate() {
        viewModel.delegate = self
    }

    func setObservationCallbacks() {
        let isHiddenToken = observe(\.isHidden) { [weak self] _, change in
            guard let isHidden = change.newValue else { return }
            self?.viewModel.viewVisibilityChanged(isVisible: !isHidden)
        }

        let boundsToken = observe(\.bounds) { [weak self] _, _ in
            self?.precalculateXValues()
            self?.redraw()
        }

        observationTokens = [isHiddenToken, boundsToken]
    }

    func notifyViewModelOfVisibilityState() {
        viewModel.viewVisibilityChanged(isVisible: !isHidden)
    }
}

fileprivate extension SpectrumAnalyzerView {
    func plot(points: [NSPoint]) {
        guard points.count != 0 else { return }
        NSColor(red: 158/255, green: 137/255, blue: 43/255, alpha: 1).setStroke()
        let graph = NSBezierPath()
        graph.move(to: points[0])
        points.forEach(graph.line)
        graph.stroke()
    }
}

fileprivate extension SpectrumAnalyzerView {

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

/*
//        let sampleFreq = CGFloat(44100.0)
//
//        let maxFreq = sampleFreq / 2
//
//        let xAxisSettings = AxisMode.linear
//        let yAxisMode = AxisMode.log

        drawLinearXGrid(in: dirtyRect)
//
//
//        NSColor.black.drawSwatch(in: dirtyRect)
//
//        let ySteps = CGFloat(11)
//        let xSteps = CGFloat(10)
//
//        let yStep = dirtyRect.height / ySteps
//        let xStep = dirtyRect.width / xSteps
//
//        let grid = NSBezierPath()
//        NSColor(red: 158/255, green: 137/255, blue: 43/255, alpha: 1).setStroke()
//
//        for x in stride(from: 0, to: dirtyRect.width, by: xStep) {
//            grid.move(to: CGPoint(x: x, y: 0))
//            grid.line(to: CGPoint(x: x, y: dirtyRect.height))
//        }
//        for y in stride(from: 0, to: dirtyRect.height, by: yStep) {
//            grid.move(to: CGPoint(x: 0, y: y))
//            grid.line(to: CGPoint(x: dirtyRect.width, y: y))
//        }
//
//        grid.stroke()
//
//
//        let samples = viewModel.samples
//        let max = samples.max() ?? 1
//
//        let spectrum = NSBezierPath()
//        NSColor(red: 158/255, green: 100/255, blue: 20/255, alpha: 1).setStroke()
//
//        for i in 0..<samples.count {
//            let x = CGFloat(i) * dirtyRect.width / CGFloat(samples.count)
//            print(x)
//            let sampleVal = samples[i]/max
//            let yLogVal = (sampleVal < 1e-5) ? -100 : 20 * log10(CGFloat(sampleVal))
//            let y = (100 + yLogVal) / 10 * yStep
//
//            if i == 0 {
//                spectrum.move(to: CGPoint(x: x, y: y))
//            } else {
//                spectrum.line(to: CGPoint(x: x, y: y))
//            }
//        }
//
//        spectrum.stroke()
    }
}

fileprivate extension SpectrumAnalyzerView {
    func drawLinearXGrid(in rect: CGRect) {
        let freqMax = CGFloat(22050) // viewModel.maxFreq
        let freqStep = CGFloat(2000)

        let xStep = rect.width * freqStep / freqMax

        let subxStep = xStep / 2

        let subGrid = NSBezierPath()
        NSColor(red: 100/255, green: 100/255, blue: 100/255, alpha: 1).setStroke()
        for x in stride(from: rect.minX, to: rect.maxX, by: subxStep) {
            subGrid.move(to: CGPoint(x: x, y: 0))
            subGrid.line(to: CGPoint(x: x, y: rect.height))
        }
        subGrid.stroke()

        let grid = NSBezierPath()
        NSColor(red: 158/255, green: 137/255, blue: 43/255, alpha: 1).setStroke()
        for x in stride(from: rect.minX, to: rect.maxX, by: xStep) {
            grid.move(to: CGPoint(x: x, y: 0))
            grid.line(to: CGPoint(x: x, y: rect.height))
        }
        grid.stroke()
    }

    func drawLogXGrid(in rect: CGRect) {
        let maxVal = CGFloat(44100)/2 // viewModel.maxFreq
        let minVal = CGFloat(10)
        let maxLogVal = log10(maxVal/minVal)

        xLogSteps = [CGFloat]()
        

//        let subGrid = NSBezierPath()
//        NSColor(red: 100/255, green: 100/255, blue: 100/255, alpha: 1).setStroke()
//        for x in stride(from: rect.minX, to: rect.maxX, by: subxStep) {
//            subGrid.move(to: CGPoint(x: x, y: 0))
//            subGrid.line(to: CGPoint(x: x, y: rect.height))
//        }
//        subGrid.stroke()

        let grid = NSBezierPath()
        NSColor(red: 158/255, green: 137/255, blue: 43/255, alpha: 1).setStroke()
        xLogSteps.forEach { x in
            grid.move(to: CGPoint(x: x, y: 0))
            grid.line(to: CGPoint(x: x, y: rect.height))
        }
        grid.stroke()
    }

//
//    func drawLogYGrid(in rect: CGRect) {
//        let grid = NSBezierPath()
//        NSColor(red: 158/255, green: 137/255, blue: 43/255, alpha: 1).setStroke()
//
//        for y in stride(from: 0, to: rect.height, by: yStep) {
//            grid.move(to: CGPoint(x: 0, y: y))
//            grid.line(to: CGPoint(x: rect.width, y: y))
//        }
//
//        grid.stroke()
//    }
}
*/
