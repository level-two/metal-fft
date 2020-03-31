//
//  SpectrumAnalyzerDefaultModel.swift
//  FftMetalTest
//
//  Created by Yauheni Lychkouski on 3/5/20.
//  Copyright © 2020 Yauheni Lychkouski. All rights reserved.
//

struct SpectrumAnalyzerDefaultInteractor: SpectrumAnalyzerInteractor {
    let isPlaying = Pipe<Bool>()
    let samples = Pipe<[Float32]>()
}
