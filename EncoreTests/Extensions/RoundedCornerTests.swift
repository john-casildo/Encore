//
//  RoundedCornerTests.swift
//  EncoreTests
//

import XCTest
import SwiftUI
@testable import Encore

final class RoundedCornerTests: XCTestCase {

    func testRoundedCorner_path_producesNonEmptyPath() {
        let shape = RoundedCorner(radius: 10, corners: .allCorners)
        let rect = CGRect(x: 0, y: 0, width: 100, height: 50)
        let path = shape.path(in: rect)
        XCTAssertFalse(path.isEmpty)
    }

    func testRoundedCorner_path_withZeroRect() {
        let shape = RoundedCorner(radius: 5, corners: .topLeft)
        let path = shape.path(in: .zero)
        XCTAssertNotNil(path)
    }
}
