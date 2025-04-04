//
//  PixelBlender.swift
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

extension ImageContext {
    
    @frozen
    @usableFromInline
    struct PixelBlender {
        
        @usableFromInline
        var destination: UnsafeMutablePointer<Pixel>
        
        @usableFromInline
        var clip: UnsafePointer<Float>?
        
        @usableFromInline
        let opacity: Double
        
        @usableFromInline
        let compositingMode: ColorCompositingMode
        
        @usableFromInline
        let blendMode: ColorBlendMode
        
        @inlinable
        @inline(__always)
        init(destination: UnsafeMutablePointer<Pixel>, clip: UnsafePointer<Float>?, opacity: Double, compositingMode: ColorCompositingMode, blendMode: ColorBlendMode) {
            self.destination = destination
            self.clip = clip
            self.opacity = opacity
            self.compositingMode = compositingMode
            self.blendMode = blendMode
        }
    }
}

extension ImageContext.PixelBlender {
    
    @inlinable
    @inline(__always)
    func draw<C: ColorPixel>(color: () -> C?) where C.Model == Pixel.Model {
        
        if compositingMode == .default && blendMode == .default {
            
            if let _clip = clip?.pointee {
                if _clip > 0, var source = color() {
                    source.opacity *= opacity * Double(_clip)
                    destination.pointee.blend(source: source)
                }
            } else if var source = color() {
                source.opacity *= opacity
                destination.pointee.blend(source: source)
            }
            
        } else {
            
            if let _clip = clip?.pointee {
                if _clip > 0, var source = color() {
                    source.opacity *= opacity * Double(_clip)
                    destination.pointee.blend(source: source, compositingMode: compositingMode, blendMode: blendMode)
                }
            } else if var source = color() {
                source.opacity *= opacity
                destination.pointee.blend(source: source, compositingMode: compositingMode, blendMode: blendMode)
            }
        }
    }
}

extension ImageContext.PixelBlender {
    
    @inlinable
    @inline(__always)
    static func + (lhs: Self, rhs: Int) -> Self {
        return Self(destination: lhs.destination + rhs, clip: lhs.clip.map { $0 + rhs }, opacity: lhs.opacity, compositingMode: lhs.compositingMode, blendMode: lhs.blendMode)
    }
    
    @inlinable
    @inline(__always)
    static func += (lhs: inout Self, rhs: Int) {
        lhs.destination += rhs
        lhs.clip = lhs.clip.map { $0 + rhs }
    }
}

extension ImageContext {
    
    @inlinable
    @inline(__always)
    func _withUnsafePixelBlender(_ body: (PixelBlender) -> Void) {
        
        let opacity = self.opacity
        let blendMode = self.blendMode
        let compositingMode = self.compositingMode
        
        guard opacity > 0 else { return }
        
        self.withUnsafeClipBufferPointer { _clip in
            
            self.withUnsafeMutableImageBufferPointer { _image in
                
                guard let _destination = _image.baseAddress else { return }
                
                body(PixelBlender(destination: _destination, clip: _clip?.baseAddress, opacity: opacity, compositingMode: compositingMode, blendMode: blendMode))
            }
        }
    }
    
    @inlinable
    @inline(__always)
    func withUnsafePixelBlender(_ body: (PixelBlender) -> Void) {
        
        let opacity = self.opacity
        let blendMode = self.blendMode
        let compositingMode = self.compositingMode
        
        guard opacity > 0 else { return }
        
        if self.isShadow {
            
            var layer = Texture<Pixel>(width: width, height: height, fileBacked: image.fileBacked)
            
            self.withUnsafeClipBufferPointer { _clip in
                
                layer.withUnsafeMutableBufferPointer { _layer in
                    
                    guard let _destination = _layer.baseAddress else { return }
                    
                    body(PixelBlender(destination: _destination, clip: _clip?.baseAddress, opacity: opacity, compositingMode: compositingMode, blendMode: blendMode))
                }
            }
            
            self._drawWithShadow(texture: layer)
            
        } else {
            
            self._withUnsafePixelBlender(body)
        }
    }
}
