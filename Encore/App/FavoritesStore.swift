//
//  FavoritesStore.swift
//  Encore
//

import Foundation
import SwiftUI

@MainActor
final class FavoritesStore: ObservableObject {
    static let shared = FavoritesStore()

    @Published private(set) var favoriteInstrumentIds: Set<UUID> = []

    /// IDs we've optimistically added; insert may still be in flight. Preserved when load() overwrites.
    private var pendingAdds: Set<UUID> = []
    /// IDs we've optimistically removed; delete may still be in flight.
    private var pendingRemoves: Set<UUID> = []

    private let client = SupabaseClient.shared
    private let table = "saved_instruments"

    private init() {}

    /// Call when the user might have changed or on first load.
    func load() {
        // Use session.userId so this works even before loadUserAndRole finishes.
        guard let uid = AuthManager.shared.session?.userId else {
            // Don't clear — session may be briefly nil during auth restore; preserve current state
            return
        }
        Task {
            do {
                let list: [Favorite] = try await client.fetch(
                    table: table,
                    query: [URLQueryItem(name: "user_id", value: "eq.\(uid.uuidString)")]
                )
                let serverIds = Set(list.map(\.instrumentId))
                // Merge with optimistic state so load() doesn't overwrite in-flight adds
                favoriteInstrumentIds = serverIds.union(pendingAdds).subtracting(pendingRemoves)
            } catch {
                print("[FavoritesStore] load failed: \(error)")
                favoriteInstrumentIds = pendingAdds.subtracting(pendingRemoves)
            }
        }
    }

    /// Add or remove favorite. Optimistic UI — updates set immediately, then persists.
    func toggle(_ instrumentId: UUID) {
        guard let uid = AuthManager.shared.session?.userId else { return }
        let isCurrentlyFavorite = favoriteInstrumentIds.contains(instrumentId)
        // Optimistic update (reassign to trigger @Published; in-place insert/remove does not)
        if isCurrentlyFavorite {
            pendingRemoves.insert(instrumentId)
            pendingAdds.remove(instrumentId)
            favoriteInstrumentIds = favoriteInstrumentIds.subtracting([instrumentId])
            remove(instrumentId, userId: uid)
        } else {
            pendingAdds.insert(instrumentId)
            pendingRemoves.remove(instrumentId)
            favoriteInstrumentIds = favoriteInstrumentIds.union([instrumentId])
            add(instrumentId, userId: uid)
        }
    }

    func isFavorite(_ instrumentId: UUID) -> Bool {
        favoriteInstrumentIds.contains(instrumentId)
    }

    /// Call on sign out so the set is cleared until next load.
    func clear() {
        favoriteInstrumentIds = []
        pendingAdds = []
        pendingRemoves = []
    }

    private func add(_ instrumentId: UUID, userId: UUID) {
        let body: [String: Any] = [
            "user_id": userId.uuidString,
            "instrument_id": instrumentId.uuidString
        ]
        Task {
            do {
                _ = try await client.insert(table: table, body: body)
                _ = await MainActor.run { addDidSucceed(instrumentId) }
            } catch {
                print("[FavoritesStore] add failed: \(error)")
                _ = await MainActor.run {
                    pendingAdds.remove(instrumentId)
                    if favoriteInstrumentIds.contains(instrumentId) {
                        favoriteInstrumentIds = favoriteInstrumentIds.subtracting([instrumentId])
                    }
                }
            }
        }
    }

    private func addDidSucceed(_ instrumentId: UUID) {
        pendingAdds.remove(instrumentId)
    }

    private func remove(_ instrumentId: UUID, userId: UUID) {
        Task {
            do {
                let list: [Favorite] = try await client.fetch(
                    table: table,
                    query: [
                        URLQueryItem(name: "user_id", value: "eq.\(userId.uuidString)"),
                        URLQueryItem(name: "instrument_id", value: "eq.\(instrumentId.uuidString)")
                    ]
                )
                if let row = list.first {
                    try await client.delete(table: table, id: row.id)
                    _ = await MainActor.run { pendingRemoves.remove(instrumentId) }
                }
            } catch {
                print("[FavoritesStore] remove failed: \(error)")
                _ = await MainActor.run {
                    pendingRemoves.remove(instrumentId)
                    if !favoriteInstrumentIds.contains(instrumentId) {
                        favoriteInstrumentIds = favoriteInstrumentIds.union([instrumentId])
                    }
                }
            }
        }
    }
}
