//
//  CountryDialCodeTests.swift
//  EncoreTests
//

import XCTest
@testable import Encore

final class CountryDialCodeTests: XCTestCase {

    func testForIso_costaRica() {
        let cr = CountryDialCode.forIso("CR")
        XCTAssertNotNil(cr)
        XCTAssertEqual(cr?.isoCode, "CR")
        XCTAssertEqual(cr?.dialCode, "+506")
    }

    func testForIso_unitedStates() {
        let us = CountryDialCode.forIso("US")
        XCTAssertNotNil(us)
        XCTAssertEqual(us?.isoCode, "US")
        XCTAssertEqual(us?.dialCode, "+1")
    }

    func testForIso_caseInsensitive() {
        let cr = CountryDialCode.forIso("cr")
        XCTAssertNotNil(cr)
        XCTAssertEqual(cr?.isoCode, "CR")
    }

    func testForIso_nil_returnsNil() {
        XCTAssertNil(CountryDialCode.forIso(nil))
    }

    func testForIso_empty_returnsNil() {
        XCTAssertNil(CountryDialCode.forIso(""))
    }

    func testForIso_unknown_returnsNil() {
        XCTAssertNil(CountryDialCode.forIso("XX"))
    }

    func testFromLocale_returnsValidCountry() {
        let result = CountryDialCode.fromLocale()
        XCTAssertNotNil(result)
        XCTAssertFalse(result.isoCode.isEmpty)
        XCTAssertFalse(result.dialCode.isEmpty)
    }

    func testAll_notEmpty() {
        XCTAssertFalse(CountryDialCode.all.isEmpty)
    }
}
