//
//  ImageTest.swift
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

import Doggie
import XCTest

class ImageTest: XCTestCase {
    
    let accuracy = 0.00000001
    
    var sample: Image<ARGB32ColorPixel> = {
        
        let context = ImageContext<ARGB32ColorPixel>(width: 100, height: 100, colorSpace: ColorSpace.sRGB)
        
        context.draw(ellipseIn: Rect(x: 10, y: 35, width: 55, height: 55), color: RGBColorModel(red: 247/255, green: 217/255, blue: 12/255))
        
        context.draw(ellipseIn: Rect(x: 10, y: 35, width: 55, height: 55), stroke: Stroke(width: 1, cap: .round, join: .round, color: RGBColorModel()))
        
        context.draw(ellipseIn: Rect(x: 35, y: 10, width: 55, height: 55), color: RGBColorModel(red: 234/255, green: 24/255, blue: 71/255))
        
        context.draw(ellipseIn: Rect(x: 35, y: 10, width: 55, height: 55), stroke: Stroke(width: 1, cap: .round, join: .round, color: RGBColorModel()))
        
        return context.image
    }()
    
    func testStencilTextureConvolutionA() {
        
        var stencil: StencilTexture<Double> = StencilTexture(width: 100, height: 100)
        
        stencil.withUnsafeMutableBufferPointer {
            
            guard var ptr = $0.baseAddress else { return }
            
            for _ in 0..<$0.count {
                ptr.pointee = Double.random(in: 0...1)
                ptr += 1
            }
        }
        
        for s in [1, 2, 3, 5, 7, 11] {
            for t in [1, 2, 3, 5, 7, 11] {
                
                var horizontal = [Double](repeating: 0, count: s)
                var vertical = [Double](repeating: 0, count: t)
                for i in 0..<horizontal.count {
                    horizontal[i] = Double.random(in: -1...1)
                }
                for i in 0..<vertical.count {
                    vertical[i] = Double.random(in: -1...1)
                }
                
                let filter = vertical.flatMap { a in horizontal.map { a * $0 } }
                
                guard let (horizontal2, vertical2) = separate_convolution_filter(filter, horizontal.count, vertical.count) else { XCTFail(); return }
                
                let result1 = stencil.convolution(horizontal: horizontal, vertical: vertical, algorithm: .direct)
                let result2 = stencil.convolution(horizontal: horizontal, vertical: vertical, algorithm: .cooleyTukey)
                let result3 = stencil.convolution(filter, horizontal.count, vertical.count, algorithm: .direct)
                let result4 = stencil.convolution(filter, horizontal.count, vertical.count, algorithm: .cooleyTukey)
                let result5 = stencil.convolution(horizontal: horizontal2, vertical: vertical2, algorithm: .direct)
                let result6 = stencil.convolution(horizontal: horizontal2, vertical: vertical2, algorithm: .cooleyTukey)
                
                XCTAssertEqual(result1.width, result2.width)
                XCTAssertEqual(result1.height, result2.height)
                
                XCTAssertEqual(result1.width, result3.width)
                XCTAssertEqual(result1.height, result3.height)
                
                XCTAssertEqual(result1.width, result4.width)
                XCTAssertEqual(result1.height, result4.height)
                
                XCTAssertEqual(result1.width, result5.width)
                XCTAssertEqual(result1.height, result5.height)
                
                XCTAssertEqual(result1.width, result6.width)
                XCTAssertEqual(result1.height, result6.height)
                
                for i in 0..<result1.pixels.count {
                    XCTAssertEqual(result1.pixels[i], result2.pixels[i], accuracy: accuracy)
                    XCTAssertEqual(result1.pixels[i], result3.pixels[i], accuracy: accuracy)
                    XCTAssertEqual(result1.pixels[i], result4.pixels[i], accuracy: accuracy)
                    XCTAssertEqual(result1.pixels[i], result5.pixels[i], accuracy: accuracy)
                    XCTAssertEqual(result1.pixels[i], result6.pixels[i], accuracy: accuracy)
                }
            }
        }
    }
    
    func testStencilTextureConvolutionB() {
        
        var stencil: StencilTexture<Double> = StencilTexture(width: 100, height: 100)
        
        stencil.withUnsafeMutableBufferPointer {
            
            guard var ptr = $0.baseAddress else { return }
            
            for _ in 0..<$0.count {
                ptr.pointee = Double.random(in: 0...1)
                ptr += 1
            }
        }
        
        for s in [1, 2, 3, 5, 7, 11] {
            for t in [1, 2, 3, 5, 7, 11] {
                
                var horizontal = [Double](repeating: 0, count: s)
                var vertical = [Double](repeating: 0, count: t)
                for i in 0..<horizontal.count {
                    horizontal[i] = Double(Int.random(in: 0...10))
                }
                for i in 0..<vertical.count {
                    vertical[i] = Double(Int.random(in: 0...10))
                }
                
                let filter = vertical.flatMap { a in horizontal.map { a * $0 } }
                
                guard let (horizontal2, vertical2) = separate_convolution_filter(filter, horizontal.count, vertical.count) else { XCTFail(); return }
                
                let result1 = stencil.convolution(horizontal: horizontal, vertical: vertical, algorithm: .direct)
                let result2 = stencil.convolution(horizontal: horizontal, vertical: vertical, algorithm: .cooleyTukey)
                let result3 = stencil.convolution(filter, horizontal.count, vertical.count, algorithm: .direct)
                let result4 = stencil.convolution(filter, horizontal.count, vertical.count, algorithm: .cooleyTukey)
                let result5 = stencil.convolution(horizontal: horizontal2, vertical: vertical2, algorithm: .direct)
                let result6 = stencil.convolution(horizontal: horizontal2, vertical: vertical2, algorithm: .cooleyTukey)
                
                XCTAssertEqual(result1.width, result2.width)
                XCTAssertEqual(result1.height, result2.height)
                
                XCTAssertEqual(result1.width, result3.width)
                XCTAssertEqual(result1.height, result3.height)
                
                XCTAssertEqual(result1.width, result4.width)
                XCTAssertEqual(result1.height, result4.height)
                
                XCTAssertEqual(result1.width, result5.width)
                XCTAssertEqual(result1.height, result5.height)
                
                XCTAssertEqual(result1.width, result6.width)
                XCTAssertEqual(result1.height, result6.height)
                
                for i in 0..<result1.pixels.count {
                    XCTAssertEqual(result1.pixels[i], result2.pixels[i], accuracy: accuracy)
                    XCTAssertEqual(result1.pixels[i], result3.pixels[i], accuracy: accuracy)
                    XCTAssertEqual(result1.pixels[i], result4.pixels[i], accuracy: accuracy)
                    XCTAssertEqual(result1.pixels[i], result5.pixels[i], accuracy: accuracy)
                    XCTAssertEqual(result1.pixels[i], result6.pixels[i], accuracy: accuracy)
                }
            }
        }
    }
    
    func testStencilTextureConvolutionC() {
        
        var stencil: StencilTexture<Double> = StencilTexture(width: 100, height: 100)
        
        stencil.withUnsafeMutableBufferPointer {
            
            guard var ptr = $0.baseAddress else { return }
            
            for _ in 0..<$0.count {
                ptr.pointee = Double.random(in: 0...1)
                ptr += 1
            }
        }
        
        for s in [1, 2, 3, 5, 7, 11] {
            for t in [1, 2, 3, 5, 7, 11] {
                
                var filter = [Double](repeating: 0, count: s * t)
                for i in 0..<filter.count {
                    filter[i] = Double.random(in: -1...1)
                }
                
                let separated = separate_convolution_filter(filter, s, t)
                
                let result1 = stencil.convolution(filter, s, t, algorithm: .direct)
                let result2 = stencil.convolution(filter, s, t, algorithm: .cooleyTukey)
                let result3 = separated.map { stencil.convolution(horizontal: $0, vertical: $1, algorithm: .direct) } ?? result1
                let result4 = separated.map { stencil.convolution(horizontal: $0, vertical: $1, algorithm: .cooleyTukey) } ?? result2
                
                XCTAssertEqual(result1.width, result2.width)
                XCTAssertEqual(result1.height, result2.height)
                
                XCTAssertEqual(result1.width, result3.width)
                XCTAssertEqual(result1.height, result3.height)
                
                XCTAssertEqual(result1.width, result4.width)
                XCTAssertEqual(result1.height, result4.height)
                
                for i in 0..<result1.pixels.count {
                    XCTAssertEqual(result1.pixels[i], result2.pixels[i], accuracy: accuracy)
                    XCTAssertEqual(result1.pixels[i], result3.pixels[i], accuracy: accuracy)
                    XCTAssertEqual(result1.pixels[i], result4.pixels[i], accuracy: accuracy)
                }
            }
        }
    }
    
    func testImageGaussianBlur() {
        
        var image = Image<Float64ColorPixel<RGBColorModel>>(width: 100, height: 100, colorSpace: .sRGB)
        
        image.withUnsafeMutableBufferPointer {
            
            guard var ptr = $0.baseAddress else { return }
            
            for _ in 0..<$0.count {
                ptr.pointee.color.red = Double.random(in: 0...1)
                ptr.pointee.color.green = Double.random(in: 0...1)
                ptr.pointee.color.blue = Double.random(in: 0...1)
                ptr.pointee.opacity = Double.random(in: 0...1)
                ptr += 1
            }
        }
        
        for t in 2...5 {
            
            let _filter = GaussianBlurFilter(Double(t))
            let filter = _filter.flatMap { a in _filter.map { a * $0 } }
            
            guard let (horizontal, vertical) = separate_convolution_filter(filter, _filter.count, _filter.count) else { XCTFail(); return }
            
            let result1 = GaussianBlur(image, Double(t), .direct)
            let result2 = GaussianBlur(image, Double(t), .cooleyTukey)
            let result3 = image.convolution(filter, _filter.count, _filter.count, algorithm: .direct)
            let result4 = image.convolution(filter, _filter.count, _filter.count, algorithm: .cooleyTukey)
            let result5 = image.convolution(horizontal: horizontal, vertical: vertical, algorithm: .direct)
            let result6 = image.convolution(horizontal: horizontal, vertical: vertical, algorithm: .cooleyTukey)
            
            XCTAssertEqual(result1.width, result2.width)
            XCTAssertEqual(result1.height, result2.height)
            
            XCTAssertEqual(result1.width, result3.width)
            XCTAssertEqual(result1.height, result3.height)
            
            XCTAssertEqual(result1.width, result4.width)
            XCTAssertEqual(result1.height, result4.height)
            
            XCTAssertEqual(result1.width, result5.width)
            XCTAssertEqual(result1.height, result5.height)
            
            XCTAssertEqual(result1.width, result6.width)
            XCTAssertEqual(result1.height, result6.height)
            
            for i in 0..<result1.pixels.count {
                XCTAssertEqual(result1.pixels[i].red, result2.pixels[i].red, accuracy: accuracy)
                XCTAssertEqual(result1.pixels[i].red, result3.pixels[i].red, accuracy: accuracy)
                XCTAssertEqual(result1.pixels[i].red, result4.pixels[i].red, accuracy: accuracy)
                XCTAssertEqual(result1.pixels[i].red, result5.pixels[i].red, accuracy: accuracy)
                XCTAssertEqual(result1.pixels[i].red, result6.pixels[i].red, accuracy: accuracy)
                
                XCTAssertEqual(result1.pixels[i].green, result2.pixels[i].green, accuracy: accuracy)
                XCTAssertEqual(result1.pixels[i].green, result3.pixels[i].green, accuracy: accuracy)
                XCTAssertEqual(result1.pixels[i].green, result4.pixels[i].green, accuracy: accuracy)
                XCTAssertEqual(result1.pixels[i].green, result5.pixels[i].green, accuracy: accuracy)
                XCTAssertEqual(result1.pixels[i].green, result6.pixels[i].green, accuracy: accuracy)
                
                XCTAssertEqual(result1.pixels[i].blue, result2.pixels[i].blue, accuracy: accuracy)
                XCTAssertEqual(result1.pixels[i].blue, result3.pixels[i].blue, accuracy: accuracy)
                XCTAssertEqual(result1.pixels[i].blue, result4.pixels[i].blue, accuracy: accuracy)
                XCTAssertEqual(result1.pixels[i].blue, result5.pixels[i].blue, accuracy: accuracy)
                XCTAssertEqual(result1.pixels[i].blue, result6.pixels[i].blue, accuracy: accuracy)
                
                XCTAssertEqual(result1.pixels[i].opacity, result2.pixels[i].opacity, accuracy: accuracy)
                XCTAssertEqual(result1.pixels[i].opacity, result3.pixels[i].opacity, accuracy: accuracy)
                XCTAssertEqual(result1.pixels[i].opacity, result4.pixels[i].opacity, accuracy: accuracy)
                XCTAssertEqual(result1.pixels[i].opacity, result5.pixels[i].opacity, accuracy: accuracy)
                XCTAssertEqual(result1.pixels[i].opacity, result6.pixels[i].opacity, accuracy: accuracy)
            }
        }
    }
    
    func testDrawing() {
        
        let shape = try! Shape(code: "M184.529,100c0-100-236.601,36.601-150,86.601c86.599,50,86.599-223.2,0-173.2C-52.071,63.399,184.529,200,184.529,100z")
        
        let mask = try! Shape(code: "M100.844,122.045c1.51-14.455,1.509-29.617-0.001-44.09c17.241-7.306,33.295-11.16,46.526-11.16c28.647,0,34.66,18.057,34.66,33.205c0,11.428-3.231,20.032-9.604,25.573c-5.826,5.064-14.252,7.632-25.048,7.632c-0.002,0-0.005,0-0.007,0C134.13,133.204,118.076,129.349,100.844,122.045z M57.276,96.89c11.771-8.541,24.9-16.122,38.18-22.044C91.51,43.038,78.813,9.759,54.625,9.759c-5.832,0-12.172,1.954-18.846,5.807c-11.233,6.485-17.211,14.737-17.766,24.525C17.084,56.461,31.729,77.609,57.276,96.89z M35.779,184.436c6.673,3.853,13.014,5.807,18.846,5.807c24.184,0,36.883-33.279,40.832-65.088c-13.283-5.925-26.413-13.506-38.181-22.045c-25.547,19.281-40.192,40.43-39.263,56.801C18.568,169.699,24.546,177.95,35.779,184.436z M61.514,100c10.717,7.645,22.534,14.467,34.517,19.929c1.261-13.099,1.261-26.743-0.001-39.857C84.05,85.531,72.234,92.354,61.514,100z")
        
        let context = ImageContext<ARGB32ColorPixel>(width: 500, height: 500, colorSpace: ColorSpace.sRGB)
        
        context.draw(rect: Rect(x: 0, y: 0, width: 500, height: 500), color: .black)
        
        context.clip(shape: mask, winding: .nonZero)
        
        context.beginTransparencyLayer()
        
        context.draw(rect: Rect(x: 0, y: 0, width: 500, height: 500), color: .white)
        context.draw(shape: shape, winding: .nonZero, color: .black)
        
        context.endTransparencyLayer()
        
        XCTAssertTrue(context.image.pixels.allSatisfy { $0.color == .black })
    }
    
    func testClipPerformance() {
        
        self.measure() {
            
            let context = ImageContext<ARGB32ColorPixel>(width: 500, height: 500, colorSpace: ColorSpace.sRGB)
            
            context.clip(shape: Shape(ellipseIn: Rect(x: 20, y: 20, width: 460, height: 460)), winding: .nonZero)
            
            context.scale(5)
            
            let stop1 = GradientStop(offset: 0, color: Color(colorSpace: context.colorSpace, color: RGBColorModel(red: 1, green: 0, blue: 0)))
            let stop2 = GradientStop(offset: 1, color: Color(colorSpace: context.colorSpace, color: RGBColorModel(red: 0, green: 0, blue: 1)))
            
            context.drawLinearGradient(stops: [stop1, stop2], start: Point(x: 50, y: 50), end: Point(x: 250, y: 250), startSpread: .pad, endSpread: .pad)
            
        }
    }
    
    func testLinearGradientPerformance() {
        
        self.measure() {
            
            let context = ImageContext<ARGB32ColorPixel>(width: 500, height: 500, colorSpace: ColorSpace.sRGB)
            
            context.scale(5)
            
            let stop1 = GradientStop(offset: 0, color: Color(colorSpace: context.colorSpace, color: RGBColorModel(red: 1, green: 0, blue: 0)))
            let stop2 = GradientStop(offset: 1, color: Color(colorSpace: context.colorSpace, color: RGBColorModel(red: 0, green: 0, blue: 1)))
            
            context.drawLinearGradient(stops: [stop1, stop2], start: Point(x: 50, y: 50), end: Point(x: 250, y: 250), startSpread: .pad, endSpread: .pad)
            
        }
    }
    
    func testRadialGradientPerformance() {
        
        self.measure() {
            
            let context = ImageContext<ARGB32ColorPixel>(width: 500, height: 500, colorSpace: ColorSpace.sRGB)
            
            context.scale(5)
            
            let stop1 = GradientStop(offset: 0, color: Color(colorSpace: context.colorSpace, color: RGBColorModel(red: 1, green: 0, blue: 0)))
            let stop2 = GradientStop(offset: 1, color: Color(colorSpace: context.colorSpace, color: RGBColorModel(red: 0, green: 0, blue: 1)))
            
            context.drawRadialGradient(stops: [stop1, stop2], start: Point(x: 100, y: 150), startRadius: 0, end: Point(x: 150, y: 150), endRadius: 100, startSpread: .pad, endSpread: .pad)
            
        }
    }
    
    func testOrthographicProjectPerformance() {
        
        self.measure() {
            
            let context = ImageContext<ARGB32ColorPixel>(width: 300, height: 300, colorSpace: ColorSpace.sRGB)
            
            let matrix = Matrix.scale(0.4) * Matrix.rotateY(.pi / 6) * Matrix.rotateX(.pi / 6) * Matrix.translate(x: 0, y: 0, z: 100)
            
            let c0 = Float64ColorPixel(red: 0, green: 0, blue: 0, opacity: 1)
            let c1 = Float64ColorPixel(red: 1, green: 0, blue: 0, opacity: 1)
            let c2 = Float64ColorPixel(red: 0, green: 1, blue: 0, opacity: 1)
            let c3 = Float64ColorPixel(red: 0, green: 0, blue: 1, opacity: 1)
            let c4 = Float64ColorPixel(red: 1, green: 1, blue: 0, opacity: 1)
            let c5 = Float64ColorPixel(red: 1, green: 0, blue: 1, opacity: 1)
            let c6 = Float64ColorPixel(red: 0, green: 1, blue: 1, opacity: 1)
            let c7 = Float64ColorPixel(red: 1, green: 1, blue: 1, opacity: 1)
            
            let v0 = ColorVertex(position: Vector(x: 1, y: 1, z: -1) * matrix, color: c0)
            let v1 = ColorVertex(position: Vector(x: -1, y: 1, z: -1) * matrix, color: c1)
            let v2 = ColorVertex(position: Vector(x: -1, y: -1, z: -1) * matrix, color: c5)
            let v3 = ColorVertex(position: Vector(x: 1, y: -1, z: -1) * matrix, color: c3)
            let v4 = ColorVertex(position: Vector(x: 1, y: 1, z: 1) * matrix, color: c2)
            let v5 = ColorVertex(position: Vector(x: -1, y: 1, z: 1) * matrix, color: c4)
            let v6 = ColorVertex(position: Vector(x: -1, y: -1, z: 1) * matrix, color: c7)
            let v7 = ColorVertex(position: Vector(x: 1, y: -1, z: 1) * matrix, color: c6)
            
            // face v0, v1, v2, v3
            let t0 = (v0, v1, v2)
            let t1 = (v0, v2, v3)
            
            // face v7, v6, v5, v4
            let t2 = (v7, v6, v5)
            let t3 = (v7, v5, v4)
            
            // face v4, v0, v3, v7
            let t4 = (v4, v0, v3)
            let t5 = (v4, v3, v7)
            
            // face v1, v5, v6, v2
            let t6 = (v1, v5, v6)
            let t7 = (v1, v6, v2)
            
            // face v0, v4, v5, v1
            let t8 = (v0, v4, v5)
            let t9 = (v0, v5, v1)
            
            // face v7, v3, v2, v6
            let t10 = (v7, v3, v2)
            let t11 = (v7, v2, v6)
            
            func shader(stageIn: ImageContextRenderStageIn<ColorVertex>) -> Float64ColorPixel<RGBColorModel> {
                
                return stageIn.vertex.color
            }
            
            let triangles = [t0, t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11]
            
            context.renderCullingMode = .back
            context.renderDepthCompareMode = .less
            
            context.render(triangles, projection: OrthographicProjectMatrix(nearZ: 1, farZ: 500), shader: shader)
            
        }
    }
    
    func testPerspectiveProjectPerformance() {
        
        self.measure() {
            
            let context = ImageContext<ARGB32ColorPixel>(width: 300, height: 300, colorSpace: ColorSpace.sRGB)
            
            let matrix = Matrix.rotateY(.pi / 6) * Matrix.rotateX(.pi / 6) * Matrix.translate(x: 0, y: 0, z: 100)
            
            let c0 = Float64ColorPixel(red: 0, green: 0, blue: 0, opacity: 1)
            let c1 = Float64ColorPixel(red: 1, green: 0, blue: 0, opacity: 1)
            let c2 = Float64ColorPixel(red: 0, green: 1, blue: 0, opacity: 1)
            let c3 = Float64ColorPixel(red: 0, green: 0, blue: 1, opacity: 1)
            let c4 = Float64ColorPixel(red: 1, green: 1, blue: 0, opacity: 1)
            let c5 = Float64ColorPixel(red: 1, green: 0, blue: 1, opacity: 1)
            let c6 = Float64ColorPixel(red: 0, green: 1, blue: 1, opacity: 1)
            let c7 = Float64ColorPixel(red: 1, green: 1, blue: 1, opacity: 1)
            
            let v0 = ColorVertex(position: Vector(x: 25, y: 25, z: -25) * matrix, color: c0)
            let v1 = ColorVertex(position: Vector(x: -25, y: 25, z: -25) * matrix, color: c1)
            let v2 = ColorVertex(position: Vector(x: -25, y: -25, z: -25) * matrix, color: c5)
            let v3 = ColorVertex(position: Vector(x: 25, y: -25, z: -25) * matrix, color: c3)
            let v4 = ColorVertex(position: Vector(x: 25, y: 25, z: 25) * matrix, color: c2)
            let v5 = ColorVertex(position: Vector(x: -25, y: 25, z: 25) * matrix, color: c4)
            let v6 = ColorVertex(position: Vector(x: -25, y: -25, z: 25) * matrix, color: c7)
            let v7 = ColorVertex(position: Vector(x: 25, y: -25, z: 25) * matrix, color: c6)
            
            // face v0, v1, v2, v3
            let t0 = (v0, v1, v2)
            let t1 = (v0, v2, v3)
            
            // face v7, v6, v5, v4
            let t2 = (v7, v6, v5)
            let t3 = (v7, v5, v4)
            
            // face v4, v0, v3, v7
            let t4 = (v4, v0, v3)
            let t5 = (v4, v3, v7)
            
            // face v1, v5, v6, v2
            let t6 = (v1, v5, v6)
            let t7 = (v1, v6, v2)
            
            // face v0, v4, v5, v1
            let t8 = (v0, v4, v5)
            let t9 = (v0, v5, v1)
            
            // face v7, v3, v2, v6
            let t10 = (v7, v3, v2)
            let t11 = (v7, v2, v6)
            
            func shader(stageIn: ImageContextRenderStageIn<ColorVertex>) -> Float64ColorPixel<RGBColorModel> {
                
                return stageIn.vertex.color
            }
            
            let triangles = [t0, t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11]
            
            context.renderCullingMode = .back
            context.renderDepthCompareMode = .less
            
            context.render(triangles, projection: PerspectiveProjectMatrix(angle: 5 * .pi / 18, nearZ: 1, farZ: 500), shader: shader)
            
        }
    }

    func testColorSpaceConversionPerformance() {
        
        let sampleA = self.sample
        
        let context = ImageContext<ARGB32ColorPixel>(width: 500, height: 500, colorSpace: sampleA.colorSpace)
        
        context.shouldAntialias = false
        context.resamplingAlgorithm = .none
        
        context.draw(image: sampleA, transform: SDTransform.scale(x: Double(context.width) / Double(sampleA.width), y: Double(context.height) / Double(sampleA.height)))
        
        let sampleB = context.image
        
        self.measure() {
            
            _ = Image<ARGB32ColorPixel>(image: sampleB, colorSpace: ColorSpace.adobeRGB)
        }
    }
    
    func testResamplingNonePerformance() {
        
        let sample = self.sample
        
        let context = ImageContext<ARGB32ColorPixel>(width: 500, height: 500, colorSpace: sample.colorSpace)
        
        context.shouldAntialias = false
        context.resamplingAlgorithm = .none
        
        self.measure() {
            
            context.draw(image: sample, transform: SDTransform.scale(x: Double(context.width) / Double(sample.width), y: Double(context.height) / Double(sample.height)))
        }
    }
    
    func testResamplingLinearPerformance() {
        
        let sample = self.sample
        
        let context = ImageContext<ARGB32ColorPixel>(width: 500, height: 500, colorSpace: sample.colorSpace)
        
        context.shouldAntialias = false
        context.resamplingAlgorithm = .linear
        
        self.measure() {
            
            context.draw(image: sample, transform: SDTransform.scale(x: Double(context.width) / Double(sample.width), y: Double(context.height) / Double(sample.height)))
        }
    }
    
    func testResamplingCosinePerformance() {
        
        let sample = self.sample
        
        let context = ImageContext<ARGB32ColorPixel>(width: 500, height: 500, colorSpace: sample.colorSpace)
        
        context.shouldAntialias = false
        context.resamplingAlgorithm = .cosine
        
        self.measure() {
            
            context.draw(image: sample, transform: SDTransform.scale(x: Double(context.width) / Double(sample.width), y: Double(context.height) / Double(sample.height)))
        }
    }
    
    func testResamplingCubicPerformance() {
        
        let sample = self.sample
        
        let context = ImageContext<ARGB32ColorPixel>(width: 500, height: 500, colorSpace: sample.colorSpace)
        
        context.shouldAntialias = false
        context.resamplingAlgorithm = .cubic
        
        self.measure() {
            
            context.draw(image: sample, transform: SDTransform.scale(x: Double(context.width) / Double(sample.width), y: Double(context.height) / Double(sample.height)))
        }
    }
    
    func testResamplingHermitePerformance() {
        
        let sample = self.sample
        
        let context = ImageContext<ARGB32ColorPixel>(width: 500, height: 500, colorSpace: sample.colorSpace)
        
        context.shouldAntialias = false
        context.resamplingAlgorithm = .hermite(0.5, 0)
        
        self.measure() {
            
            context.draw(image: sample, transform: SDTransform.scale(x: Double(context.width) / Double(sample.width), y: Double(context.height) / Double(sample.height)))
        }
    }
    
    func testResamplingMitchellPerformance() {
        
        let sample = self.sample
        
        let context = ImageContext<ARGB32ColorPixel>(width: 500, height: 500, colorSpace: sample.colorSpace)
        
        context.shouldAntialias = false
        context.resamplingAlgorithm = .mitchell(1/3, 1/3)
        
        self.measure() {
            
            context.draw(image: sample, transform: SDTransform.scale(x: Double(context.width) / Double(sample.width), y: Double(context.height) / Double(sample.height)))
        }
    }
    
    func testResamplingLanczosPerformance() {
        
        let sample = self.sample
        
        let context = ImageContext<ARGB32ColorPixel>(width: 500, height: 500, colorSpace: sample.colorSpace)
        
        context.shouldAntialias = false
        context.resamplingAlgorithm = .lanczos(3)
        
        self.measure() {
            
            context.draw(image: sample, transform: SDTransform.scale(x: Double(context.width) / Double(sample.width), y: Double(context.height) / Double(sample.height)))
        }
    }
    
    func testResamplingNoneAntialiasPerformance() {
        
        let sample = self.sample
        
        let context = ImageContext<ARGB32ColorPixel>(width: 500, height: 500, colorSpace: sample.colorSpace)
        
        context.shouldAntialias = true
        context.resamplingAlgorithm = .none
        
        self.measure() {
            
            context.draw(image: sample, transform: SDTransform.scale(x: Double(context.width) / Double(sample.width), y: Double(context.height) / Double(sample.height)))
        }
    }
    
    func testResamplingLinearAntialiasPerformance() {
        
        let sample = self.sample
        
        let context = ImageContext<ARGB32ColorPixel>(width: 50, height: 50, colorSpace: sample.colorSpace)
        
        context.shouldAntialias = true
        context.resamplingAlgorithm = .linear
        
        self.measure() {
            
            context.draw(image: sample, transform: SDTransform.scale(x: Double(context.width) / Double(sample.width), y: Double(context.height) / Double(sample.height)))
        }
    }
    
    func testResamplingCosineAntialiasPerformance() {
        
        let sample = self.sample
        
        let context = ImageContext<ARGB32ColorPixel>(width: 50, height: 50, colorSpace: sample.colorSpace)
        
        context.shouldAntialias = true
        context.resamplingAlgorithm = .cosine
        
        self.measure() {
            
            context.draw(image: sample, transform: SDTransform.scale(x: Double(context.width) / Double(sample.width), y: Double(context.height) / Double(sample.height)))
        }
    }
    
    func testResamplingCubicAntialiasPerformance() {
        
        let sample = self.sample
        
        let context = ImageContext<ARGB32ColorPixel>(width: 50, height: 50, colorSpace: sample.colorSpace)
        
        context.shouldAntialias = true
        context.resamplingAlgorithm = .cubic
        
        self.measure() {
            
            context.draw(image: sample, transform: SDTransform.scale(x: Double(context.width) / Double(sample.width), y: Double(context.height) / Double(sample.height)))
        }
    }
    
    func testResamplingHermiteAntialiasPerformance() {
        
        let sample = self.sample
        
        let context = ImageContext<ARGB32ColorPixel>(width: 50, height: 50, colorSpace: sample.colorSpace)
        
        context.shouldAntialias = true
        context.resamplingAlgorithm = .hermite(0.5, 0)
        
        self.measure() {
            
            context.draw(image: sample, transform: SDTransform.scale(x: Double(context.width) / Double(sample.width), y: Double(context.height) / Double(sample.height)))
        }
    }
    
    func testResamplingMitchellAntialiasPerformance() {
        
        let sample = self.sample
        
        let context = ImageContext<ARGB32ColorPixel>(width: 50, height: 50, colorSpace: sample.colorSpace)
        
        context.shouldAntialias = true
        context.resamplingAlgorithm = .mitchell(1/3, 1/3)
        
        self.measure() {
            
            context.draw(image: sample, transform: SDTransform.scale(x: Double(context.width) / Double(sample.width), y: Double(context.height) / Double(sample.height)))
        }
    }
    
    func testResamplingLanczosAntialiasPerformance() {
        
        let sample = self.sample
        
        let context = ImageContext<ARGB32ColorPixel>(width: 50, height: 50, colorSpace: sample.colorSpace)
        
        context.shouldAntialias = true
        context.resamplingAlgorithm = .lanczos(3)
        
        self.measure() {
            
            context.draw(image: sample, transform: SDTransform.scale(x: Double(context.width) / Double(sample.width), y: Double(context.height) / Double(sample.height)))
        }
    }
    
}

private struct ColorVertex: ImageContextRenderVertex {
    
    var position: Vector
    
    var color: Float64ColorPixel<RGBColorModel>
    
    static func + (lhs: ColorVertex, rhs: ColorVertex) -> ColorVertex {
        return ColorVertex(position: lhs.position + rhs.position, color: lhs.color + rhs.color)
    }
    
    static func * (lhs: Double, rhs: ColorVertex) -> ColorVertex {
        return ColorVertex(position: lhs * rhs.position, color: lhs * rhs.color)
    }
}

