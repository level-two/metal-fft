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

    override public func layout() {
        super.layout()
//        self.layer?.frame = self.bounds
        gridLayer?.frame = self.bounds
        spectrumLayer?.frame = self.bounds
    }

    private var gridLayer: SpectrumAnalyzerGridLayer?
    private var spectrumLayer: SpectrumAnalyzerSpectrumLayer?
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
        self.layer = CALayer()

        gridLayer = SpectrumAnalyzerGridLayer()
        gridLayer?.frame = self.bounds
//        gridLayer?.constraints =
//            [.init(attribute: .minX, relativeTo: "superlayer", attribute: .minX),
//             .init(attribute: .maxX, relativeTo: "superlayer", attribute: .maxX),
//             .init(attribute: .minY, relativeTo: "superlayer", attribute: .minY),
//             .init(attribute: .maxY, relativeTo: "superlayer", attribute: .maxY)]
        gridLayer?.backgroundColor = NSColor.green.withAlphaComponent(0.5).cgColor

        spectrumLayer = SpectrumAnalyzerSpectrumLayer()
        spectrumLayer?.frame = self.bounds
//        spectrumLayer?.constraints
//            = [.init(attribute: .minX, relativeTo: "superlayer", attribute: .minX),
//               .init(attribute: .maxX, relativeTo: "superlayer", attribute: .maxX),
//               .init(attribute: .minY, relativeTo: "superlayer", attribute: .minY),
//               .init(attribute: .maxY, relativeTo: "superlayer", attribute: .maxY)]
        spectrumLayer?.backgroundColor = NSColor.red.withAlphaComponent(0.5).cgColor
        self.layer?.addSublayers(gridLayer, spectrumLayer)
    }
}
