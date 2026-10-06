//
//  AppUserTests.swift
//  EncoreTests
//

import XCTest
@testable import Encore

final class AppUserTests: XCTestCase {

    func testDisplayName_firstAndLastName() throws {
        let user = try makeUser(name: "John", lastName: "Doe", email: "john@test.com")
        XCTAssertEqual(user.displayName, "John Doe")
    }

    func testDisplayName_nameOnly() throws {
        let user = try makeUser(name: "Jane", lastName: nil, email: "jane@test.com")
        XCTAssertEqual(user.displayName, "Jane")
    }

    func testDisplayName_lastNameOnly() throws {
        let user = try makeUser(name: nil, lastName: "Smith", email: "smith@test.com")
        XCTAssertEqual(user.displayName, "Smith")
    }

    func testDisplayName_emailFallback() throws {
        let user = try makeUser(name: nil, lastName: nil, email: "fallback@test.com")
        XCTAssertEqual(user.displayName, "fallback@test.com")
    }

    func testDisplayName_allEmpty_returnsEmDash() throws {
        let user = try makeUser(name: nil, lastName: nil, email: nil)
        XCTAssertEqual(user.displayName, "—")
    }

    func testDisplayName_whitespaceOnlyName_usesEmail() throws {
        let user = try makeUser(name: "   ", lastName: "  ", email: "real@test.com")
        XCTAssertEqual(user.displayName, "real@test.com")
    }

    func testDisplayName_trimmedWhitespace() throws {
        let user = try makeUser(name: "  John  ", lastName: "  Doe  ", email: nil)
        XCTAssertEqual(user.displayName, "John Doe")
    }

    private func makeUser(name: String?, lastName: String?, email: String?) throws -> AppUser {
        let json = """
        {
            "id": "\(UUID().uuidString)",
            "name": \(name.map { "\"\($0)\"" } ?? "null"),
            "last_name": \(lastName.map { "\"\($0)\"" } ?? "null"),
            "email": \(email.map { "\"\($0)\"" } ?? "null"),
            "role": "renter"
        }
        """
        let data = json.data(using: .utf8)!
        return try JSONDecoder.supabase.decode(AppUser.self, from: data)
    }
}
