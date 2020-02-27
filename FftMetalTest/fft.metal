//
//  add.metal
//  MetalTestApp
//
//  Created by Yauheni Lychkouski on 2/19/20.
//  Copyright © 2020 Yauheni Lychkouski. All rights reserved.
//

#include <metal_stdlib>
#include <metal_compute>
using namespace metal;

int biranyInversed(int value, int numberOfDigits) {
    int result = 0;
    for(int i = 0; i < numberOfDigits; i++) {
        result = result << 1;
        result = result | (value & 0x1);
        value = value >> 1;
    }
    return result;
}

float2 W(int k, int N) {
    auto x = 2 * float(k) / float(N);
    return float2(cospi(x), -sinpi(x));
}

struct ParamBuff {
    int order [[ id(0) ]];
};

kernel void fft(constant ParamBuff &parameters [[ buffer(0) ]],
                device const float* inputBuffer [[ buffer(1) ]],
                device float* resultBuffer [[ buffer(2) ]],
                device float2* stepBuffer [[ buffer(3) ]],
                uint i [[ thread_position_in_grid ]],
                uint samplesNum [[ grid_size ]]) {
    auto order = parameters.order;

    // reverse_bits for metal 2.1
    auto indexInversed = biranyInversed(i, order);
    auto inputSample = inputBuffer[indexInversed];
    stepBuffer[i] = float2(inputSample, 0);

//    var intermediateResultsBuf = [Complex].init(repeating: .zero, count: samplesNum)

    for (int step = 0; step < order; step++) {
        auto mask = ((0x1 << step) - 1) * ((i >> step) & 0x1);
        auto wi = (i & mask) << (order - step - 1);
        auto wCoeff = W(wi, samplesNum);;
        stepBuffer[i] = stepBuffer[i] * wCoeff;

//         thread group barrier

        auto srcIdx = i & ~(0x1 << step);
        auto halfSum = stepBuffer[srcIdx];
//         barrier

        srcIdx = i | (0x1 << step);
        auto multiplier = ((i & (0x1 << step)) == 0) ? 1 : -1;
        auto anotherHalfSum = multiplier * stepBuffer[srcIdx];
        stepBuffer[i] = halfSum + anotherHalfSum;
    }

    auto resultComplex = stepBuffer[i];
    resultBuffer[i] = sqrt(resultComplex[0] * resultComplex[0] + resultComplex[1] * resultComplex[1]);
}
