//
//  XYZColorModel.swift
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

@frozen
public struct XYZColorModel: ColorModel {
    
    public typealias Indices = Range<Int>
    
    public typealias Scalar = Double
    
    @inlinable
    public static var numberOfComponents: Int {
        return 3
    }
    
    @inlinable
    public static func rangeOfComponent(_ i: Int) -> ClosedRange<Double> {
        precondition(0..<numberOfComponents ~= i, "Index out of range.")
        switch i {
        case 1: return 0...1
        default: return 0...2
        }
    }
    
    public var x: Double
    public var y: Double
    public var z: Double
    
    @inlinable
    public init() {
        self.x = 0
        self.y = 0
        self.z = 0
    }
    
    @inlinable
    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    @inlinable
    public init(luminance: Double, point: Point) {
        self.init(luminance: luminance, x: point.x, y: point.y)
    }
    
    @inlinable
    public init(luminance: Double, x: Double, y: Double) {
        if y == 0 {
            self.x = 0
            self.y = 0
            self.z = 0
        } else {
            let _y = 1 / y
            self.x = x * _y * luminance
            self.y = luminance
            self.z = (1 - x - y) * _y * luminance
        }
    }
    
    @inlinable
    public subscript(position: Int) -> Double {
        get {
            return withUnsafeTypePunnedPointer(of: self, to: Double.self) { $0[position] }
        }
        set {
            withUnsafeMutableTypePunnedPointer(of: &self, to: Double.self) { $0[position] = newValue }
        }
    }
}

extension XYZColorModel {
    
    @inlinable
    public init(_ Yxy: YxyColorModel) {
        self.init(luminance: Yxy.luminance, x: Yxy.x, y: Yxy.y)
    }
}

extension XYZColorModel {
    
    @inlinable
    public var luminance: Double {
        get {
            return y
        }
        set {
            self = XYZColorModel(luminance: newValue, point: point)
        }
    }
    
    @inlinable
    public var point: Point {
        get {
            return Point(x: x, y: y) / (x + y + z)
        }
        set {
            self = XYZColorModel(luminance: luminance, point: newValue)
        }
    }
}

extension XYZColorModel {
    
    @inlinable
    public static var black: XYZColorModel {
        return XYZColorModel()
    }
}

extension XYZColorModel {
    
    @inlinable
    public func normalized() -> XYZColorModel {
        return XYZColorModel(x: x / 2, y: y, z: z / 2)
    }
    
    @inlinable
    public func denormalized() -> XYZColorModel {
        return XYZColorModel(x: x * 2, y: y, z: z * 2)
    }
}

extension XYZColorModel {
    
    @inlinable
    public func map(_ transform: (Double) -> Double) -> XYZColorModel {
        return XYZColorModel(x: transform(x), y: transform(y), z: transform(z))
    }
    
    @inlinable
    public func reduce<Result>(into initialResult: Result, _ updateAccumulatingResult: (inout Result, Double) -> Void) -> Result {
        var accumulator = initialResult
        updateAccumulatingResult(&accumulator, x)
        updateAccumulatingResult(&accumulator, y)
        updateAccumulatingResult(&accumulator, z)
        return accumulator
    }
    
    @inlinable
    public func combined(_ other: XYZColorModel, _ transform: (Double, Double) -> Double) -> XYZColorModel {
        return XYZColorModel(x: transform(self.x, other.x), y: transform(self.y, other.y), z: transform(self.z, other.z))
    }
}

#if swift(>=5.3)

@available(macOS, unavailable)
@available(macCatalyst, unavailable)
@available(iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension XYZColorModel: _Float16ColorModelProtocol {
    
    public typealias Float16Components = FloatComponents<Float16>
    
}

#endif

extension XYZColorModel {
    
    public typealias Float32Components = FloatComponents<Float>
    
    @frozen
    public struct FloatComponents<Scalar: BinaryFloatingPoint & ScalarProtocol>: ColorComponents {
        
        public typealias Indices = Range<Int>
        
        @inlinable
        public static var numberOfComponents: Int {
            return 3
        }
        
        public var x: Scalar
        public var y: Scalar
        public var z: Scalar
        public init() {
            self.x = 0
            self.y = 0
            self.z = 0
        }
        public init(x: Scalar, y: Scalar, z: Scalar) {
            self.x = x
            self.y = y
            self.z = z
        }
        
        @inlinable
        public init(_ color: XYZColorModel) {
            self.x = Scalar(color.x)
            self.y = Scalar(color.y)
            self.z = Scalar(color.z)
        }
        
        @inlinable
        public init<T>(_ components: FloatComponents<T>) {
            self.x = Scalar(components.x)
            self.y = Scalar(components.y)
            self.z = Scalar(components.z)
        }
        
        @inlinable
        public subscript(position: Int) -> Scalar {
            get {
                return withUnsafeTypePunnedPointer(of: self, to: Scalar.self) { $0[position] }
            }
            set {
                withUnsafeMutableTypePunnedPointer(of: &self, to: Scalar.self) { $0[position] = newValue }
            }
        }
        
        @inlinable
        public var model: XYZColorModel {
            get {
                return XYZColorModel(x: Double(x), y: Double(y), z: Double(z))
            }
            set {
                self = FloatComponents(newValue)
            }
        }
    }
}

extension XYZColorModel.FloatComponents {
    
    @inlinable
    public func map(_ transform: (Scalar) -> Scalar) -> XYZColorModel.FloatComponents<Scalar> {
        return XYZColorModel.FloatComponents(x: transform(x), y: transform(y), z: transform(z))
    }
    
    @inlinable
    public func reduce<Result>(into initialResult: Result, _ updateAccumulatingResult: (inout Result, Scalar) -> Void) -> Result {
        var accumulator = initialResult
        updateAccumulatingResult(&accumulator, x)
        updateAccumulatingResult(&accumulator, y)
        updateAccumulatingResult(&accumulator, z)
        return accumulator
    }
    
    @inlinable
    public func combined(_ other: XYZColorModel.FloatComponents<Scalar>, _ transform: (Scalar, Scalar) -> Scalar) -> XYZColorModel.FloatComponents<Scalar> {
        return XYZColorModel.FloatComponents(x: transform(self.x, other.x), y: transform(self.y, other.y), z: transform(self.z, other.z))
    }
}

@inlinable
public func * (lhs: XYZColorModel, rhs: Matrix) -> XYZColorModel {
    return XYZColorModel(x: lhs.x * rhs.a + lhs.y * rhs.b + lhs.z * rhs.c + rhs.d, y: lhs.x * rhs.e + lhs.y * rhs.f + lhs.z * rhs.g + rhs.h, z: lhs.x * rhs.i + lhs.y * rhs.j + lhs.z * rhs.k + rhs.l)
}
@inlinable
public func *= (lhs: inout XYZColorModel, rhs: Matrix) {
    lhs = lhs * rhs
}
