//
//  LZWFilter.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2020 Susan Cheng. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a data
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, data, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above dataright notice and this permission notice shall be included in
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

public struct LZWFilter: PDFFilter {
    
    private struct BitsWriter {
        
        var buffer = Data()
        
        var byte: UInt8 = 0
        var bitsize: UInt = 0
        
        mutating func write(_ bits: UInt, _ size: UInt) {
            
            var bits = bits & ((1 << size) - 1)
            var remain = size
            
            while remain != 0 {
                
                let _size = min(8 - bitsize, remain)
                remain -= _size
                
                byte = (byte << _size) | UInt8(bits >> remain)
                bits &= (1 << remain) - 1
                
                bitsize += _size
                
                if bitsize == 8 {
                    buffer.append(byte)
                    byte = 0
                    bitsize = 0
                }
            }
        }
        
        mutating func flush() {
            buffer.append(byte << (8 - bitsize))
        }
    }
    
    public static func encode(_ data: Data, _ table_limit: Int = 4096) -> Data {
        
        var data = data
        
        var writer = BitsWriter()
        writer.write(256, 9)
        
        var table: [Data] = []
        table.reserveCapacity(table_limit - 258)
        
        while let char = data.first {
            
            let bit_count = log2(UInt(table.count + 258)) + 1
            
            var max_length = 0
            var index: Int?
            
            for (i, sequence) in table.enumerated() where max_length < sequence.count && data.starts(with: sequence) {
                max_length = sequence.count
                index = i
            }
            
            if let index = index {
                writer.write(UInt(index + 258), bit_count)
            } else {
                writer.write(UInt(char), bit_count)
                max_length = 1
            }
            
            let sequence =  data.prefix(max_length + 1)
            data = data.dropFirst(max_length)
            
            if table.count > table_limit - 259 {
                
                writer.write(256, bit_count)
                table.removeAll(keepingCapacity: true)
                
            } else {
                
                table.append(sequence)
            }
        }
        
        writer.write(257, log2(UInt(table.count + 258)) + 1)
        
        return writer.buffer
    }
    
    public static func decode(_ data: inout Data) -> Data? {
        
        var table: [Data] = []
        table.reserveCapacity(4096 - 258)
        
        var bits: UInt = 0
        var bitsize: UInt = 0
        
        func next_code() -> UInt? {
            
            while let byte = data.popFirst() {
                
                bits = (bits << 8) | UInt(byte)
                bitsize += 8
                
                let code_size = log2(UInt(table.count + 258)) + 1
                
                guard bitsize >= code_size else { continue }
                
                let remain = bitsize - code_size
                let code = bits >> remain
                
                bits &= (1 << remain) - 1
                bitsize = remain
                
                return code
            }
            
            return nil
        }
        
        var result = Data()
        
        while let code = next_code() {
            
            guard code != 257 else { break }
            
            if code == 256 {
                
                table.removeAll(keepingCapacity: true)
                
            } else if 0...255 ~= code {
                
                if var last_sequence = table.last {
                    last_sequence.append(UInt8(code))
                    table[table.count - 1] = last_sequence
                }
                
                result.append(UInt8(code))
                table.append(result.suffix(1))
                
            } else {
                
                let index = Int(code - 258)
                guard index < table.count else { return nil }
                
                if var last_sequence = table.last {
                    guard let char = table[index].first else { return nil }
                    last_sequence.append(char)
                    table[table.count - 1] = last_sequence
                }
                
                let sequence = table[index]
                
                result.append(sequence)
                table.append(sequence)
            }
        }
        
        return result
    }
}
