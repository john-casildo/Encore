//
//  SupabaseClient.swift
//  Encore
//

import Foundation

// MARK: - Config

enum SupabaseConfig {
    /// Set in Config/Secrets.xcconfig (see Config/Secrets.example.xcconfig), injected via Info.plist.
    static var baseURL: String { "https://\(value(for: "SupabaseHost"))" }
    static var anonKey: String { value(for: "SupabaseAnonKey") }
    static var restURL: String { "\(baseURL)/rest/v1" }
    static var authURL: String { "\(baseURL)/auth/v1" }

    private static func value(for key: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String, !value.isEmpty else {
            fatalError("Missing \(key). Copy Config/Secrets.example.xcconfig to Config/Secrets.xcconfig and add your Supabase project.")
        }
        return value
    }
}

// MARK: - SupabaseClient

final class SupabaseClient {
    static let shared = SupabaseClient()
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Caller must set token (e.g. from AuthManager). If nil, we log a warning and still send the request.
    var accessToken: String?

    // MARK: - Headers

    private func headers(includeAuth: Bool = true) -> [String: String] {
        var h: [String: String] = [
            "apikey": SupabaseConfig.anonKey,
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Prefer": "return=representation"
        ]
        if includeAuth, let token = accessToken {
            h["Authorization"] = "Bearer \(token)"
        } else if includeAuth && accessToken == nil {
            print("[SupabaseClient] ⚠️ WARNING: accessToken is nil before authenticated request.")
        }
        return h
    }

    // MARK: - Fetch (GET)

    /// Fetch with a raw query string (e.g. "id=eq.uuid") so PostgREST gets the operator and value unmodified.
    func fetchWithQueryString<T: Decodable>(
        table: String,
        queryString: String,
        decoder: JSONDecoder = .supabase
    ) async throws -> [T] {
        let urlString = "\(SupabaseConfig.restURL)/\(table)?\(queryString)"
        guard let url = URL(string: urlString) else { throw SupabaseError.badURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        headers().forEach { request.setValue($1, forHTTPHeaderField: $0) }
        let (data, response) = try await perform(request)
        try assertOK(data: data, response: response, context: "GET \(table)")
        return try decoder.decode([T].self, from: data)
    }

    func fetch<T: Decodable>(
        table: String,
        query: [URLQueryItem] = [],
        decoder: JSONDecoder = .supabase
    ) async throws -> [T] {
        var components = URLComponents(string: "\(SupabaseConfig.restURL)/\(table)")!
        if !query.isEmpty {
            components.queryItems = query
        }
        guard let url = components.url else { throw SupabaseError.badURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        headers().forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let (data, response) = try await perform(request)
        try assertOK(data: data, response: response, context: "GET \(table)")
        return try decoder.decode([T].self, from: data)
    }

    // MARK: - Insert (Encodable)

    func insert<T: Encodable>(
        table: String,
        body: T,
        encoder: JSONEncoder = .supabase
    ) async throws -> Data {
        let url = URL(string: "\(SupabaseConfig.restURL)/\(table)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        headers().forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await perform(request)
        try assertOK(data: data, response: response, context: "POST \(table)")
        return data
    }

    // MARK: - Insert ([String: Any])

    func insert(table: String, body: [String: Any]) async throws -> Data {
        let url = URL(string: "\(SupabaseConfig.restURL)/\(table)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        headers().forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await perform(request)
        try assertOK(data: data, response: response, context: "POST \(table)")
        return data
    }

    // MARK: - Update

    func update<T: Encodable>(
        table: String,
        id: UUID,
        body: T,
        encoder: JSONEncoder = .supabase
    ) async throws {
        let url = URL(string: "\(SupabaseConfig.restURL)/\(table)?id=eq.\(id.uuidString)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        headers().forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await perform(request)
        try assertOK(data: data, response: response, context: "PATCH \(table)")
    }

    func update(table: String, id: UUID, body: [String: Any]) async throws {
        let url = URL(string: "\(SupabaseConfig.restURL)/\(table)?id=eq.\(id.uuidString)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        headers().forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await perform(request)
        try assertOK(data: data, response: response, context: "PATCH \(table)")
    }

    /// PATCH and decode returned row(s). Use when you need the updated row (e.g. profile save).
    func updateAndReturn<T: Decodable>(table: String, id: UUID, body: [String: Any], decoder: JSONDecoder = .supabase) async throws -> [T] {
        let url = URL(string: "\(SupabaseConfig.restURL)/\(table)?id=eq.\(id.uuidString)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        headers().forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await perform(request)
        try assertOK(data: data, response: response, context: "PATCH \(table)")
        return try decoder.decode([T].self, from: data)
    }

    // MARK: - Delete

    func delete(table: String, id: UUID) async throws {
        let url = URL(string: "\(SupabaseConfig.restURL)/\(table)?id=eq.\(id.uuidString)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        headers().forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let (data, response) = try await perform(request)
        try assertOK(data: data, response: response, context: "DELETE \(table)")
    }

    // MARK: - Request execution with auto-refresh

    /// Executes a request. If a 401 is returned, refreshes the token once and retries.
    private func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 401 else {
            return (data, response)
        }
        let refreshed = await AuthManager.shared.refreshTokens()
        guard refreshed, let newToken = accessToken else {
            return (data, response)
        }
        var retryReq = request
        retryReq.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
        return try await session.data(for: retryReq)
    }

    // MARK: - Error handling

    private func assertOK(data: Data, response: URLResponse, context: String) throws {
        guard let http = response as? HTTPURLResponse else { return }
        if http.statusCode >= 200 && http.statusCode < 300 { return }
        let body = String(data: data, encoding: .utf8) ?? ""
        print("[SupabaseClient] HTTP \(http.statusCode) \(context)\nBody: \(body)")
        throw SupabaseError.http(statusCode: http.statusCode, body: body)
    }
}

// MARK: - SupabaseError

enum SupabaseError: LocalizedError {
    case badURL
    case http(statusCode: Int, body: String)

    var errorDescription: String? {
        switch self {
        case .badURL: return "Invalid URL"
        case .http(let code, let body): return "HTTP \(code): \(body)"
        }
    }
}

// MARK: - JSONEncoder / JSONDecoder (snake_case, dates)

extension JSONEncoder {
    static let supabase: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
}

extension JSONDecoder {
    static let supabase: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let c = try decoder.singleValueContainer()
            let s = try c.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: s) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: s) { return date }
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            f.locale = Locale(identifier: "en_US_POSIX")
            f.timeZone = TimeZone(identifier: "UTC")
            if let date = f.date(from: String(s.prefix(10))) { return date }
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Invalid date: \(s)")
        }
        return d
    }()
}
