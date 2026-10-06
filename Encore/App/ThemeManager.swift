//
//  ThemeManager.swift
//  Encore
//

import SwiftUI

enum AppTheme: String, CaseIterable {
    case system
    case light
    case dark
}

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    private let key = "Encore.AppTheme"

    @Published var theme: AppTheme {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: key)
        }
    }

    /// Returns nil when the theme should follow the device system setting.
    var colorScheme: ColorScheme? {
        switch theme {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: "Encore.AppTheme") ?? "system"
        self.theme = AppTheme(rawValue: raw) ?? .system
    }

    func label(sp: Bool) -> String {
        switch theme {
        case .system: return sp ? "Sistema" : "System"
        case .light:  return sp ? "Claro" : "Light"
        case .dark:   return sp ? "Oscuro" : "Dark"
        }
    }
}
