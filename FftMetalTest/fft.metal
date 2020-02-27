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

float2 complexMul(float2 x, float2 y) {
    return float2(x[0] * y[0] - x[1] * y[1],
                  x[0] * y[1] + x[1] * y[0]);
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

    auto isEvenHalf = !((i >> step) & 0x1);

    auto mask = isEvenHalf ? 0 : ((0x1 << step) - 1);
    auto wi = (i & mask) << (order - step - 1);
    auto wCoeff = W(wi, samplesNum);

    auto sample = complexMul(inputBuffer[i], wCoeff);
    resultBuffer[i] = isEvenHalf ? sample : -sample;

    threadgroup_barrier(mem_flags::mem_none);

    auto idx = int(i) + (0x1 << step);
    if (isEvenHalf) {
        resultBuffer[idx] += sample;
    }

    threadgroup_barrier(mem_flags::mem_none);

    idx = int(i) - (0x1 << step);
    if (!isEvenHalf) {
        resultBuffer[idx] += sample;
    }
}
