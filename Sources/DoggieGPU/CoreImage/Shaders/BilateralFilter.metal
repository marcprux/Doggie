//
//  BilateralFilter.metal
//
//  The MIT License
//  Copyright (c) 2015 - 2020 Susan Cheng. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#include <metal_stdlib>
using namespace metal;

kernel void bilateral_filter(texture2d<half, access::read> input [[texture(0)]],
                             texture2d<half, access::write> output [[texture(1)]],
                             constant packed_int2 &offset [[buffer(2)]],
                             constant packed_float2 &spatial [[buffer(3)]],
                             constant float &range [[buffer(4)]],
                             uint2 gid [[thread_position_in_grid]]) {
    
    if (gid.x >= output.get_width() || gid.y >= output.get_height()) { return; }
    
    const int r0 = (int)ceil(3 * abs(spatial[0])) >> 1;
    const int r1 = (int)ceil(3 * abs(spatial[1])) >> 1;
    
    const float c0 = -0.5 / (spatial[0] * spatial[0]);
    const float c1 = -0.5 / (spatial[1] * spatial[1]);
    const float c2 = -0.5 / (range * range);
    
    half4 s = 0;
    float t = 0;
    
    const int2 coord = (int2)gid + offset;
    
    half4 p;
    
    if (0 <= coord.x && coord.x < input.get_width() && 0 <= coord.y && coord.y < input.get_height()) {
        p = input.read((uint2)coord);
    }
    
    const int minX = max(0, coord.x - r0);
    const int minY = max(0, coord.y - r1);
    const int maxX = min((int)input.get_width(), coord.x + r0 + 1);
    const int maxY = min((int)input.get_height(), coord.y + r1 + 1);
    
    for (int y = minY; y < maxY; ++y) {
        for (int x = minX; x < maxX; ++x) {
            
            const int _x = x - coord.x;
            const int _y = y - coord.y;
            
            const half4 k = input.read(uint2(x, y));
            const float w = exp(c0 * _x * _x + c1 * _y * _y + c2 * distance_squared(p, k));
            
            s += w * k;
            t += w;
        }
    }
    
    output.write(s / t, gid);
}
