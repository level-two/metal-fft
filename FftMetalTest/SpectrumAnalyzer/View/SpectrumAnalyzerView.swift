//
//  SpectrumAnalyzerView.swift
//  FftMetalTest
//
//  Created by Yauheni Lychkouski on 3/5/20.
//  Copyright © 2020 Yauheni Lychkouski. All rights reserved.
//

import Cocoa

@IBDesignable public final class SpectrumAnalyzerView: NSView {
    @IBOutlet var gridView: SpectrumAnalyzerGridView?
    @IBOutlet var graphView: SpectrumAnalyzerGraphView?

    override public func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }

    override public var intrinsicContentSize: CGSize {
        return CGSize(width: 100, height: 100)
    }

    private var isHiddenToken: NSKeyValueObservation?
    private let viewModel: SpectrumAnalyzerViewModel = SpectrumAnalyzerDefaultViewModel()
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
        observeHiddenState()
        notifyViewModelOfVisibilityState()
    }

    func setViewModelDelegate() {
        viewModel.delegate = self
    }

    func observeHiddenState() {
        isHiddenToken = observe(\.isHidden) { [weak self] _, change in
            guard let isHidden = change.newValue else { return }
            self?.viewModel.viewVisibilityChanged(isVisible: !isHidden)
        }
    }

    func notifyViewModelOfVisibilityState() {
        viewModel.viewVisibilityChanged(isVisible: !isHidden)
    }
}
