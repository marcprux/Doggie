//
//  APNGDecoder.swift
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
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

extension PNGDecoder {
    
    class Frame {
        
        let prev_frame: Frame?
        
        let chunks: [PNGChunk]
        
        let ihdr: IHDR
        
        let fctl: FrameControlChunk
        
        let data: Data
        
        var decoded: AnyImage?
        
        init(prev_frame: Frame?, chunks: [PNGChunk], ihdr: IHDR, fctl: FrameControlChunk, data: Data) {
            self.prev_frame = prev_frame
            self.chunks = chunks
            self.ihdr = ihdr
            self.fctl = fctl
            self.data = data
        }
    }
}

extension PNGDecoder {
    
    struct AnimationControlChunk {
        
        var num_frames: BEUInt32
        var num_plays: BEUInt32
        
        init(data: Data) {
            self.num_frames = data.load(as: BEUInt32.self)
            self.num_plays = data.load(fromByteOffset: 4, as: BEUInt32.self)
        }
    }
    
    struct FrameControlChunk {
        
        var sequence_number: BEUInt32
        var width: BEUInt32
        var height: BEUInt32
        var x_offset: BEUInt32
        var y_offset: BEUInt32
        var delay_num: BEUInt16
        var delay_den: BEUInt16
        var dispose_op: UInt8
        var blend_op: UInt8
        
        init(data: Data) {
            self.sequence_number = data.load(as: BEUInt32.self)
            self.width = data.load(fromByteOffset: 4, as: BEUInt32.self)
            self.height = data.load(fromByteOffset: 8, as: BEUInt32.self)
            self.x_offset = data.load(fromByteOffset: 12, as: BEUInt32.self)
            self.y_offset = data.load(fromByteOffset: 16, as: BEUInt32.self)
            self.delay_num = data.load(fromByteOffset: 20, as: BEUInt16.self)
            self.delay_den = data.load(fromByteOffset: 22, as: BEUInt16.self)
            self.dispose_op = data.load(fromByteOffset: 24, as: UInt8.self)
            self.blend_op = data.load(fromByteOffset: 25, as: UInt8.self)
        }
    }
    
    struct FrameDataChunk {
        
        var sequence_number: BEUInt32
        var data: Data
        
        init(data: Data) {
            self.sequence_number = data.load(as: BEUInt32.self)
            self.data = data.dropFirst(4)
        }
    }
    
    mutating func resolve_frames() {
        
        var actl: AnimationControlChunk?
        var frames: [Frame] = []
        
        var fctl: FrameControlChunk?
        var data = Data()
        
        var last_sequence_number: BEUInt32 = 0
        
        for chunk in chunks {
            
            switch chunk.signature {
                
            case "acTL":
                
                guard actl == nil, chunk.data.count >= 8 else { return }
                
                actl = AnimationControlChunk(data: chunk.data)
                
            case "fcTL":
                
                guard actl != nil else { return }
                guard chunk.data.count >= 26 else { return }
                
                if let _fctl = fctl {
                    frames.append(Frame(prev_frame: frames.last, chunks: chunks, ihdr: ihdr, fctl: _fctl, data: data))
                    data = Data()
                }
                
                let _fctl = FrameControlChunk(data: chunk.data)
                fctl = _fctl
                
                guard last_sequence_number < _fctl.sequence_number else { return }
                last_sequence_number = _fctl.sequence_number
                
            case "IDAT":
                
                guard actl != nil, fctl != nil, frames.last == nil else { return }
                
                data = self.idat
                
            case "fdAT":
                
                guard actl != nil, fctl != nil else { return }
                guard chunk.data.count >= 4 else { return }
                
                let data_chunk = FrameDataChunk(data: chunk.data)
                data.append(data_chunk.data)
                
                guard last_sequence_number < data_chunk.sequence_number else { return }
                last_sequence_number = data_chunk.sequence_number
                
            default: break
            }
        }
        
        if let _fctl = fctl {
            frames.append(Frame(prev_frame: frames.last, chunks: chunks, ihdr: ihdr, fctl: _fctl, data: data))
        }
        
        guard let num_frames = actl?.num_frames, num_frames == frames.count else { return }
        
        self.actl = actl
        self.frames = frames
    }
    
}

extension PNGDecoder {
    
    var isAnimated: Bool {
        return actl != nil
    }
    
    var repeats: Int {
        return actl.map { Int($0.num_plays) } ?? 0
    }
    
    var numberOfPages: Int {
        return actl == nil ? 1 : frames.count
    }
    
    func page(_ index: Int) -> ImageRepBase {
        precondition(actl != nil || index == 0, "Index out of range.")
        return actl == nil ? self : frames[index]
    }
}

extension PNGDecoder.Frame: ImageRepBase {
    
    var width: Int {
        return Int(ihdr.width)
    }
    
    var height: Int {
        return Int(ihdr.height)
    }
    
    var resolution: Resolution {
        return _png_resolution(chunks: chunks)
    }
    
    var colorSpace: AnyColorSpace {
        return _png_colorspace(ihdr: ihdr, chunks: chunks)
    }
    
    var is_key_frame: Bool {
        
        guard let prev_frame = prev_frame else { return true }
        
        if fctl.blend_op == 0
            && fctl.width == ihdr.width
            && fctl.height == ihdr.height
            && fctl.x_offset == 0
            && fctl.y_offset == 0 {
            
            return true
        }
        
        if prev_frame.fctl.dispose_op == 1 {
            return prev_frame.fctl.width == ihdr.width
                && prev_frame.fctl.height == ihdr.height
                && prev_frame.fctl.x_offset == 0
                && prev_frame.fctl.y_offset == 0
        }
        
        return false
    }
    
    var _empty_image: AnyImage {
        return _png_blank_image(ihdr: ihdr, chunks: chunks, width: width, height: height, fileBacked: false)
    }
    
    var _disposed: AnyImage {
        switch fctl.dispose_op {
        case 0: return _image
        case 1:
            let region = png_region(x: Int(fctl.x_offset), y: Int(fctl.y_offset), width: Int(fctl.width), height: Int(fctl.height))
            return _png_clear(region, _image)
        case 2: return prev_frame?._disposed ?? _empty_image
        default: return _empty_image
        }
    }
    
    var _image: AnyImage {
        
        if let decoded = self.decoded { return decoded }
        
        let width = Int(fctl.width)
        let height = Int(fctl.height)
        
        let current_frame = _png_image(ihdr: ihdr, chunks: chunks, width: width, height: height, data: data, fileBacked: false) ?? _empty_image
        
        if is_key_frame {
            return current_frame
        }
        
        guard let prev_frame = self.prev_frame else { return current_frame }
        
        let prev_image = prev_frame._disposed
        
        let region = png_region(x: Int(fctl.x_offset), y: Int(fctl.y_offset), width: Int(fctl.width), height: Int(fctl.height))
        
        var decoded: AnyImage
        
        switch fctl.blend_op {
        case 0: decoded = _png_copy(region, prev_image, current_frame)
        case 1: decoded = _png_blend(region, prev_image, current_frame)
        default: decoded = _empty_image
        }
        
        decoded.fileBacked = true
        self.decoded = decoded
        
        return decoded
    }
    
    func image(fileBacked: Bool) -> AnyImage {
        var image = _image
        image.fileBacked = fileBacked
        return image
    }
}

struct png_region {
    
    var x: Int
    var y: Int
    var width: Int
    var height: Int
}

func _png_clear(_ region: png_region, _ image: AnyImage) -> AnyImage {
    switch image.base {
    case let image as Image<Gray16ColorPixel>: return AnyImage(_png_clear(region, image))
    case let image as Image<Gray32ColorPixel>: return AnyImage(_png_clear(region, image))
    case let image as Image<RGBA32ColorPixel>: return AnyImage(_png_clear(region, image))
    case let image as Image<RGBA64ColorPixel>: return AnyImage(_png_clear(region, image))
    default: fatalError()
    }
}

func _png_copy(_ region: png_region, _ prev_image: AnyImage, _ image: AnyImage) -> AnyImage {
    switch (prev_image.base, image.base) {
    case let (prev_image, image) as (Image<Gray16ColorPixel>, Image<Gray16ColorPixel>): return AnyImage(_png_copy(region, prev_image, image))
    case let (prev_image, image) as (Image<Gray32ColorPixel>, Image<Gray32ColorPixel>): return AnyImage(_png_copy(region, prev_image, image))
    case let (prev_image, image) as (Image<RGBA32ColorPixel>, Image<RGBA32ColorPixel>): return AnyImage(_png_copy(region, prev_image, image))
    case let (prev_image, image) as (Image<RGBA64ColorPixel>, Image<RGBA64ColorPixel>): return AnyImage(_png_copy(region, prev_image, image))
    default: fatalError()
    }
}

func _png_blend(_ region: png_region, _ prev_image: AnyImage, _ image: AnyImage) -> AnyImage {
    switch (prev_image.base, image.base) {
    case let (prev_image, image) as (Image<Gray16ColorPixel>, Image<Gray16ColorPixel>): return AnyImage(_png_blend(region, prev_image, image))
    case let (prev_image, image) as (Image<Gray32ColorPixel>, Image<Gray32ColorPixel>): return AnyImage(_png_blend(region, prev_image, image))
    case let (prev_image, image) as (Image<RGBA32ColorPixel>, Image<RGBA32ColorPixel>): return AnyImage(_png_blend(region, prev_image, image))
    case let (prev_image, image) as (Image<RGBA64ColorPixel>, Image<RGBA64ColorPixel>): return AnyImage(_png_blend(region, prev_image, image))
    default: fatalError()
    }
}

func _png_clear<P>(_ region: png_region, _ image: Image<P>) -> Image<P> {
    
    var image = image
    
    let image_width = image.width
    
    let x = max(0, region.x)
    let y = max(0, region.y)
    let width = max(0, min(region.width + region.x, image.width) - x)
    let height = max(0, min(region.height + region.y, image.height) - y)
    
    guard width != 0 && height != 0 else { return image }
    
    image.withUnsafeMutableBufferPointer {
        
        guard var pixels = $0.baseAddress else { return }
        
        pixels += x + y * image_width
        
        for _ in 0..<height {
            
            var p = pixels
            
            for _ in 0..<width {
                p.pointee = P()
                p += 1
            }
            
            pixels += image_width
        }
    }
    
    return image
}

func _png_copy<P>(_ region: png_region, _ prev_image: Image<P>, _ image: Image<P>) -> Image<P> {
    
    var prev_image = prev_image
    
    _ = prev_image.width
    let image_width = image.width
    
    let x = max(0, region.x)
    let y = max(0, region.y)
    let width = max(0, min(region.width + region.x, image.width) - x)
    let height = max(0, min(region.height + region.y, image.height) - y)
    
    guard width != 0 && height != 0 else { return prev_image }
    
    image.withUnsafeBufferPointer {
        
        guard var source = $0.baseAddress else { return }
        
        prev_image.withUnsafeMutableBufferPointer {
            
            guard var destination = $0.baseAddress else { return }
            
            destination += x + y * image_width
            
            for _ in 0..<height {
                
                var p = destination
                
                for _ in 0..<width {
                    p.pointee = source.pointee
                    source += 1
                    p += 1
                }
                
                destination += image_width
            }
        }
    }
    
    return prev_image
}

func _png_blend<P: PNGPixelProtocol>(_ region: png_region, _ prev_image: Image<P>, _ image: Image<P>) -> Image<P> {
    
    var prev_image = prev_image
    
    _ = prev_image.width
    let image_width = image.width
    
    let x = max(0, region.x)
    let y = max(0, region.y)
    let width = max(0, min(region.width + region.x, image.width) - x)
    let height = max(0, min(region.height + region.y, image.height) - y)
    
    guard width != 0 && height != 0 else { return prev_image }
    
    image.withUnsafeBufferPointer {
        
        guard var source = $0.baseAddress else { return }
        
        prev_image.withUnsafeMutableBufferPointer {
            
            guard var destination = $0.baseAddress else { return }
            
            destination += x + y * image_width
            
            for _ in 0..<height {
                
                var p = destination
                
                for _ in 0..<width {
                    p.pointee = source.pointee
                    source += 1
                    p += 1
                }
                
                destination += image_width
            }
        }
    }
    
    return prev_image
}

protocol PNGPixelProtocol {
    
    func png_blended(source: Self) -> Self
}

extension Gray16ColorPixel: PNGPixelProtocol {
    
    func png_blended(source: Gray16ColorPixel) -> Gray16ColorPixel {
        
        let d_w = UInt32(self.w)
        let d_a = UInt32(self.a)
        let s_w = UInt32(source.w)
        let s_a = UInt32(source.a)
        
        let a = (s_a + ((0xFF - s_a) * d_a) + 0x7F) / 0xFF
        
        if a == 0 {
            
            return Gray16ColorPixel()
            
        } else if d_a == 0xFF {
            
            let w = (s_a * s_w + (0xFF - s_a) * d_w + 0x7F) / 0xFF
            
            return Gray16ColorPixel(white: UInt8(w), opacity: UInt8(a))
            
        } else {
            
            let w = ((0xFF * s_a * s_w + (0xFF - s_a) * d_a * d_w) / a + 0x7F) / 0xFF
            
            return Gray16ColorPixel(white: UInt8(w), opacity: UInt8(a))
        }
    }
}

extension Gray32ColorPixel: PNGPixelProtocol {
    
    func png_blended(source: Gray32ColorPixel) -> Gray32ColorPixel {
        
        let d_w = UInt64(self.w)
        let d_a = UInt64(self.a)
        let s_w = UInt64(source.w)
        let s_a = UInt64(source.a)
        
        let a = (s_a + ((0xFFFF - s_a) * d_a) - 0x7FFF) / 0xFFFF
        
        if a == 0 {
            
            return Gray32ColorPixel()
            
        } else if d_a == 0xFFFF {
            
            let w = (s_a * s_w + (0xFFFF - s_a) * d_w - 0x7FFF) / 0xFFFF
            
            return Gray32ColorPixel(white: UInt16(w), opacity: UInt16(a))
            
        } else {
            
            let w = ((0xFFFF * s_a * s_w + (0xFFFF - s_a) * d_a * d_w) / a - 0x7FFF) / 0xFFFF
            
            return Gray32ColorPixel(white: UInt16(w), opacity: UInt16(a))
        }
    }
}

extension RGBA32ColorPixel: PNGPixelProtocol {
    
    func png_blended(source: RGBA32ColorPixel) -> RGBA32ColorPixel {
        
        let d_r = UInt32(self.r)
        let d_g = UInt32(self.g)
        let d_b = UInt32(self.b)
        let d_a = UInt32(self.a)
        let s_r = UInt32(source.r)
        let s_g = UInt32(source.g)
        let s_b = UInt32(source.b)
        let s_a = UInt32(source.a)
        
        let a = (s_a + ((0xFF - s_a) * d_a) + 0x7F) / 0xFF
        
        if a == 0 {
            
            return RGBA32ColorPixel()
            
        } else if d_a == 0xFF {
            
            let r = (s_a * s_r + (0xFF - s_a) * d_r + 0x7F) / 0xFF
            let g = (s_a * s_g + (0xFF - s_a) * d_g + 0x7F) / 0xFF
            let b = (s_a * s_b + (0xFF - s_a) * d_b + 0x7F) / 0xFF
            
            return RGBA32ColorPixel(red: UInt8(r), green: UInt8(g), blue: UInt8(b), opacity: UInt8(a))
            
        } else {
            
            let r = ((0xFF * s_a * s_r + (0xFF - s_a) * d_a * d_r) / a + 0x7F) / 0xFF
            let g = ((0xFF * s_a * s_g + (0xFF - s_a) * d_a * d_g) / a + 0x7F) / 0xFF
            let b = ((0xFF * s_a * s_b + (0xFF - s_a) * d_a * d_b) / a + 0x7F) / 0xFF
            
            return RGBA32ColorPixel(red: UInt8(r), green: UInt8(g), blue: UInt8(b), opacity: UInt8(a))
        }
    }
}

extension RGBA64ColorPixel: PNGPixelProtocol {
    
    func png_blended(source: RGBA64ColorPixel) -> RGBA64ColorPixel {
        
        let d_r = UInt64(self.r)
        let d_g = UInt64(self.g)
        let d_b = UInt64(self.b)
        let d_a = UInt64(self.a)
        let s_r = UInt64(source.r)
        let s_g = UInt64(source.g)
        let s_b = UInt64(source.b)
        let s_a = UInt64(source.a)
        
        let a = (s_a + ((0xFFFF - s_a) * d_a) - 0x7FFF) / 0xFFFF
        
        if a == 0 {
            
            return RGBA64ColorPixel()
            
        } else if d_a == 0xFFFF {
            
            let r = (s_a * s_r + (0xFFFF - s_a) * d_r - 0x7FFF) / 0xFFFF
            let g = (s_a * s_g + (0xFFFF - s_a) * d_g - 0x7FFF) / 0xFFFF
            let b = (s_a * s_b + (0xFFFF - s_a) * d_b - 0x7FFF) / 0xFFFF
            
            return RGBA64ColorPixel(red: UInt16(r), green: UInt16(g), blue: UInt16(b), opacity: UInt16(a))
            
        } else {
            
            let r = ((0xFFFF * s_a * s_r + (0xFFFF - s_a) * d_a * d_r) / a + 0x7FFF) / 0xFFFF
            let g = ((0xFFFF * s_a * s_g + (0xFFFF - s_a) * d_a * d_g) / a + 0x7FFF) / 0xFFFF
            let b = ((0xFFFF * s_a * s_b + (0xFFFF - s_a) * d_a * d_b) / a + 0x7FFF) / 0xFFFF
            
            return RGBA64ColorPixel(red: UInt16(r), green: UInt16(g), blue: UInt16(b), opacity: UInt16(a))
        }
    }
}
