//
//  SpectrumAnalyzerView.swift
//  FftMetalTest
//
//  Created by Yauheni Lychkouski on 3/5/20.
//  Copyright © 2020 Yauheni Lychkouski. All rights reserved.
//

import Cocoa

@IBDesignable
public class SpectrumAnalyzerView: NSView {
    override public var intrinsicContentSize: CGSize {
        return CGSize(width: 100, height: 100)
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private var token: NSKeyValueObservation?

    private let viewModel: SpectrumAnalyzerViewModel = SpectrumAnalyzerDefaultViewModel()

    let logSteps: [CGFloat] = stride(from: 2, to: 9, by: 1).map(log10)
}

extension SpectrumAnalyzerView {
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
    func commonInit() {
        viewModel.delegate = self

        token = observe(\.isHidden) { [weak self] _, change in
            guard let isHidden = change.newValue else { return }
            self?.viewModel.viewVisibilityChanged(isVisible: !isHidden)
        }

        viewModel.viewVisibilityChanged(isVisible: !isHidden)
    }
}

extension SpectrumAnalyzerView {
    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

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
//
//
//
//
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
