//
//  Pipe.swift
//  FftMetalTest
//
//  Created by Yauheni Lychkouski on 3/5/20.
//  Copyright © 2020 Yauheni Lychkouski. All rights reserved.
//

import Foundation

class Pipe<T> {
    private var callback: ((T) -> Void)?

    func push(_ data: T) {
        callback?(data)
    }

    func bind(callback: @escaping (T) -> Void) {
        self.callback = callback
    }

    func bindOnMain(callbackOnMain: @escaping (T) -> Void) {
        self.callback = { value in
            DispatchQueue.main.async {
                callbackOnMain(value)
            }
        }
    }

    func bind(to otherPipe: Pipe<T>?) {
        self.callback = { [weak otherPipe] data in
            otherPipe?.push(data)
        }
    }

    func bindOnMain(to otherPipe: Pipe<T>?) {
        self.callback = { [weak otherPipe] data in
            DispatchQueue.main.async {
                otherPipe?.push(data)
            }
        }
    }
}
