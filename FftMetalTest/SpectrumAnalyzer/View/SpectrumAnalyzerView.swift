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

    private var viewModel: SpectrumAnalyzerViewModel?
}

extension SpectrumAnalyzerView {
    func set(viewModel: SpectrumAnalyzerViewModel) {
        self.viewModel = viewModel
        self.viewModel?.delegate = self
    }
}

extension SpectrumAnalyzerView: SpectrumAnalyzerViewModelDelegate {
    func draw(spectrumData: [Double]) {
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


        let numSamples = 2048
        var mockSamples = [Double].init(repeating: 0, count: numSamples)

        for i in 0..<numSamples {
            mockSamples[i] = pow(10, Double.random(in: -150...10) / 20)
        }

        let spectrum = NSBezierPath()
        NSColor(red: 158/255, green: 137/255, blue: 43/255, alpha: 1).setStroke()

        for i in 0..<numSamples {
            let x = xStep * log10( sampleFreq / 2 * CGFloat(i) / CGFloat(numSamples) )
            let sampleVal = mockSamples[i]
            let yLogVal = (sampleVal < 1e-5) ? -100 : 20 * log10(CGFloat(sampleVal))
            let y = (100 + yLogVal) / 10 * yStep
            print(yLogVal)
            spectrum.move(to: CGPoint(x: x, y: 0))
            spectrum.line(to: CGPoint(x: x, y: y))
        }

        spectrum.stroke()
    }
}
