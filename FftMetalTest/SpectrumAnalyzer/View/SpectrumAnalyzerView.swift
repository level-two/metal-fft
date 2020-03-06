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

    private let viewModel: SpectrumAnalyzerViewModel = SpectrumAnalyzerDefaultViewModel()
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
        setupView()
    }

    func setupView() {
    }
}

extension SpectrumAnalyzerView {
    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let sampleFreq = CGFloat(44100.0)

        NSColor.black.drawSwatch(in: dirtyRect)

        let ySteps = CGFloat(11)
        let xSteps = log10(sampleFreq/2)

        let yStep = dirtyRect.height / ySteps
        let xStep = dirtyRect.width / xSteps

        let grid = NSBezierPath()
        NSColor(red: 158/255, green: 137/255, blue: 43/255, alpha: 1).setStroke()

        for x in stride(from: 0, to: dirtyRect.width, by: xStep) {
            grid.move(to: CGPoint(x: x, y: 0))
            grid.line(to: CGPoint(x: x, y: dirtyRect.height))
        }
        for y in stride(from: 0, to: dirtyRect.height, by: yStep) {
            grid.move(to: CGPoint(x: 0, y: y))
            grid.line(to: CGPoint(x: dirtyRect.width, y: y))
        }

        grid.stroke()

        let samples = viewModel.samples

        let spectrum = NSBezierPath()
        NSColor(red: 158/255, green: 137/255, blue: 43/255, alpha: 1).setStroke()

        for i in 0..<samples.count {
            let x = (i == 0) ? 0 : xStep * log10( sampleFreq / 2 * CGFloat(i) / CGFloat(samples.count) )
            let sampleVal = samples[i]
            let yLogVal = (sampleVal < 1e-5) ? -100 : 20 * log10(CGFloat(sampleVal))
            let y = (100 + yLogVal) / 10 * yStep

            if i == 0 {
                spectrum.move(to: CGPoint(x: x, y: y))
            } else {
                spectrum.line(to: CGPoint(x: x, y: y))
            }
        }

        spectrum.stroke()
    }
}
