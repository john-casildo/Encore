//
//  CheckoutHelpersTests.swift
//  EncoreTests
//

import XCTest
@testable import Encore

final class CheckoutHelpersTests: XCTestCase {

    // MARK: - cardBrand

    func testCardBrand_visa() {
        XCTAssertEqual(CheckoutHelpers.cardBrand(from: "4"), "visa")
        XCTAssertEqual(CheckoutHelpers.cardBrand(from: "4111111111111111"), "visa")
        XCTAssertEqual(CheckoutHelpers.cardBrand(from: "4 1111 1111 1111 1111"), "visa")
    }

    func testCardBrand_mastercard() {
        XCTAssertEqual(CheckoutHelpers.cardBrand(from: "5"), "mastercard")
        XCTAssertEqual(CheckoutHelpers.cardBrand(from: "2"), "mastercard")
        XCTAssertEqual(CheckoutHelpers.cardBrand(from: "5555555555554444"), "mastercard")
        XCTAssertEqual(CheckoutHelpers.cardBrand(from: "2221000000000009"), "mastercard")
    }

    func testCardBrand_amex() {
        XCTAssertEqual(CheckoutHelpers.cardBrand(from: "34"), "amex")
        XCTAssertEqual(CheckoutHelpers.cardBrand(from: "37"), "amex")
        XCTAssertEqual(CheckoutHelpers.cardBrand(from: "378282246310005"), "amex")
    }

    func testCardBrand_unknown() {
        XCTAssertEqual(CheckoutHelpers.cardBrand(from: ""), "card")
        XCTAssertEqual(CheckoutHelpers.cardBrand(from: "6"), "card")
        XCTAssertEqual(CheckoutHelpers.cardBrand(from: "123"), "card")
    }

    // MARK: - formatCardNumber

    func testFormatCardNumber_empty() {
        XCTAssertEqual(CheckoutHelpers.formatCardNumber(""), "")
    }

    func testFormatCardNumber_partial() {
        XCTAssertEqual(CheckoutHelpers.formatCardNumber("4111"), "4111")
        XCTAssertEqual(CheckoutHelpers.formatCardNumber("41111111"), "4111 1111")
    }

    func testFormatCardNumber_full() {
        XCTAssertEqual(CheckoutHelpers.formatCardNumber("4111111111111111"), "4111 1111 1111 1111")
    }

    func testFormatCardNumber_stripsNonNumeric() {
        XCTAssertEqual(CheckoutHelpers.formatCardNumber("4111-1111-1111-1111"), "4111 1111 1111 1111")
    }

    func testFormatCardNumber_capsAt16() {
        XCTAssertEqual(CheckoutHelpers.formatCardNumber("41111111111111112222"), "4111 1111 1111 1111")
    }

    // MARK: - formatExpiry

    func testFormatExpiry_empty() {
        XCTAssertEqual(CheckoutHelpers.formatExpiry(""), "")
    }

    func testFormatExpiry_twoDigits() {
        XCTAssertEqual(CheckoutHelpers.formatExpiry("12"), "12")
    }

    func testFormatExpiry_fourDigits() {
        XCTAssertEqual(CheckoutHelpers.formatExpiry("1225"), "12 / 25")
    }

    func testFormatExpiry_stripsNonNumeric() {
        XCTAssertEqual(CheckoutHelpers.formatExpiry("12/25"), "12 / 25")
    }

    func testFormatExpiry_capsAt4() {
        XCTAssertEqual(CheckoutHelpers.formatExpiry("122599"), "12 / 25")
    }
}
