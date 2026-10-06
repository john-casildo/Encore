//
//  AuthManager.swift
//  Encore
//

import Foundation
import SwiftUI

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published private(set) var session: AuthSession?
    @Published private(set) var currentUser: AppUser?
    @Published private(set) var role: UserRole = .renter
    @Published var errorMessage: String?
    /// False only when we restored a session at launch and haven’t finished validating it. Prevents showing main app until we’ve verified the token/profile.
    @Published private(set) var hasFinishedRestoreValidation = false

    private let client = SupabaseClient.shared
    private let tokenKey = "Encore.AccessToken"
    private let refreshKey = "Encore.RefreshToken"
    private let userIdKey = "Encore.UserId"
    /// True only when session was restored from UserDefaults at launch; used so we only sign out on restore validation, not after a fresh sign-in.
    private var needsRestoreValidation = false

    var isAuthenticated: Bool { session != nil }

    /// True when it’s safe to show main app: either no session, or session has been validated (or didn’t need restore validation).
    var shouldShowMainApp: Bool { isAuthenticated && hasFinishedRestoreValidation }

    init() {
        if let token = UserDefaults.standard.string(forKey: tokenKey),
           let refresh = UserDefaults.standard.string(forKey: refreshKey),
           let uid = UserDefaults.standard.string(forKey: userIdKey),
           let uuid = UUID(uuidString: uid) {
            session = AuthSession(accessToken: token, refreshToken: refresh, userId: uuid)
            client.accessToken = token
            StorageService.shared.accessToken = token
            needsRestoreValidation = true
            hasFinishedRestoreValidation = false
        } else {
            session = nil
            hasFinishedRestoreValidation = true
        }
    }

    /// Refetch current user data only (avatar, name, etc.) without changing the active role.
    /// Use this from profile/menu views so switching to host mode isn't reset on re-appear.
    func refreshUser(force: Bool = false) async {
        guard let uid = session?.userId else { return }
        do {
            let select = "id,name,last_name,email,role,city,country_iso,address,avatar_url,phone,bio,is_verified,rating,review_count,created_at,updated_at"
            let query: [URLQueryItem] = [
                URLQueryItem(name: "id", value: "eq.\(uid.uuidString)"),
                URLQueryItem(name: "select", value: select)
            ]
            let users: [AppUser] = try await client.fetch(table: "users", query: query)
            await MainActor.run {
                if let user = users.first, force || user != currentUser {
                    currentUser = user
                    // role is intentionally NOT updated here — preserve whatever the user chose
                }
            }
        } catch {
            print("[AuthManager] refreshUser failed: \(error)")
        }
    }

    /// Call once the app UI is up (e.g. from RootView). Validates *restored* session only; tries token refresh before signing out.
    func validateSessionIfNeeded() async {
        guard session != nil, needsRestoreValidation else {
            hasFinishedRestoreValidation = true
            return
        }
        await loadUserAndRole()
        if session != nil && currentUser == nil {
            // Profile load failed — try refreshing the token first
            let refreshed = await refreshTokens()
            if refreshed {
                await loadUserAndRole()
            }
            if currentUser == nil {
                signOut()
            }
        }
        needsRestoreValidation = false
        hasFinishedRestoreValidation = true
    }

    /// Exchanges the stored refresh token for a new access token.
    /// Returns true if successful and session was updated.
    @discardableResult
    func refreshTokens() async -> Bool {
        guard let refreshToken = session?.refreshToken, !refreshToken.isEmpty else { return false }
        let url = URL(string: "\(SupabaseConfig.authURL)/token?grant_type=refresh_token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["refresh_token": refreshToken])
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return false }
            let authResp = try JSONDecoder().decode(SupabaseAuthResponse.self, from: data)
            await saveSession(authResp)
            return true
        } catch {
            print("[AuthManager] refreshTokens failed: \(error)")
            return false
        }
    }

    // MARK: - Sign in

    func signIn(email: String, password: String) async {
        errorMessage = nil
        let url = URL(string: "\(SupabaseConfig.authURL)/token?grant_type=password")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["email": email, "password": password])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw AuthError.invalidResponse }
            if http.statusCode != 200 {
                let body = String(data: data, encoding: .utf8) ?? ""
                print("[AuthManager] SignIn HTTP \(http.statusCode): \(body)")
                await setError(from: data)
                return
            }
            let authResp = try JSONDecoder().decode(SupabaseAuthResponse.self, from: data)
            await saveSession(authResp)
            await loadUserAndRole()
        } catch {
            let message = error.localizedDescription
            await MainActor.run { errorMessage = message }
        }
    }

    // MARK: - Sign up

    func signUp(
        email: String,
        password: String,
        role: UserRole,
        name: String? = nil,
        lastName: String? = nil,
        phone: String? = nil,
        address: String? = nil,
        city: String? = nil
    ) async {
        errorMessage = nil
        let url = URL(string: "\(SupabaseConfig.authURL)/signup")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["email": email, "password": password])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw AuthError.invalidResponse }
            if http.statusCode != 200 {
                let body = String(data: data, encoding: .utf8) ?? ""
                print("[AuthManager] SignUp HTTP \(http.statusCode): \(body)")
                await setError(from: data)
                return
            }
            let authResp = try JSONDecoder().decode(SupabaseAuthResponse.self, from: data)
            await saveSession(authResp)
            await upsertProfile(
                role: role,
                email: authResp.user.email ?? email,
                name: name,
                lastName: lastName,
                phone: phone,
                address: address,
                city: city
            )
            await loadUserAndRole()
        } catch {
            let message = error.localizedDescription
            await MainActor.run { errorMessage = message }
        }
    }

    // MARK: - Load user and role

    private func loadUserAndRole() async {
        guard let uid = session?.userId else {
            await MainActor.run { currentUser = nil; role = .renter }
            return
        }
        do {
            let select = "id,name,last_name,email,role,city,country_iso,address,avatar_url,phone,bio,is_verified,rating,review_count,created_at,updated_at"
            let query: [URLQueryItem] = [
                URLQueryItem(name: "id", value: "eq.\(uid.uuidString)"),
                URLQueryItem(name: "select", value: select)
            ]
            let users: [AppUser] = try await client.fetch(table: "users", query: query)
            await MainActor.run {
                if let user = users.first {
                    currentUser = user
                    role = user.role  // restore last-used role from DB
                } else {
                    currentUser = nil
                    role = .renter
                    // No signOut here: after fresh sign-in the profile may not exist yet; caller will setRole/upsert
                }
            }
        } catch {
            print("[AuthManager] loadUserAndRole failed: \(error)")
            await MainActor.run { currentUser = nil }
        }
    }

    // MARK: - Upsert profile

    private func upsertProfile(
        role: UserRole,
        email: String? = nil,
        name: String? = nil,
        lastName: String? = nil,
        phone: String? = nil,
        address: String? = nil,
        city: String? = nil
    ) async {
        guard let uid = session?.userId else { return }
        let userEmail = email ?? session?.userEmail ?? ""
        var body: [String: Any] = [
            "id": uid.uuidString,
            "email": userEmail,
            "role": role.rawValue
        ]
        if let v = name,     !v.isEmpty { body["name"]      = v }
        if let v = lastName, !v.isEmpty { body["last_name"] = v }
        if let v = phone,    !v.isEmpty { body["phone"]     = v }
        if let v = address,  !v.isEmpty { body["address"]   = v }
        if let v = city,     !v.isEmpty { body["city"]      = v }

        do {
            _ = try await client.insert(table: "users", body: body)
        } catch {
            // Might be unique violation if already exists; try update with provided fields
            var updateBody: [String: Any] = ["role": role.rawValue]
            if let v = name,     !v.isEmpty { updateBody["name"]      = v }
            if let v = lastName, !v.isEmpty { updateBody["last_name"] = v }
            if let v = phone,    !v.isEmpty { updateBody["phone"]     = v }
            if let v = address,  !v.isEmpty { updateBody["address"]   = v }
            if let v = city,     !v.isEmpty { updateBody["city"]      = v }
            do {
                try await client.update(table: "users", id: uid, body: updateBody)
            } catch {
                print("[AuthManager] upsertProfile failed: \(error)")
            }
        }
    }

    /// Call after sign-in when we already have a session but need to set role (e.g. Switch to Host / Renter).
    func setRole(_ newRole: UserRole) async {
        guard let uid = session?.userId else { return }
        errorMessage = nil
        do {
            try await client.update(table: "users", id: uid, body: ["role": newRole.rawValue])
            await loadUserAndRole()
            await MainActor.run { role = newRole }  // override after load so we always land on the chosen role
        } catch {
            print("[AuthManager] setRole failed: \(error)")
            await MainActor.run {
                errorMessage = "Could not switch mode. Run Supabase_HostMode_Ensure.sql in Supabase if you haven’t."
            }
        }
    }

    /// Ensures a user row exists (insert or update), then loads user. Use after sign-in when currentUser is nil.
    func ensureProfile(role: UserRole = .renter) async {
        await upsertProfile(role: role, email: nil)
        await loadUserAndRole()
    }

    /// Changes the authenticated user's email via Supabase Auth. Supabase sends a
    /// confirmation link to the new address — the change is not active until confirmed.
    func updateEmail(_ newEmail: String) async throws {
        let url = URL(string: "\(SupabaseConfig.authURL)/user")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = session?.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try? JSONEncoder().encode(["email": newEmail])
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode >= 300 {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("[AuthManager] updateEmail HTTP \(http.statusCode): \(body)")
            throw SupabaseError.http(statusCode: http.statusCode, body: body)
        }
    }

    /// Update current user profile fields. Pass only keys you want to update (name, last_name, city, phone, bio, avatar_url). Refetches full user from DB so profile always shows latest.
    func updateProfile(_ body: [String: Any]) async throws {
        guard let uid = session?.userId else { return }
        try await client.update(table: "users", id: uid, body: body)
        // Use refreshUser (not loadUserAndRole) so the active role is never overwritten
        // and currentUser is never set to nil on a transient fetch failure.
        await refreshUser(force: true)
    }

    // MARK: - Password reset

    /// Sends a password recovery email via Supabase Auth (POST /recover). Sets errorMessage on failure.
    func requestPasswordReset(email: String) async {
        errorMessage = nil
        let url = URL(string: "\(SupabaseConfig.authURL)/recover")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["email": email])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw AuthError.invalidResponse }
            if http.statusCode != 200 {
                let body = String(data: data, encoding: .utf8) ?? ""
                print("[AuthManager] Recover HTTP \(http.statusCode): \(body)")
                await setError(from: data)
                return
            }
            await MainActor.run { errorMessage = nil }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }

    // MARK: - Sign out

    func signOut() {
        session = nil
        currentUser = nil
        role = .renter
        client.accessToken = nil
        StorageService.shared.accessToken = nil
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: refreshKey)
        UserDefaults.standard.removeObject(forKey: userIdKey)
        ListingsCache.invalidate()
    }

    // MARK: - Helpers

    private func saveSession(_ auth: SupabaseAuthResponse) async {
        let s = AuthSession(
            accessToken: auth.accessToken,
            refreshToken: auth.refreshToken ?? "",
            userId: auth.user.id,
            userEmail: auth.user.email
        )
        await MainActor.run {
            session = s
            needsRestoreValidation = false
            client.accessToken = auth.accessToken
            StorageService.shared.accessToken = auth.accessToken
            UserDefaults.standard.set(auth.accessToken, forKey: tokenKey)
            UserDefaults.standard.set(auth.refreshToken, forKey: refreshKey)
            UserDefaults.standard.set(auth.user.id.uuidString, forKey: userIdKey)
        }
    }

    private func setError(from data: Data) async {
        struct ErrResp: Decodable {
            let msg: String?
            let error_description: String?
            enum CodingKeys: String, CodingKey {
                case msg
                case error_description = "error_description"
            }
        }
        let message: String
        if let e = try? JSONDecoder().decode(ErrResp.self, from: data) {
            message = e.msg ?? e.error_description ?? "Auth failed"
        } else {
            message = String(data: data, encoding: .utf8) ?? "Auth failed"
        }
        await MainActor.run { errorMessage = message }
    }
}

// MARK: - Auth error

enum AuthError: LocalizedError {
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response"
        }
    }
}

// MARK: - Auth session

struct AuthSession {
    let accessToken: String
    let refreshToken: String
    let userId: UUID
    let userEmail: String?

    init(accessToken: String, refreshToken: String, userId: UUID, userEmail: String? = nil) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.userId = userId
        self.userEmail = userEmail
    }
}

// MARK: - Supabase auth response

private struct SupabaseAuthResponse: Decodable {
    let accessToken: String
    let refreshToken: String?
    let user: SupabaseAuthUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

private struct SupabaseAuthUser: Decodable {
    let id: UUID
    let email: String?

    enum CodingKeys: String, CodingKey {
        case id, email
    }
}

