//
//  SamplingFourierCalculator.swift
//  FftMetalTest
//
//  Created by Yauheni Lychkouski on 3/6/20.
//  Copyright © 2020 Yauheni Lychkouski. All rights reserved.
//

protocol SamplingFourierCalculator {
    init?(order: Int)
    func pushSamples(_ samples: [Double])
    var delegate: SamplingFourierCalculatorDelegate? { get set }
}
