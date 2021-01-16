//
//  RGBPixelDecoder.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2021 Susan Cheng. All rights reserved.
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
public struct RGBPixelDecoder {
    
    public var width: Int
    public var height: Int
    
    public var resolution: Resolution
    
    public var colorSpace: ColorSpace<RGBColorModel>
    
    public init(width: Int, height: Int, resolution: Resolution, colorSpace: ColorSpace<RGBColorModel>) {
        self.width = width
        self.height = height
        self.resolution = resolution
        self.colorSpace = colorSpace
    }
}

extension RGBPixelDecoder {
    
    @inlinable
    public func decode_rgb24(data: Data, fileBacked: Bool) -> Image<RGBA32ColorPixel> {
        
        var image = Image<RGBA32ColorPixel>(width: width, height: height, resolution: resolution, colorSpace: colorSpace, fileBacked: fileBacked)
        
        let pixels_count = min(image.pixels.count, data.count / 3)
        
        data.withUnsafeBufferPointer(as: (UInt8, UInt8, UInt8).self) {
            
            guard var source = $0.baseAddress else { return }
            
            image.withUnsafeMutableBufferPointer {
                
                guard var destination = $0.baseAddress else { return }
                
                for _ in 0..<pixels_count {
                    let (r, g, b) = source.pointee
                    destination.pointee = RGBA32ColorPixel(red: r, green: g, blue: b)
                    source += 1
                    destination += 1
                }
            }
        }
        
        return image
    }
    
    @inlinable
    public func decode_rgb48(data: Data, endianness: RawBitmap.Endianness, fileBacked: Bool) -> Image<RGBA64ColorPixel> {
        
        var image = Image<RGBA64ColorPixel>(width: width, height: height, resolution: resolution, colorSpace: colorSpace, fileBacked: fileBacked)
        
        let pixels_count = min(image.pixels.count, data.count / 6)
        
        switch endianness {
        case .big:
            
            data.withUnsafeBufferPointer(as: (BEUInt16, BEUInt16, BEUInt16).self) {
                
                guard var source = $0.baseAddress else { return }
                
                image.withUnsafeMutableBufferPointer {
                    
                    guard var destination = $0.baseAddress else { return }
                    
                    for _ in 0..<pixels_count {
                        let (r, g, b) = source.pointee
                        destination.pointee = RGBA64ColorPixel(red: r.representingValue, green: g.representingValue, blue: b.representingValue)
                        source += 1
                        destination += 1
                    }
                }
            }
            
        case .little:
            
            data.withUnsafeBufferPointer(as: (LEUInt16, LEUInt16, LEUInt16).self) {
                
                guard var source = $0.baseAddress else { return }
                
                image.withUnsafeMutableBufferPointer {
                    
                    guard var destination = $0.baseAddress else { return }
                    
                    for _ in 0..<pixels_count {
                        let (r, g, b) = source.pointee
                        destination.pointee = RGBA64ColorPixel(red: r.representingValue, green: g.representingValue, blue: b.representingValue)
                        source += 1
                        destination += 1
                    }
                }
            }
        }
        
        return image
    }
    
}

extension RGBPixelDecoder {
    
    @inlinable
    public func decode_rgb24(data: Data, transparent: (UInt8, UInt8, UInt8), fileBacked: Bool) -> Image<RGBA32ColorPixel> {
        
        var image = Image<RGBA32ColorPixel>(width: width, height: height, resolution: resolution, colorSpace: colorSpace, fileBacked: fileBacked)
        
        let pixels_count = min(image.pixels.count, data.count / 3)
        
        data.withUnsafeBufferPointer(as: (UInt8, UInt8, UInt8).self) {
            
            guard var source = $0.baseAddress else { return }
            
            image.withUnsafeMutableBufferPointer {
                
                guard var destination = $0.baseAddress else { return }
                
                for _ in 0..<pixels_count {
                    
                    let (r, g, b) = source.pointee
                    
                    if (r, g, b) != transparent {
                        destination.pointee = RGBA32ColorPixel(red: r, green: g, blue: b)
                    }
                    
                    source += 1
                    destination += 1
                }
            }
        }
        
        return image
    }
    
    @inlinable
    public func decode_rgb48(data: Data, transparent: (UInt16, UInt16, UInt16), endianness: RawBitmap.Endianness, fileBacked: Bool) -> Image<RGBA64ColorPixel> {
        
        var image = Image<RGBA64ColorPixel>(width: width, height: height, resolution: resolution, colorSpace: colorSpace, fileBacked: fileBacked)
        
        let pixels_count = min(image.pixels.count, data.count / 6)
        
        switch endianness {
        case .big:
            
            data.withUnsafeBufferPointer(as: (BEUInt16, BEUInt16, BEUInt16).self) {
                
                guard var source = $0.baseAddress else { return }
                
                image.withUnsafeMutableBufferPointer {
                    
                    guard var destination = $0.baseAddress else { return }
                    
                    for _ in 0..<pixels_count {
                        
                        let (r, g, b) = source.pointee
                        
                        let _r = r.representingValue
                        let _g = g.representingValue
                        let _b = b.representingValue
                        
                        if (_r, _g, _b) != transparent {
                            destination.pointee = RGBA64ColorPixel(red: _r, green: _g, blue: _b)
                        }
                        
                        source += 1
                        destination += 1
                    }
                }
            }
            
        case .little:
            
            data.withUnsafeBufferPointer(as: (LEUInt16, LEUInt16, LEUInt16).self) {
                
                guard var source = $0.baseAddress else { return }
                
                image.withUnsafeMutableBufferPointer {
                    
                    guard var destination = $0.baseAddress else { return }
                    
                    for _ in 0..<pixels_count {
                        
                        let (r, g, b) = source.pointee
                        
                        let _r = r.representingValue
                        let _g = g.representingValue
                        let _b = b.representingValue
                        
                        if (_r, _g, _b) != transparent {
                            destination.pointee = RGBA64ColorPixel(red: _r, green: _g, blue: _b)
                        }
                        
                        source += 1
                        destination += 1
                    }
                }
            }
        }
        
        return image
    }
    
}

extension RGBPixelDecoder {
    
    @inlinable
    public func decode_rgba32(data: Data, fileBacked: Bool) -> Image<RGBA32ColorPixel> {
        
        var image = Image<RGBA32ColorPixel>(width: width, height: height, resolution: resolution, colorSpace: colorSpace, fileBacked: fileBacked)
        
        let pixels_count = min(image.pixels.count, data.count / 4)
        
        data.withUnsafeBufferPointer(as: (UInt8, UInt8, UInt8, UInt8).self) {
            
            guard var source = $0.baseAddress else { return }
            
            image.withUnsafeMutableBufferPointer {
                
                guard var destination = $0.baseAddress else { return }
                
                for _ in 0..<pixels_count {
                    let (r, g, b, a) = source.pointee
                    destination.pointee = RGBA32ColorPixel(red: r, green: g, blue: b, opacity: a)
                    source += 1
                    destination += 1
                }
            }
        }
        
        return image
    }
    
    @inlinable
    public func decode_rgba64(data: Data, endianness: RawBitmap.Endianness, fileBacked: Bool) -> Image<RGBA64ColorPixel> {
        
        var image = Image<RGBA64ColorPixel>(width: width, height: height, resolution: resolution, colorSpace: colorSpace, fileBacked: fileBacked)
        
        let pixels_count = min(image.pixels.count, data.count / 8)
        
        switch endianness {
        case .big:
            
            data.withUnsafeBufferPointer(as: (BEUInt16, BEUInt16, BEUInt16, BEUInt16).self) {
                
                guard var source = $0.baseAddress else { return }
                
                image.withUnsafeMutableBufferPointer {
                    
                    guard var destination = $0.baseAddress else { return }
                    
                    for _ in 0..<pixels_count {
                        let (r, g, b, a) = source.pointee
                        destination.pointee = RGBA64ColorPixel(red: r.representingValue, green: g.representingValue, blue: b.representingValue, opacity: a.representingValue)
                        source += 1
                        destination += 1
                    }
                }
            }
            
        case .little:
            
            data.withUnsafeBufferPointer(as: (LEUInt16, LEUInt16, LEUInt16, LEUInt16).self) {
                
                guard var source = $0.baseAddress else { return }
                
                image.withUnsafeMutableBufferPointer {
                    
                    guard var destination = $0.baseAddress else { return }
                    
                    for _ in 0..<pixels_count {
                        let (r, g, b, a) = source.pointee
                        destination.pointee = RGBA64ColorPixel(red: r.representingValue, green: g.representingValue, blue: b.representingValue, opacity: a.representingValue)
                        source += 1
                        destination += 1
                    }
                }
            }
        }
        
        return image
    }
    
}
