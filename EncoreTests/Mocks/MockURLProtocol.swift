//
//  MockURLProtocol.swift
//  EncoreTests
//

import Foundation

/// URLProtocol that captures requests and returns configurable responses.
final class MockURLProtocol: URLProtocol {
    static var mockResponses: [URL: (Data?, HTTPURLResponse?)] = [:]
    static var lastRequest: URLRequest?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lastRequest = request
        guard let url = request.url,
              let (data, response) = Self.mockResponses[url] else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "MockURLProtocol", code: -1, userInfo: [NSLocalizedDescriptionKey: "No mock for \(request.url?.absoluteString ?? "")"]))
            return
        }
        if let response = response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        if let data = data {
            client?.urlProtocol(self, didLoad: data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
