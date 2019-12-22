//
//  SVGConvolveMatrixEffect.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2019 Susan Cheng. All rights reserved.
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

public struct SVGConvolveMatrixEffect : SVGEffectElement {
    
    public var region: Rect?
    
    public var regionUnit: RegionUnit = .objectBoundingBox
    
    public var source: SVGEffect.Source
    
    public var matrix: [Double]
    public var divisor: Double
    public var bias: Double
    public var orderX: Int
    public var orderY: Int
    public var edgeMode: EdgeMode
    public var preserveAlpha: Bool
    
    public var sources: [SVGEffect.Source] {
        return [source]
    }
    
    public init(source: SVGEffect.Source = .source, matrix: [Double], divisor: Double = 1, bias: Double = 0, orderX: Int, orderY: Int, edgeMode: EdgeMode = .duplicate, preserveAlpha: Bool = false) {
        precondition(orderX > 0, "nonpositive width is not allowed.")
        precondition(orderY > 0, "nonpositive height is not allowed.")
        precondition(orderX * orderY == matrix.count, "mismatch matrix count.")
        self.source = source
        self.matrix = matrix
        self.divisor = divisor
        self.bias = bias
        self.orderX = orderX
        self.orderY = orderY
        self.edgeMode = edgeMode
        self.preserveAlpha = preserveAlpha
    }
    
    public enum EdgeMode {
        case duplicate
        case wrap
        case none
    }
    
    public func visibleBound(_ sources: [SVGEffect.Source: Rect]) -> Rect? {
        return sources[source]?.inset(dx: -0.5 * Double(orderX + 1), dy: -0.5 * Double(orderY + 1))
    }
}

extension SVGConvolveMatrixEffect {
    
    public init() {
        self.init(matrix: [0, 0, 0, 0, 0, 0, 0, 0, 0], orderX: 3, orderY: 3)
    }
}

extension SVGConvolveMatrixEffect {
    
    public var xml_element: SDXMLElement {
        
        let matrix = self.matrix.map { "\(Decimal($0).rounded(scale: 9))" }
        var filter = SDXMLElement(name: "feConvolveMatrix", attributes: ["kernelMatrix": matrix.joined(separator: " "), "order": orderX == orderY ? "\(orderX)" : "\(orderX) \(orderY)"])
        
        let sum = self.matrix.reduce(0, +)
        if divisor != (sum == 0 ? 1 : sum) {
            filter.setAttribute(for: "divisor", value: "\(Decimal(divisor).rounded(scale: 9))")
        }
        if bias != 0 {
            filter.setAttribute(for: "bias", value: "\(Decimal(bias).rounded(scale: 9))")
        }
        
        filter.setAttribute(for: "preserveAlpha", value: "\(preserveAlpha)")
        
        switch edgeMode {
        case .duplicate: filter.setAttribute(for: "edgeMode", value: "duplicate")
        case .wrap: filter.setAttribute(for: "edgeMode", value: "wrap")
        case .none: filter.setAttribute(for: "edgeMode", value: "none")
        }
        
        switch self.source {
        case .source: filter.setAttribute(for: "in", value: "SourceGraphic")
        case .sourceAlpha: filter.setAttribute(for: "in", value: "SourceAlpha")
        case let .reference(uuid): filter.setAttribute(for: "in", value: uuid.uuidString)
        }
        
        return filter
    }
}
