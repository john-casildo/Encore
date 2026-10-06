//
//  SupabaseClientTests.swift
//  EncoreTests
//

import XCTest
@testable import Encore

final class SupabaseClientTests: XCTestCase {

    private var session: URLSession!
    private var client: SupabaseClient!

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: config)
        client = SupabaseClient(session: session)
    }

    override func tearDown() {
        MockURLProtocol.mockResponses = [:]
        MockURLProtocol.lastRequest = nil
        super.tearDown()
    }

    func testFetch_buildsCorrectURL() async throws {
        let table = "instruments"
        let url = URL(string: "\(SupabaseConfig.restURL)/\(table)")!
        let json = "[]"
        MockURLProtocol.mockResponses[url] = (json.data(using: .utf8), HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil))

        let _: [Instrument] = try await client.fetch(table: table)
        XCTAssertNotNil(MockURLProtocol.lastRequest)
        XCTAssertEqual(MockURLProtocol.lastRequest?.url, url)
        XCTAssertEqual(MockURLProtocol.lastRequest?.httpMethod, "GET")
    }

    func testFetch_withQuery() async throws {
        let table = "rentals"
        var comp = URLComponents(string: "\(SupabaseConfig.restURL)/\(table)")!
        comp.queryItems = [URLQueryItem(name: "status", value: "eq.pending")]
        let url = comp.url!
        let json = "[]"
        MockURLProtocol.mockResponses[url] = (json.data(using: .utf8), HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil))

        let _: [Rental] = try await client.fetch(table: table, query: [URLQueryItem(name: "status", value: "eq.pending")])
        XCTAssertNotNil(MockURLProtocol.lastRequest)
        let urlStr = MockURLProtocol.lastRequest?.url?.absoluteString ?? ""
        XCTAssertTrue(urlStr.contains("rentals"), "URL should contain table name")
        XCTAssertTrue(urlStr.contains("status"), "URL should contain query param")
    }

    func testFetch_httpError_throws() async {
        let table = "instruments"
        let url = URL(string: "\(SupabaseConfig.restURL)/\(table)")!
        MockURLProtocol.mockResponses[url] = ("Error".data(using: .utf8), HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil))

        do {
            let _: [Instrument] = try await client.fetch(table: table)
            XCTFail("Expected throw")
        } catch {
            guard let supabaseError = error as? SupabaseError,
                  case .http(let code, _) = supabaseError else {
                XCTFail("Expected SupabaseError.http, got \(error)")
                return
            }
            XCTAssertEqual(code, 500)
        }
    }
}
