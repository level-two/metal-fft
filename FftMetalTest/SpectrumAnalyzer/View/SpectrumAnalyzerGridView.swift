//
//  SpectrumAnalyzerGridView.swift
//  FftMetalTest
//
//  Created by Yauheni Lychkouski on 3/31/20.
//  Copyright © 2020 Yauheni Lychkouski. All rights reserved.
//

import Foundation

import Cocoa

@IBDesignable public final class SpectrumAnalyzerGridView: NSView {
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
        minSampleVal = viewModel.sampleValuesRange.min
        maxSampleVal = viewModel.sampleValuesRange.max
    }

    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        drawXGrid()
        drawYGrid()
    }

    private var minFreq: CGFloat?
    private var maxFreq: CGFloat?
    private var minSampleVal: CGFloat?
    private var maxSampleVal: CGFloat?
}

fileprivate extension SpectrumAnalyzerGridView {
    func setup() {
        // TBD
    }
}

fileprivate extension SpectrumAnalyzerGridView {
    func drawXGrid() {
        guard let minFreq = minFreq, let maxFreq = maxFreq else { return }

        NSColor.black.drawSwatch(in: bounds)

        let minLogFreq = log10(minFreq)
        let maxLogFreq = log10(maxFreq)
        let substeps: [CGFloat] = [0] + stride(from: 2, to: 10, by: 1).map(log10)

        let subGridSteps = stride(from: minLogFreq.rounded(.down), to: maxLogFreq.rounded(.up), by: 1)
            .flatMap { step in substeps.map { $0 + step } }
            .filter { $0 >= minLogFreq && $0 <= maxLogFreq }

        let subgrid = NSBezierPath()
        NSColor(red: 100/255, green: 100/255, blue: 100/255, alpha: 1).setStroke()
        subgrid.setLineDash([2, 2], count: 2, phase: 0)
        subGridSteps.forEach { step in
            let x = bounds.width * (step - minLogFreq) / (maxLogFreq - minLogFreq)
            subgrid.move(to: CGPoint(x: x, y: 0))
            subgrid.line(to: CGPoint(x: x, y: bounds.height))
        }
        subgrid.stroke()

        let gridSteps = stride(from: minLogFreq.rounded(.up), to: maxLogFreq.rounded(.up), by: 1)

        let grid = NSBezierPath()
        NSColor(red: 158/255, green: 137/255, blue: 43/255, alpha: 1).setStroke()
        gridSteps.forEach { step in
            let x = bounds.width * (step - minLogFreq) / (maxLogFreq - minLogFreq)
            grid.move(to: CGPoint(x: x, y: 0))
            grid.line(to: CGPoint(x: x, y: bounds.height))
        }
        grid.stroke()
    }

    func drawYGrid() {
        guard let minSampleVal = minSampleVal, let maxSampleVal = maxSampleVal else { return }

        let yStep: CGFloat = 20

        let grid = NSBezierPath()
        NSColor(red: 158/255, green: 137/255, blue: 43/255, alpha: 1).setStroke()
        for step in stride(from: minSampleVal, to: maxSampleVal, by: yStep) {
            let y = bounds.height * (step - minSampleVal) / (maxSampleVal - minSampleVal)
            grid.move(to: CGPoint(x: 0, y: y))
            grid.line(to: CGPoint(x: bounds.width, y: y))
        }
        grid.stroke()
    }
}

