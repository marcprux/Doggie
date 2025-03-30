//
//  XCTestCase+Android.swift
//

#if os(Android)
import XCTest

extension XCTestCase {
    /// XCTestCase.measure on Android is problematic because
    /// the emulator on a virtualized runner can be quite slow
    /// but there is no way to set the standard deviation threshold
    /// for failure, so we override it to simply run the block
    /// and not perform any measurement.
    ///
    /// See: https://github.com/swiftlang/swift-corelibs-xctest/pull/506
    func measure(_ count: Int = 0, _ block: () -> ()) {
        block()
    }
}
#endif

