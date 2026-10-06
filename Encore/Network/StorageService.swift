//
//  StorageService.swift
//  Encore
//

import SwiftUI

// MARK: - Bucket

enum StorageBucket: String {
    case instruments = "instrument-photos"
    case avatars = "avatars"
}

// MARK: - StorageService

final class StorageService {
    static let shared = StorageService()
    private let session: URLSession = .shared

    private init() {}

    var accessToken: String?

    private var baseURL: String { "\(SupabaseConfig.baseURL)/storage/v1/object" }

    private func authHeader() -> String? {
        guard let t = accessToken else { return nil }
        return "Bearer \(t)"
    }

    // MARK: - Upload single

    func upload(bucket: StorageBucket, path: String, data: Data, contentType: String = "image/jpeg") async throws -> String {
        let url = URL(string: "\(baseURL)/\(bucket.rawValue)/\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        if let auth = authHeader() {
            request.setValue(auth, forHTTPHeaderField: "Authorization")
        }
        request.setValue("true", forHTTPHeaderField: "x-upsert")
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        let (dataResp, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw StorageError.invalidResponse
        }
        if http.statusCode < 200 || http.statusCode >= 300 {
            let body = String(data: dataResp, encoding: .utf8) ?? ""
            print("[StorageService] Non-2xx response body: \(body)")
            throw StorageError.http(statusCode: http.statusCode, body: body)
        }
        // Supabase returns the public URL in response or we build it
        let publicURL = "\(SupabaseConfig.baseURL)/storage/v1/object/public/\(bucket.rawValue)/\(path)"
        return publicURL
    }

    // MARK: - Upload multiple (sequential)

    func uploadMultiple(bucket: StorageBucket, pathsAndData: [(path: String, data: Data)], contentType: String = "image/jpeg") async throws -> [String] {
        var urls: [String] = []
        for item in pathsAndData {
            let url = try await upload(bucket: bucket, path: item.path, data: item.data, contentType: contentType)
            urls.append(url)
        }
        return urls
    }

    // MARK: - Delete

    func delete(bucket: StorageBucket, path: String) async throws {
        let url = URL(string: "\(baseURL)/\(bucket.rawValue)/\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        if let auth = authHeader() {
            request.setValue(auth, forHTTPHeaderField: "Authorization")
        }

        let (dataResp, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw StorageError.invalidResponse
        }
        if http.statusCode < 200 || http.statusCode >= 300 {
            let body = String(data: dataResp, encoding: .utf8) ?? ""
            print("[StorageService] Delete non-2xx response body: \(body)")
            throw StorageError.http(statusCode: http.statusCode, body: body)
        }
    }
}

// MARK: - StorageError

enum StorageError: LocalizedError {
    case invalidResponse
    case http(statusCode: Int, body: String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response"
        case .http(let code, let body): return "HTTP \(code): \(body)"
        }
    }
}

// MARK: - Normalize image URL (path vs full URL)

extension StorageService {
    /// Converts a DB value (full URL or storage path) to a loadable public URL.
    static func normalizedImageURL(_ pathOrUrl: String?, bucket: StorageBucket) -> String? {
        guard let raw = pathOrUrl?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return nil }
        if raw.lowercased().hasPrefix("http://") || raw.lowercased().hasPrefix("https://") {
            return raw
        }
        let base = "\(SupabaseConfig.baseURL)/storage/v1/object/public/\(bucket.rawValue)"
        let path = raw.hasPrefix("/") ? String(raw.dropFirst()) : raw
        return "\(base)/\(path)"
    }
}

// MARK: - Image cache

final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    private init() { cache.countLimit = 100 }

    func get(_ key: String) -> UIImage? { cache.object(forKey: key as NSString) }
    func set(_ image: UIImage, for key: String) { cache.setObject(image, forKey: key as NSString) }
}

// MARK: - Authenticated image loader

@MainActor
final class AuthImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var failed = false

    private var loadedURL: String?

    func load(urlString: String) {
        guard urlString != loadedURL else { return }
        loadedURL = urlString
        image = nil
        failed = false

        if let cached = ImageCache.shared.get(urlString) {
            image = cached
            return
        }

        guard let url = URL(string: urlString) else { failed = true; return }

        Task {
            do {
                var request = URLRequest(url: url)
                request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
                if let token = StorageService.shared.accessToken {
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200,
                      let uiImage = UIImage(data: data) else {
                    await MainActor.run { self.failed = true }
                    return
                }
                ImageCache.shared.set(uiImage, for: urlString)
                await MainActor.run { self.image = uiImage }
            } catch {
                await MainActor.run { self.failed = true }
            }
        }
    }
}

// MARK: - Profile avatar (default when no photo)

struct ProfileAvatarView: View {
    let url: String?
    var size: CGFloat = 44

    private var loadableURL: String? {
        StorageService.normalizedImageURL(url, bucket: .avatars)
    }

    var body: some View {
        Group {
            if let u = loadableURL, let imageURL = URL(string: u) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure, .empty:
                        defaultAvatar
                    @unknown default:
                        defaultAvatar
                    }
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                defaultAvatar
            }
        }
        .frame(width: size, height: size)
    }

    private var defaultAvatar: some View {
        Circle()
            .fill(Color(.systemGray5))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.45))
                    .foregroundStyle(Color(.systemGray3))
            }
    }
}

// MARK: - RemoteImage (defined once here per plan)

struct RemoteImage: View {
    let url: String?
    let emojiFallback: String?
    var placeholder: String = "photo"
    /// When URL is a storage path (no http), use this bucket to build public URL. Nil = use url as-is.
    var storageBucket: StorageBucket? = .instruments
    /// Instrument category — drives the Memphis illustration shown when no image is available.
    var category: String? = nil

    private var loadableURL: String? {
        guard let raw = url else { return nil }
        if let bucket = storageBucket {
            return StorageService.normalizedImageURL(raw, bucket: bucket)
        }
        return raw.isEmpty ? nil : raw
    }

    @StateObject private var loader = AuthImageLoader()

    var body: some View {
        Group {
            if let uiImage = loader.image {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if loader.failed {
                emojiOrPlaceholder
            } else if loadableURL != nil {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                emojiOrPlaceholder
            }
        }
        .onAppear {
            if let u = loadableURL { loader.load(urlString: u) }
        }
        .onChange(of: url) { _ in
            if let u = loadableURL { loader.load(urlString: u) }
        }
    }

    private var emojiOrPlaceholder: some View {
        MemphisInstrumentIllustration(category: category)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
