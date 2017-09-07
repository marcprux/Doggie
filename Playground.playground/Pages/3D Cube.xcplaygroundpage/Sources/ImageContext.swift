
import Cocoa
import Doggie

struct Vertex : ImageContextRenderVertex {
    
    var position: Vector
    
    var color: ColorPixel<RGBColorModel>
    
    static func + (lhs: Vertex, rhs: Vertex) -> Vertex {
        return Vertex(position: lhs.position + rhs.position, color: lhs.color + rhs.color)
    }
    
    static func * (lhs: Double, rhs: Vertex) -> Vertex {
        return Vertex(position: lhs * rhs.position, color: lhs * rhs.color)
    }
}

public func sampleImage(width: Int, height: Int) -> Image<ARGB32ColorPixel> {
    
    let context = ImageContext<ARGB32ColorPixel>(width: width, height: height, colorSpace: ColorSpace.sRGB)
    
    let matrix = Matrix.rotateY(degreesToRad(30)) * Matrix.rotateX(degreesToRad(-30)) * Matrix.translate(x: 0, y: 0, z: 100)
    
    let c0 = ColorPixel(red: 0, green: 0, blue: 0, opacity: 1)
    let c1 = ColorPixel(red: 1, green: 0, blue: 0, opacity: 1)
    let c2 = ColorPixel(red: 0, green: 1, blue: 0, opacity: 1)
    let c3 = ColorPixel(red: 0, green: 0, blue: 1, opacity: 1)
    let c4 = ColorPixel(red: 1, green: 1, blue: 0, opacity: 1)
    let c5 = ColorPixel(red: 1, green: 0, blue: 1, opacity: 1)
    let c6 = ColorPixel(red: 0, green: 1, blue: 1, opacity: 1)
    let c7 = ColorPixel(red: 1, green: 1, blue: 1, opacity: 1)
    
    let v0 = Vertex(position: Vector(x: 25, y: 25, z: -25) * matrix, color: c0)
    let v1 = Vertex(position: Vector(x: -25, y: 25, z: -25) * matrix, color: c1)
    let v2 = Vertex(position: Vector(x: -25, y: -25, z: -25) * matrix, color: c5)
    let v3 = Vertex(position: Vector(x: 25, y: -25, z: -25) * matrix, color: c3)
    let v4 = Vertex(position: Vector(x: 25, y: 25, z: 25) * matrix, color: c2)
    let v5 = Vertex(position: Vector(x: -25, y: 25, z: 25) * matrix, color: c4)
    let v6 = Vertex(position: Vector(x: -25, y: -25, z: 25) * matrix, color: c7)
    let v7 = Vertex(position: Vector(x: 25, y: -25, z: 25) * matrix, color: c6)
    
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
    
    func shader(vertex: Vertex) -> ColorPixel<RGBColorModel> {
        
        return vertex.color
    }
    
    let triangles = [t0, t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11]
    
    context.renderCullingMode = .back
    context.renderDepthCompareMode = .less
    
    context.render(triangles, projection: PerspectiveProjectMatrix(angle: degreesToRad(50), nearZ: 1, farZ: 500), shader: shader)
    
    return context.image
}


