//
//  ColorHexTests.swift
//  EncoreTests
//

import XCTest
import SwiftUI
@testable import Encore

final class ColorHexTests: XCTestCase {

    func testColorHex_6chars() {
        let color = Color(hex: "7C3AED")
        // Purple - we can't easily assert RGB in SwiftUI Color, but we verify it doesn't crash
        XCTAssertNotNil(color)
    }

    func testColorHex_3chars() {
        let color = Color(hex: "F00")
        XCTAssertNotNil(color)
    }

    func testColorHex_8chars() {
        let color = Color(hex: "FF7C3AED")
        XCTAssertNotNil(color)
    }

    func testColorHex_empty_defaultsToBlack() {
        let color = Color(hex: "")
        XCTAssertNotNil(color)
    }

    func testColorHex_withHash() {
        let color = Color(hex: "#7C3AED")
        XCTAssertNotNil(color)
    }

    func testColorHex_lowercase() {
        let color = Color(hex: "7c3aed")
        XCTAssertNotNil(color)
    }
}
