//
//  displayP3.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2018 Susan Cheng. All rights reserved.
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
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

@_fixed_layout
@usableFromInline
class _displayP3: CalibratedRGBColorSpace {
    
    @inlinable
    init() {
        super.init(CIEXYZColorSpace(white: Point(x: 0.3127, y: 0.3290)), red: Point(x: 0.6800, y: 0.3200), green: Point(x: 0.2650, y: 0.6900), blue: Point(x: 0.1500, y: 0.0600))
    }
    
    @inlinable
    override func convertToLinear(_ color: RGBColorModel) -> RGBColorModel {
        
        func toLinear(_ x: Double) -> Double {
            if x > 0.04045 {
                return pow((x + 0.055) / 1.055, 2.4)
            }
            return x / 12.92
        }
        return RGBColorModel(red: exteneded(color.red, toLinear), green: exteneded(color.green, toLinear), blue: exteneded(color.blue, toLinear))
    }
    
    @inlinable
    override func convertFromLinear(_ color: RGBColorModel) -> RGBColorModel {
        
        func toGamma(_ x: Double) -> Double {
            if x > 0.0031308 {
                return 1.055 * pow(x, 1 / 2.4) - 0.055
            }
            return 12.92 * x
        }
        return RGBColorModel(red: exteneded(color.red, toGamma), green: exteneded(color.green, toGamma), blue: exteneded(color.blue, toGamma))
    }
    
    @inlinable
    override func iccCurve(_ index: Int) -> iccCurve {
        return .parametric3(2.4, 1 / 1.055, 0.055 / 1.055, 1 / 12.92, 0.04045)
    }
    
    @inlinable
    override var localizedName: String? {
        return "Doggie Calibrated RGB Color Space (DisplayP3)"
    }
    
    @inlinable
    override func __equalTo(_ other: CalibratedRGBColorSpace) -> Bool {
        return type(of: other) == _displayP3.self
    }
    
    @inlinable
    override func hash(into hasher: inout Hasher) {
        hasher.combine("CalibratedRGBColorSpace")
        hasher.combine(".displayP3")
    }
}

extension ColorSpace where Model == RGBColorModel {
    
    public static var displayP3: ColorSpace {
        
        return ColorSpace(base: _displayP3())
    }
}
