//
//  SpectrumAnalyzerModel.swift
//  FftMetalTest
//
//  Created by Yauheni Lychkouski on 3/5/20.
//  Copyright © 2020 Yauheni Lychkouski. All rights reserved.
//

protocol SpectrumAnalyzerInteractor {
    var isPlaying: Pipe<Bool> { get }
    var samples: Pipe<[Float32]> { get }
}
