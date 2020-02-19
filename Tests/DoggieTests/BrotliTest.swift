//
//  BrotliTest.swift
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

import Doggie
import XCTest

class BrotliTest: XCTestCase {
    
    let sample = """
        //
        //  The MIT License
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
        """.data(using: .utf8)!
    
    func testBrotli() {
        
        do {
            
            let encoder = try BrotliEncoder()
            let decoder = try BrotliDecoder()
            
            let sample = self.sample
            
            let result = try decoder.process(encoder.process(self.sample))
            
            XCTAssertEqual(result, sample)
            
        } catch let error {
            
            XCTFail("\(error)")
            
        }
        
    }
    
    func testBrotliEncoderPerformance() {
        
        let sample = self.sample
        
        self.measure() {
            
            do {
                
                let encoder = try BrotliEncoder()
                
                XCTAssert(try encoder.process(sample).count > 0)
                
            } catch let error {
                
                XCTFail("\(error)")
                
            }
        }
    }
    
    func testBrotliDecoderPerformance() {
        
        do {
            
            let encoder = try BrotliEncoder()
            
            let sample = try encoder.process(self.sample)
            
            self.measure() {
                
                do {
                    
                    let decoder = try BrotliDecoder()
                    
                    XCTAssert(try decoder.process(sample).count > 0)
                    
                } catch let error {
                    
                    XCTFail("\(error)")
                    
                }
                
            }
            
        } catch let error {
            
            XCTFail("\(error)")
            
        }
        
    }
    
}
