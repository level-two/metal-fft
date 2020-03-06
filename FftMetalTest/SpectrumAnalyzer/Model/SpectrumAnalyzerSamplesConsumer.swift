//
//  SpectrumAnalyzerSamplesConsumer.swift
//  FftMetalTest
//
//  Created by Yauheni Lychkouski on 3/5/20.
//  Copyright © 2020 Yauheni Lychkouski. All rights reserved.
//

protocol SpectrumAnalyzerSamplesConsumer: class {
    func addSamples(_ samples: [Double])
}
