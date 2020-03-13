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

float2 W(int k, int N) {
    auto x = 2 * float(k) / float(N);
    return float2(cospi(x), -sinpi(x));
}

float2 complexMul(float2 x, float2 y) {
    return float2(x[0] * y[0] - x[1] * y[1],
                  x[0] * y[1] + x[1] * y[0]);
}

float complexModulus(float2 x) {
    return sqrt(x[0] * x[0] + x[1] * x[1]);
}

struct ParamBuff {
    int order [[id(0)]];
    int step [[id(1)]];
    int samplesNum [[id(2)]];
};

kernel void fftStep(constant ParamBuff &parameters [[buffer(0)]],
                device const float2* inputBuffer [[buffer(1)]],
                device float2* resultBuffer [[buffer(2)]],
                uint i [[thread_position_in_grid]]) {

    auto order = parameters.order;
    auto step = parameters.step;
    auto samplesNum = parameters.samplesNum;

    auto isEvenHalf = ( i & (1 << step) ) == 0;
    auto sample = inputBuffer[i];

    if (!isEvenHalf) {
        auto mask = isEvenHalf ? 0 : ((0x1 << step) - 1);
        auto wi = (i & mask) << (order - step - 1);
        auto wCoeff = W(wi, samplesNum);
        sample = -complexMul(sample, wCoeff);
    }

    auto idx = int(i) + (1 << step);
    if (idx < samplesNum && isEvenHalf) {
        auto otherSample = inputBuffer[idx];
        auto mask = (0x1 << step) - 1;
        auto wi = (idx & mask) << (order - step - 1);
        auto wCoeff = W(wi, samplesNum);
        sample += complexMul(otherSample, wCoeff);
    }

    idx = int(i) - (1 << step);
    if (idx >= 0 && !isEvenHalf) {
        auto otherSample = inputBuffer[idx];
        sample += otherSample;
    }

    resultBuffer[i] = sample;
}

kernel void modulus(device const float2* inputBuffer [[buffer(0)]],
                    device float* resultBuffer [[buffer(1)]],
                    uint i [[thread_position_in_grid]]) {

    resultBuffer[i] = complexModulus(inputBuffer[i]);
}

