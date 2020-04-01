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

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        setup()
    }

    override public var intrinsicContentSize: CGSize {
        return CGSize(width: 100, height: 100)
    }

    private var gridView: SpectrumAnalyzerGridView?
    private var graphView: SpectrumAnalyzerGraphView?

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
        graphView?.update(with: viewModel)
    }
}

fileprivate extension SpectrumAnalyzerView {
    func setup() {
        addSubviews()
        setViewModelDelegate()
        observeHiddenState()
        notifyViewModelOfVisibilityState()
    }

    func addSubviews() {
        self.gridView = SpectrumAnalyzerGridView()
        self.graphView = SpectrumAnalyzerGraphView()

        [gridView, graphView].compactMap { $0 }.forEach { view in
            addSubview(view)
            view.translatesAutoresizingMaskIntoConstraints = false
            view.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
            view.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
            view.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
            view.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        }

        gridView?.configure(with: viewModel)
        graphView?.configure(with: viewModel)
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
