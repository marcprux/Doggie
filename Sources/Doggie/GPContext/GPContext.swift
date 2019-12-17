//
//  GPContext.swift
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

#if canImport(CoreImage) || canImport(QuartzCore)

@available(macOS 10.13, iOS 11.0, tvOS 11.0, *)
private struct GPContextStyles {
    
    static let defaultShadowColor = CIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0 / 3.0)
    
    var opacity: Double = 1
    var transform: SDTransform = SDTransform.identity
    
    var shouldAntialias: Bool = true
    var antialias: Int = 5
    
    var shadowColor: CIColor = GPContextStyles.defaultShadowColor
    var shadowOffset: Size = Size()
    var shadowBlur: Double = 0
    
    var blendKernel: CIBlendKernel = .sourceOver
    
}

@available(macOS 10.13, iOS 11.0, tvOS 11.0, *)
private struct GraphicState {
    
    var clip: CIImage?
    
    var styles: GPContextStyles
    
    init(context: GPContext) {
        self.clip = context.state.clip
        self.styles = context.styles
    }
    
    func apply(to context: GPContext) {
        context.state.clip = self.clip
        context.styles = self.styles
    }
}

@available(macOS 10.13, iOS 11.0, tvOS 11.0, *)
private struct GPContextState {
    
    var clip: CIImage?
    
    var isDirty: Bool = false
    
}

@available(macOS 10.13, iOS 11.0, tvOS 11.0, *)
public class GPContext {
    
    public let width: Int
    
    public let height: Int
    
    private var _image: CIImage
    
    fileprivate var state: GPContextState = GPContextState()
    
    fileprivate var styles: GPContextStyles = GPContextStyles()
    private var graphicStateStack: [GraphicState] = []
    
    private var next: GPContext?
    
    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
        self._image = GPContext.clear
    }
    
    private init(width: Int, height: Int, image: CIImage) {
        self.width = width
        self.height = height
        self._image = image
    }
}

@available(macOS 10.13, iOS 11.0, tvOS 11.0, *)
extension GPContext {
    
    private convenience init(copyStates context: GPContext) {
        self.init(width: context.width, height: context.height)
        self.styles = context.styles
        self.styles.opacity = 1
        self.styles.shadowColor = GPContextStyles.defaultShadowColor
        self.styles.shadowOffset = Size()
        self.styles.shadowBlur = 0
        self.styles.blendKernel = .sourceOver
    }
}

@available(macOS 10.13, iOS 11.0, tvOS 11.0, *)
extension GPContext {
    
    private static let clear: CIImage = {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) { return CIImage.clear }
        return CIImage(color: CIColor.clear)
    }()
    
    private static let black: CIImage = {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) { return CIImage.black }
        return CIImage(color: CIColor.black)
    }()
    
    private var current_layer: GPContext {
        return next?.current_layer ?? self
    }
    
    public var extent: Rect {
        return Rect(x: 0, y: 0, width: width, height: height)
    }
    
    public func clone() -> GPContext {
        let clone = GPContext(width: self.width, height: self.height, image: self._image)
        clone.state = self.state
        clone.styles = self.styles
        clone.graphicStateStack = self.graphicStateStack
        clone.next = self.next?.clone()
        return clone
    }
    
    public var image: CIImage {
        return _image.cropped(to: extent)
    }
}

@available(macOS 10.13, iOS 11.0, tvOS 11.0, *)
extension GPContext {
    
    public func clearClipBuffer(with value: Double = 1) {
        switch value {
        case 1: current_layer.state.clip = nil
        case 0: current_layer.state.clip = GPContext.black
        default:
            let color = CIColor(red: CGFloat(value), green: CGFloat(value), blue: CGFloat(value), alpha: 1)
            current_layer.state.clip = CIImage(color: color)
        }
    }
    
    public func resetClip() {
        self.clearClipBuffer(with: 1)
    }
}

@available(macOS 10.13, iOS 11.0, tvOS 11.0, *)
extension GPContext {
    
    public func saveGraphicState() {
        graphicStateStack.append(GraphicState(context: current_layer))
    }
    
    public func restoreGraphicState() {
        graphicStateStack.popLast()?.apply(to: current_layer)
    }
}

@available(macOS 10.13, iOS 11.0, tvOS 11.0, *)
extension GPContext {
    
    public var opacity: Double {
        get {
            return current_layer.styles.opacity
        }
        set {
            current_layer.styles.opacity = newValue
        }
    }
    
    public var transform: SDTransform {
        get {
            return current_layer.styles.transform
        }
        set {
            current_layer.styles.transform = newValue
        }
    }
    
    public var shouldAntialias: Bool {
        get {
            return current_layer.styles.shouldAntialias
        }
        set {
            current_layer.styles.shouldAntialias = newValue
        }
    }
    public var antialias: Int {
        get {
            return current_layer.styles.antialias
        }
        set {
            current_layer.styles.antialias = max(1, newValue)
        }
    }
    
    public var shadowColor: CIColor {
        get {
            return current_layer.styles.shadowColor
        }
        set {
            current_layer.styles.shadowColor = newValue
        }
    }
    
    public var shadowOffset: Size {
        get {
            return current_layer.styles.shadowOffset
        }
        set {
            current_layer.styles.shadowOffset = newValue
        }
    }
    
    public var shadowBlur: Double {
        get {
            return current_layer.styles.shadowBlur
        }
        set {
            current_layer.styles.shadowBlur = newValue
        }
    }
    
    public var blendKernel: CIBlendKernel {
        get {
            return current_layer.styles.blendKernel
        }
        set {
            current_layer.styles.blendKernel = newValue
        }
    }
}

@available(macOS 10.13, iOS 11.0, tvOS 11.0, *)
extension GPContext {
    
    private func blend_layer(_ layer: CIImage) {
        
        current_layer.state.isDirty = true
        
        var layer = layer
        
        if let clip = current_layer.state.clip {
            layer = layer.applyingFilter("CIBlendWithMask", parameters: [kCIInputBackgroundImageKey: GPContext.clear, kCIInputMaskImageKey: clip])
        }
        
        if blendKernel === CIBlendKernel.sourceOver {
            current_layer._image = layer.composited(over: current_layer._image)
        } else {
            current_layer._image = blendKernel.apply(foreground: layer, background: current_layer._image) ?? current_layer._image
        }
    }
    
    private func draw_layer(_ layer: CIImage) {
        
        var layer = layer
        
        if shadowColor.alpha > 0 && shadowBlur > 0 {
            
            if #available(macOS 10.14, iOS 12.0, tvOS 12.0, *) {
                layer = layer.insertingIntermediate()
            }
            
            let shadow_color = CIImage(color: shadowColor)
            let shadow = layer.applyingGaussianBlur(sigma: 0.5 * shadowBlur).transformed(by: .translate(x: shadowOffset.width, y: shadowOffset.height))
            
            let image = shadow_color.applyingFilter("CIBlendWithAlphaMask", parameters: [kCIInputBackgroundImageKey: GPContext.clear, kCIInputMaskImageKey: shadow])
            
            self.blend_layer(image)
        }
        
        self.blend_layer(layer)
    }
}

@available(macOS 10.13, iOS 11.0, tvOS 11.0, *)
extension GPContext {
    
    public func beginTransparencyLayer() {
        
        if let next = self.next {
            
            next.beginTransparencyLayer()
            
        } else {
            
            let width = self.width
            let height = self.height
            
            if width == 0 || height == 0 {
                return
            }
            
            self.next = GPContext(copyStates: self)
        }
    }
    
    public func endTransparencyLayer() {
        
        guard let next = self.next else { return }
        
        if next.next != nil {
            
            next.endTransparencyLayer()
            
        } else {
            
            let width = self.width
            let height = self.height
            
            self.next = nil
            
            if width == 0 || height == 0 {
                return
            }
            
            guard next.state.isDirty else { return }
            
            self.draw_layer(next._image)
        }
    }
    
}

@available(macOS 10.13, iOS 11.0, tvOS 11.0, *)
extension GPContext {
    
    public func draw(path: CGPath, rule: CGPathFillRule, color: CIColor) {
        
        if shape.reduce(0, { $0 + $1.count }) == 0 || width == 0 || height == 0 || self.transform.determinant.almostZero() {
            return
        }
        
        let path = path.transformed(by: self.transform)
        let intersection = path.boundingBoxOfPath.intersection(CGRect(extent))
        
        guard !intersection.isNull else { return }
        guard let mask = try? CGPathProcessorKernel.apply(withExtent: intersection, path: path, rule: rule) else { return }
        
        let layer = CIImage(color: color).applyingFilter("CIBlendWithMask", parameters: [kCIInputBackgroundImageKey: GPContext.clear, kCIInputMaskImageKey: mask])
        
        self.draw_layer(layer)
    }
}

@available(macOS 10.13, iOS 11.0, tvOS 11.0, *)
extension GPContext {
    
    public func draw(image: CIImage, transform: SDTransform) {
        
        var image = image.transformed(by: transform * self.transform).cropped(to: extent)
        
        if #available(macOS 10.14, iOS 12.0, tvOS 12.0, *) {
            image = image.insertingIntermediate()
        }
        
        self.draw_layer(image)
    }
}

@available(macOS 10.13, iOS 11.0, tvOS 11.0, *)
extension GPContext {
    
    public func clip(path: CGPath, rule: CGPathFillRule) {
        
        self.clearClipBuffer(with: 0)
        
        if shape.reduce(0, { $0 + $1.count }) == 0 || width == 0 || height == 0 || self.transform.determinant.almostZero() {
            return
        }
        
        let path = path.transformed(by: self.transform)
        let intersection = path.boundingBoxOfPath.intersection(CGRect(extent))
        
        guard !intersection.isNull else { return }
        guard var clip = try? CGPathProcessorKernel.apply(withExtent: intersection, path: path, rule: rule) else { return }
        
        clip = clip.composited(over: GPContext.black)
        
        if #available(macOS 10.14, iOS 12.0, tvOS 12.0, *) {
            clip = clip.insertingIntermediate()
        }
        
        current_layer.state.clip = clip
    }
}

@available(macOS 10.13, iOS 11.0, tvOS 11.0, *)
extension GPContext {
    
    public func drawClip(body: (GPContext) throws -> Void) rethrows {
        
        let width = self.width
        let height = self.height
        
        if width == 0 || height == 0 {
            return
        }
        
        let _clip = GPContext(copyStates: current_layer)
        
        try body(_clip)
        
        if _clip.state.isDirty {
            
            var clip = _clip._image.applyingFilter("CIColorMonochrome", parameters: [kCIInputColorKey: CIColor.white]).composited(over: GPContext.black)
            
            if #available(macOS 10.14, iOS 12.0, tvOS 12.0, *) {
                clip = clip.insertingIntermediate()
            }
            
            current_layer.state.clip = clip
            
        } else {
            current_layer.clearClipBuffer(with: 0)
        }
    }
}

#endif
