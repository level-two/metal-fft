//
//  Fifo.swift
//  FftMetalTest
//
//  Created by Yauheni Lychkouski on 3/10/20.
//  Copyright © 2020 Yauheni Lychkouski. All rights reserved.
//

import Foundation

class Fifo<T> {

    enum FifoError: Error {
        case overflow
        case underflow
    }

    var isEmpty: Bool {
        semaphore.wait()
        let result = unsafeIsEmpty
        semaphore.signal()
        return result
    }

    var isFull: Bool {
        semaphore.wait()
        let result = unsafeIsFull
        semaphore.signal()
        return result
    }

    init(capacity: Int) {
        mem = .init(repeating: nil, count: capacity)
        rdIdx = 0
        wrIdx = 0
    }

    func push(_ data: T) throws {
        semaphore.wait()

        guard !unsafeIsFull else {
            semaphore.signal()
            throw FifoError.overflow
        }

        mem[wrIdx] = data
        wrIdx += 1
        if wrIdx == mem.count {
            wrIdx = 0
        }

        semaphore.signal()
    }

    func pop() throws -> T {
        semaphore.wait()

        guard !unsafeIsEmpty else {
            semaphore.signal()
            throw FifoError.underflow
        }

        guard let data = mem[rdIdx] else { fatalError() }
        mem[rdIdx] = nil // release stored value

        rdIdx += 1
        if rdIdx == mem.count {
            rdIdx = 0
        }

        semaphore.signal()

        return data
    }

    private var wrIdx: Int
    private var rdIdx: Int
    private let semaphore = DispatchSemaphore(value: 1)
    private var mem: [T?]
}


fileprivate extension Fifo {

    var unsafeIsFull: Bool {
        let prevRdIdx = (rdIdx == 0) ? mem.count - 1 : rdIdx - 1
        return (wrIdx == prevRdIdx)
    }

    var unsafeIsEmpty: Bool {
        return (rdIdx == wrIdx)
    }

}
