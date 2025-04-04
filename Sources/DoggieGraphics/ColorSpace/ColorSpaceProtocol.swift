//
//  ColorSpaceProtocol.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2025 Susan Cheng. All rights reserved.
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

public protocol ColorSpaceProtocol: Hashable {
    
    var model: any ColorModel.Type { get }
    
    var iccData: Data? { get }
    
    var localizedName: String? { get }
    
    var chromaticAdaptationAlgorithm: ChromaticAdaptationAlgorithm { get set }
    
    var numberOfComponents: Int { get }
    
    func rangeOfComponent(_ i: Int) -> ClosedRange<Double>
    
    var cieXYZ: ColorSpace<XYZColorModel> { get }
    
    var referenceWhite: XYZColorModel { get }
    
    var referenceBlack: XYZColorModel { get }
    
    var luminance: Double { get }
    
    var linearTone: Self { get }
    
    func isStorageEqual(_ other: Self) -> Bool
}

extension ColorSpaceProtocol {
    
    @inlinable
    func _isStorageEqual(_ other: any ColorSpaceProtocol) -> Bool {
        guard let other = other as? Self else { return false }
        return self.isStorageEqual(other)
    }
}

@usableFromInline
protocol _ColorSpaceProtocol: ColorSpaceProtocol {
    
    associatedtype Model: ColorModel
    
}
