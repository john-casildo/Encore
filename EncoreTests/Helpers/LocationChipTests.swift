//
//  LocationChipTests.swift
//  EncoreTests
//

import XCTest
@testable import Encore

final class LocationChipTests: XCTestCase {

    func testLocationText_cityAndCountry() {
        let country = CountryDialCode.forIso("CR")!
        let result = LocationChipView.locationText(city: "Alajuela", country: country)
        XCTAssertEqual(result, "Alajuela, Costa Rica")
    }

    func testLocationText_cityOnly() {
        let result = LocationChipView.locationText(city: "San José", country: nil)
        XCTAssertEqual(result, "San José")
    }

    func testLocationText_countryOnly() {
        let country = CountryDialCode.forIso("US")!
        let result = LocationChipView.locationText(city: nil, country: country)
        XCTAssertEqual(result, "United States")
    }

    func testLocationText_bothEmpty() {
        let result = LocationChipView.locationText(city: nil, country: nil)
        XCTAssertEqual(result, "")
    }

    func testLocationText_whitespaceCity() {
        let country = CountryDialCode.forIso("CR")!
        let result = LocationChipView.locationText(city: "  Alajuela  ", country: country)
        XCTAssertEqual(result, "Alajuela, Costa Rica")
    }

    func testLocationText_emptyCity_withCountry() {
        let country = CountryDialCode.forIso("CR")!
        let result = LocationChipView.locationText(city: "", country: country)
        XCTAssertEqual(result, "Costa Rica")
    }
}
