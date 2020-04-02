//
//  CGFloat+clamped.swift
//  FftMetalTest
//
//  Created by Yauheni Lychkouski on 4/2/20.
//  Copyright © 2020 Yauheni Lychkouski. All rights reserved.
//

import Foundation

extension CGFloat {
    func clamped(in range: ClosedRange<CGFloat>) -> CGFloat {
        return
            self >= range.upperBound ? range.upperBound :
            self <= range.lowerBound ? range.lowerBound :
            self
    }
}
