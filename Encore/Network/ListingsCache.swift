//
//  ListingsCache.swift
//  Encore
//

import Foundation

struct ListingsCache {
    private static let instrumentsKey = "Encore.CachedInstruments"
    private static let timestampKey   = "Encore.CachedInstrumentsDate"

    static func save(_ instruments: [Instrument]) {
        guard let data = try? JSONEncoder().encode(instruments) else { return }
        UserDefaults.standard.set(data, forKey: instrumentsKey)
        UserDefaults.standard.set(Date(), forKey: timestampKey)
    }

    static func load() -> [Instrument]? {
        guard let data = UserDefaults.standard.data(forKey: instrumentsKey),
              let list = try? JSONDecoder.supabase.decode([Instrument].self, from: data)
        else { return nil }
        return list
    }

    static func date() -> Date? {
        UserDefaults.standard.object(forKey: timestampKey) as? Date
    }

    static func invalidate() {
        UserDefaults.standard.removeObject(forKey: instrumentsKey)
        UserDefaults.standard.removeObject(forKey: timestampKey)
    }
}
