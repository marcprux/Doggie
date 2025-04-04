//
//  SerialRunLoop.swift
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

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public class SerialRunLoop: @unchecked Sendable {
    
    private var queue: AsyncStream<@Sendable () async -> Void>.Continuation!
    
    private let in_runloop = TaskLocal(wrappedValue: false)
    
    public init(priority: TaskPriority? = nil) {
        
        let stream = AsyncStream { self.queue = $0 }
        let in_runloop = self.in_runloop
        
        Task.detached(priority: priority) {
            
            await in_runloop.withValue(true) {
                
                for await task in stream {
                    await task()
                }
            }
        }
    }
    
    deinit {
        self.queue.finish()
    }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension SerialRunLoop {
    
    public var inRunloop: Bool {
        return in_runloop.get()
    }
}

@rethrows protocol _Rethrow {
    associatedtype Success
    func get() throws -> Success
}

extension _Rethrow {
    func _rethrowGet() rethrows -> Success { try get() }
}

extension Result: _Rethrow { }

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension SerialRunLoop {
    
    public func perform<T: Sendable>(_ task: @Sendable @escaping () async throws -> T) async rethrows -> T {
        
        let result: Result<T, Error> = await withUnsafeContinuation { continuation in
            
            self.queue.yield {
                
                do {
                    
                    try await continuation.resume(returning: .success(task()))
                    
                } catch {
                    
                    continuation.resume(returning: .failure(error))
                }
            }
        }
        
        return try result._rethrowGet()
    }
}
