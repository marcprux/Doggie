//
//  SVGDisplacementMapEffect.swift
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

public struct SVGDisplacementMapEffect: SVGEffectElement {
    
    public var region: Rect = .null
    
    public var regionUnit: SVGEffect.RegionUnit = .objectBoundingBox
    
    public var source: SVGEffect.Source
    public var displacement: SVGEffect.Source
    
    public var scale: Double
    
    public var xChannelSelector: Int
    public var yChannelSelector: Int
    
    public var sources: [SVGEffect.Source] {
        return [source, displacement]
    }
    
    public init(source: SVGEffect.Source = .source, displacement: SVGEffect.Source = .source, scale: Double = 0, xChannelSelector: Int = 3, yChannelSelector: Int = 3) {
        self.source = source
        self.displacement = displacement
        self.scale = scale
        self.xChannelSelector = xChannelSelector
        self.yChannelSelector = yChannelSelector
    }
    
    public func visibleBound(_ sources: [SVGEffect.Source: Rect]) -> Rect? {
        let inset = -ceil(abs(0.5 * self.scale))
        return self.sources.lazy.compactMap { sources[$0] }.reduce { $0.intersect($1) }?.inset(dx: inset, dy: inset)
    }
}

extension SVGDisplacementMapEffect {
    
    public var xml_element: SDXMLElement {
        
        var filter = SDXMLElement(name: "feDisplacementMap", attributes: ["scale": "\(Decimal(scale).rounded(scale: 9))"])
        
        switch xChannelSelector {
        case 0: filter.setAttribute(for: "xChannelSelector", value: "R")
        case 1: filter.setAttribute(for: "xChannelSelector", value: "G")
        case 2: filter.setAttribute(for: "xChannelSelector", value: "B")
        case 3: filter.setAttribute(for: "xChannelSelector", value: "A")
        default: break
        }
        switch yChannelSelector {
        case 0: filter.setAttribute(for: "yChannelSelector", value: "R")
        case 1: filter.setAttribute(for: "yChannelSelector", value: "G")
        case 2: filter.setAttribute(for: "yChannelSelector", value: "B")
        case 3: filter.setAttribute(for: "yChannelSelector", value: "A")
        default: break
        }
        
        switch self.source {
        case .source: filter.setAttribute(for: "in", value: "SourceGraphic")
        case .sourceAlpha: filter.setAttribute(for: "in", value: "SourceAlpha")
        case let .reference(uuid): filter.setAttribute(for: "in", value: uuid.uuidString)
        }
        
        switch self.displacement {
        case .source: filter.setAttribute(for: "in2", value: "SourceGraphic")
        case .sourceAlpha: filter.setAttribute(for: "in2", value: "SourceAlpha")
        case let .reference(uuid): filter.setAttribute(for: "in2", value: uuid.uuidString)
        }
        
        return filter
    }
}
