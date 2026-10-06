//
//  LanguageManager.swift
//  Encore
//

import SwiftUI

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case spanish = "es"
}

final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    private let key = "Encore.AppLanguage"

    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: key)
        }
    }

    var sp: Bool { language == .spanish }

    init() {
        let raw = UserDefaults.standard.string(forKey: "Encore.AppLanguage") ?? "en"
        self.language = AppLanguage(rawValue: raw) ?? .english
    }
}
