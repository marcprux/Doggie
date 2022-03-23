//
//  AsyncSequence.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2022 Susan Cheng. All rights reserved.
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

#if compiler(>=5.5.2) && canImport(_Concurrency)

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension AsyncSequence {
    
    @inlinable
    public func collect() async rethrows -> [Element] {
        return try await self.reduce(into: []) { $0.append($1) }
    }
}

@frozen
@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public struct _AsyncSequenceBox<S: Sequence>: AsyncSequence {
    
    public typealias Element = S.Element
    
    @usableFromInline
    let base: S
    
    @inlinable
    init(_ base: S) {
        self.base = base
    }
    
    public func makeAsyncIterator() -> AsyncIterator {
        return AsyncIterator(base)
    }
    
    @frozen
    public struct AsyncIterator: AsyncIteratorProtocol {
        
        @usableFromInline
        var base: S.Iterator
        
        @inlinable
        init(_ base: S) {
            self.base = base.makeIterator()
        }
        
        public mutating func next() async -> S.Element? {
            return self.base.next()
        }
    }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension Sequence {
    
    @inlinable
    public func map<ElementOfResult>(_ transform: @escaping (Element) async -> ElementOfResult) -> AsyncMapSequence<_AsyncSequenceBox<Self>, ElementOfResult> {
        return _AsyncSequenceBox(self).map(transform)
    }
    
    @inlinable
    public func map<ElementOfResult>(_ transform: @escaping (Element) async throws -> ElementOfResult) -> AsyncThrowingMapSequence<_AsyncSequenceBox<Self>, ElementOfResult> {
        return _AsyncSequenceBox(self).map(transform)
    }
    
    @inlinable
    public func filter(_ isIncluded: @escaping (Element) async -> Bool) -> AsyncFilterSequence<_AsyncSequenceBox<Self>> {
        return _AsyncSequenceBox(self).filter(isIncluded)
    }
    
    @inlinable
    public func filter(_ isIncluded: @escaping (Element) async throws -> Bool) -> AsyncThrowingFilterSequence<_AsyncSequenceBox<Self>> {
        return _AsyncSequenceBox(self).filter(isIncluded)
    }
    
    @inlinable
    public func flatMap<SegmentOfResult: AsyncSequence>(_ transform: @escaping (Element) async -> SegmentOfResult) -> AsyncFlatMapSequence<_AsyncSequenceBox<Self>, SegmentOfResult> {
        return _AsyncSequenceBox(self).flatMap(transform)
    }
    
    @inlinable
    public func flatMap<SegmentOfResult: AsyncSequence>(_ transform: @escaping (Element) async throws -> SegmentOfResult) -> AsyncThrowingFlatMapSequence<_AsyncSequenceBox<Self>, SegmentOfResult> {
        return _AsyncSequenceBox(self).flatMap(transform)
    }
    
    @inlinable
    public func compactMap<ElementOfResult>(_ transform: @escaping (Element) async -> ElementOfResult?) -> AsyncCompactMapSequence<_AsyncSequenceBox<Self>, ElementOfResult> {
        return _AsyncSequenceBox(self).compactMap(transform)
    }
    
    @inlinable
    public func compactMap<ElementOfResult>(_ transform: @escaping (Element) async throws -> ElementOfResult?) -> AsyncThrowingCompactMapSequence<_AsyncSequenceBox<Self>, ElementOfResult> {
        return _AsyncSequenceBox(self).compactMap(transform)
    }
    
    @inlinable
    public func drop(while predicate: @escaping (Element) async -> Bool) -> AsyncDropWhileSequence<_AsyncSequenceBox<Self>> {
        return _AsyncSequenceBox(self).drop(while: predicate)
    }
    
    @inlinable
    public func drop(while predicate: @escaping (Element) async throws -> Bool) -> AsyncThrowingDropWhileSequence<_AsyncSequenceBox<Self>> {
        return _AsyncSequenceBox(self).drop(while: predicate)
    }
    
    @inlinable
    public func prefix(while predicate: @escaping (Element) async -> Bool) -> AsyncPrefixWhileSequence<_AsyncSequenceBox<Self>> {
        return _AsyncSequenceBox(self).prefix(while: predicate)
    }
    
    @inlinable
    public func prefix(while predicate: @escaping (Element) async throws -> Bool) -> AsyncThrowingPrefixWhileSequence<_AsyncSequenceBox<Self>> {
        return try! _AsyncSequenceBox(self).prefix(while: predicate)
    }
    
    @inlinable
    public func reduce<Result>(_ initialResult: Result, _ nextPartialResult: (_ partialResult: Result, Element) async throws -> Result) async rethrows -> Result {
        return try await _AsyncSequenceBox(self).reduce(initialResult, nextPartialResult)
    }
    
    @inlinable
    public func reduce<Result>(into initialResult: Result, _ updateAccumulatingResult: (_ partialResult: inout Result, Element) async throws -> Void) async rethrows -> Result {
        return try await _AsyncSequenceBox(self).reduce(into: initialResult, updateAccumulatingResult)
    }
    
    @inlinable
    public func contains(where predicate: (Element) async throws -> Bool) async rethrows -> Bool {
        return try await _AsyncSequenceBox(self).contains(where: predicate)
    }
    
    @inlinable
    public func allSatisfy(_ predicate: (Element) async throws -> Bool) async rethrows -> Bool {
        return try await _AsyncSequenceBox(self).allSatisfy(predicate)
    }
    
    @inlinable
    public func first(where predicate: (Element) async throws -> Bool) async rethrows -> Element? {
        return try await _AsyncSequenceBox(self).first(where: predicate)
    }
    
    @inlinable
    @warn_unqualified_access
    public func min(by areInIncreasingOrder: (Element, Element) async throws -> Bool) async rethrows -> Element? {
        return try await _AsyncSequenceBox(self).min(by: areInIncreasingOrder)
    }
    
    @inlinable
    @warn_unqualified_access
    public func max(by areInIncreasingOrder: (Element, Element) async throws -> Bool) async rethrows -> Element? {
        return try await _AsyncSequenceBox(self).max(by: areInIncreasingOrder)
    }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension Sequence {
    
    @inlinable
    public func parallelEach(
        _ callback: @escaping (Element) async -> Void
    ) async {
        
        await withTaskGroup(of: Void.self) { group in
            
            for item in self {
                group.addTask { await callback(item) }
            }
            
            await group.waitForAll()
        }
    }
    
    @inlinable
    public func parallelEach(
        _ callback: @escaping (Element) async throws -> Void
    ) async throws {
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            
            for item in self {
                group.addTask { try await callback(item) }
            }
            
            try await group.waitForAll()
        }
    }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension Sequence {
    
    @inlinable
    public func parallelMap<ElementOfResult>(
        _ transform: @escaping (Element) async -> ElementOfResult
    ) async -> [ElementOfResult] {
        
        let group: [Task<ElementOfResult, Never>] = self.map { element in Task { await transform(element) } }
        
        var result: [ElementOfResult] = []
        result.reserveCapacity(underestimatedCount)
        
        for task in group {
            await result.append(task.value)
        }
        
        return result
    }
    
    @inlinable
    public func parallelMap<ElementOfResult>(
        _ transform: @escaping (Element) async throws -> ElementOfResult
    ) async throws -> [ElementOfResult] {
        
        let group: [Task<ElementOfResult, Error>] = self.map { element in Task { try await transform(element) } }
        
        var result: [ElementOfResult] = []
        result.reserveCapacity(underestimatedCount)
        
        for task in group {
            try await result.append(task.value)
        }
        
        return result
    }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension Sequence {
    
    @inlinable
    public func parallelCompactMap<ElementOfResult>(
        _ transform: @escaping (Element) async -> ElementOfResult?
    ) async -> [ElementOfResult] {
        
        let group: [Task<ElementOfResult?, Never>] = self.map { element in Task { await transform(element) } }
        
        var result: [ElementOfResult] = []
        result.reserveCapacity(underestimatedCount)
        
        for task in group {
            if let value = await task.value {
                result.append(value)
            }
        }
        
        return result
    }
    
    @inlinable
    public func parallelCompactMap<ElementOfResult>(
        _ transform: @escaping (Element) async throws -> ElementOfResult?
    ) async throws -> [ElementOfResult] {
        
        let group: [Task<ElementOfResult?, Error>] = self.map { element in Task { try await transform(element) } }
        
        var result: [ElementOfResult] = []
        result.reserveCapacity(underestimatedCount)
        
        for task in group {
            if let value = try await task.value {
                result.append(value)
            }
        }
        
        return result
    }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension Sequence {
    
    @inlinable
    public func reductions<Result>(
        _ initial: Result,
        _ transform: (Result, Element) async throws -> Result
    ) async rethrows -> [Result] {
        try await reductions(into: initial) { result, element in
            result = try await transform(result, element)
        }
    }
    
    @inlinable
    public func reductions<Result>(
        into initial: Result,
        _ transform: (inout Result, Element) async throws -> Void
    ) async rethrows -> [Result] {
        
        var result: [Result] = [initial]
        result.reserveCapacity(underestimatedCount + 1)
        
        var initial = initial
        for element in self {
            try await transform(&initial, element)
            result.append(initial)
        }
        
        return result
    }
}

#endif
