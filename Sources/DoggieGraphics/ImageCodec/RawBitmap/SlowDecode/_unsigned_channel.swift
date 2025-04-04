//
//  _unsigned_channel.swift
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

extension Image {
    
    @inlinable
    @inline(__always)
    mutating func _decode_unsigned_channel<T: FixedWidthInteger & UnsignedInteger>(_ bitmap: RawBitmap, _ channel_idx: Int, _ is_opaque: Bool, _: T.Type) {
        
        let width = self.width
        let height = self.height
        
        guard bitmap.startsRow < height else { return }
        
        let channel = bitmap.channels[channel_idx]
        let channel_max: T = (1 << channel.bitRange.count) &- 1
        
        let bytesPerPixel = bitmap.bitsPerPixel >> 3
        let bytesPerChannel = channel.bitRange.count >> 3
        let channelBytesOffset = channel.bitRange.lowerBound >> 3
        let channelBitsShift = channel.bitRange.lowerBound & 7
        
        let chunks = channel.bitRange.chunks(ofCount: 8)
        
        @inline(__always)
        func read_pixel(_ source: UnsafePointer<UInt8>, _ offset: Int, _ i: Int) -> UInt8 {
            switch bitmap.endianness {
            case .big: return offset == 0 ? source[i] : (source[i] << offset) | (source[i + 1] >> (8 - offset))
            case .little: return source[bytesPerPixel - i - 1]
            }
        }
        
        @inline(__always)
        func read_channel(_ source: UnsafePointer<UInt8>, _ offset: Int, _ i: Int, _ bits_count: Int) -> UInt8 {
            switch channel.endianness {
            case .big: return channelBitsShift + bits_count <= 8 ? read_pixel(source, offset, i + channelBytesOffset) << channelBitsShift : (read_pixel(source, offset, i + channelBytesOffset) << channelBitsShift) | (read_pixel(source, offset, i + 1 + channelBytesOffset) >> (8 - channelBitsShift))
            case .little: return read_pixel(source, offset, bytesPerChannel - i - 1 + channelBytesOffset)
            }
        }
        
        self.withUnsafeMutableTypePunnedBufferPointer(to: T.self) {
            
            guard var dest = $0.baseAddress else { return }
            
            let row = Pixel.numberOfComponents * width
            
            dest += bitmap.startsRow * row
            
            var data = bitmap.data
            
            for _ in bitmap.startsRow..<height {
                
                let _length = min(bitmap.bytesPerRow, data.count)
                guard _length != 0 else { return }
                
                data.popFirst(bitmap.bytesPerRow).withUnsafeBufferPointer { _source in
                    
                    guard let source = _source.baseAddress else { return }
                    var destination = dest
                    let dataBitSize = _length << 3
                    
                    var _bitsOffset = 0
                    
                    var predictor_record: T = 0
                    
                    for _ in 0..<width {
                        
                        guard _bitsOffset + bitmap.bitsPerPixel <= dataBitSize else { return }
                        
                        let _destination = destination + channel.index
                        
                        var bitPattern: T = 0
                        for (i, chunk) in chunks.enumerated() {
                            var byte = read_channel(source + _bitsOffset >> 3, _bitsOffset & 7, i, chunk.count)
                            if chunk.count != 8 {
                                byte >>= 8 - chunk.count
                            }
                            bitPattern = (bitPattern << chunk.count) | T(byte)
                        }
                        
                        let _d: T
                        
                        switch bitmap.predictor {
                        case .none: _d = bitPattern
                        case .subtract: _d = bitPattern &+ predictor_record
                        }
                        
                        _destination.pointee = _mul_div(_d & channel_max, T.max, channel_max)
                        
                        predictor_record = _d
                        
                        if is_opaque {
                            destination[Pixel.numberOfComponents - 1] = T.max
                        }
                        
                        destination += Pixel.numberOfComponents
                        _bitsOffset += bitmap.bitsPerPixel
                    }
                    
                    dest += row
                }
            }
        }
    }
    
}
