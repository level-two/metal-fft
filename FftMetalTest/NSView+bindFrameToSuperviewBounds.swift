//
//  UIView+bindFrameToSuperviewBounds.swift
//  FftMetalTest
//
//  Created by Yauheni Lychkouski on 3/6/20.
//  Copyright © 2020 Yauheni Lychkouski. All rights reserved.
//

import Cocoa

extension NSView {
    func bindFrameToSuperviewBounds() {
        guard let superview = self.superview else { return }
        self.translatesAutoresizingMaskIntoConstraints = false
        self.topAnchor.constraint(equalTo: superview.topAnchor, constant: 0).isActive = true
        self.bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: 0).isActive = true
        self.leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: 0).isActive = true
        self.trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: 0).isActive = true
    }
}
