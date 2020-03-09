//
//  SamplingFourierCalculator.swift
//  FftMetalTest
//
//  Created by Yauheni Lychkouski on 3/6/20.
//  Copyright © 2020 Yauheni Lychkouski. All rights reserved.
//

protocol SamplingFourierCalculator {
    init?(order: Int)
    var inputSamples: Pipe<[Double]> { get }
    var outputSpectrum: Pipe<[Double]> { get }
}
