//
//  Extensions.swift
//  Encore
//

import SwiftUI

// MARK: - Color (hex)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Design system (Corporate Memphis)

extension Color {
    // Primary: always purple
    static let encorePrimary     = Color(hex: "7C3AED")
    static let encorePrimaryDark = Color(hex: "4C1D95")
    // Accent: bright yellow (active states, price badges)
    static let encoreAccent      = Color(hex: "FCD34D")
    // Tinted backgrounds (adaptive: light in light mode, dark tint in dark mode)
    static let encoreWarmBg      = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.12, green: 0.08, blue: 0.04, alpha: 1)   // dark warm brown
            : UIColor(red: 1.00, green: 0.98, blue: 0.94, alpha: 1)   // #FFFBF0
    })
    static let encoreLightPurple = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.18, green: 0.10, blue: 0.34, alpha: 1)   // dark purple tint
            : UIColor(red: 0.95, green: 0.91, blue: 1.00, alpha: 1)   // #F3E8FF
    })
    static let encoreLightYellow = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.16, green: 0.13, blue: 0.04, alpha: 1)   // dark warm yellow
            : UIColor(red: 1.00, green: 0.95, blue: 0.78, alpha: 1)   // #FEF3C7
    })
    // Vibrant palette
    static let encorePink        = Color(hex: "EC4899")
    static let encoreGreen       = Color(hex: "34D399")
    static let encoreBlue        = Color(hex: "60A5FA")
    static let encoreCoral       = Color(hex: "F87171")
    static let encoreTeal        = Color(hex: "2DD4BF")
    static let encoreOrange      = Color(hex: "FB923C")
    // Page background tint (soft lavender)
    static let encoreFrame       = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.08, green: 0.04, blue: 0.16, alpha: 1)   // near-black purple
            : UIColor(red: 0.95, green: 0.91, blue: 1.00, alpha: 1)   // #F2E8FF soft lavender
    })
    // System-adapting
    static let encoreBackground  = Color(UIColor.systemBackground)
    static let encoreText        = Color(UIColor.label)
    static let encoreTextSecondary = Color(UIColor.secondaryLabel)
}

// MARK: - Memphis card modifier

struct MemphisCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    var offset: CGFloat = 4
    var lineWidth: CGFloat = 2

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.primary, lineWidth: lineWidth)
            )
            .shadow(
                color: colorScheme == .dark ? .clear : .black,
                radius: 0, x: offset, y: offset
            )
    }
}

extension View {
    func memphisCard(cornerRadius: CGFloat = 16, offset: CGFloat = 4, lineWidth: CGFloat = 2) -> some View {
        modifier(MemphisCardModifier(cornerRadius: cornerRadius, offset: offset, lineWidth: lineWidth))
    }

    /// Dark-mode-safe Memphis drop shadow: black in light mode, invisible in dark mode.
    func memphisShadow(x: CGFloat = 3, y: CGFloat = 3) -> some View {
        modifier(MemphisShadowModifier(x: x, y: y))
    }
}

struct MemphisShadowModifier: ViewModifier {
    var x: CGFloat
    var y: CGFloat
    @Environment(\.colorScheme) private var colorScheme
    func body(content: Content) -> some View {
        content.shadow(color: colorScheme == .dark ? .clear : .black, radius: 0, x: x, y: y)
    }
}

/// Adaptive border color: black in light mode, white in dark mode.
extension Color {
    static let memphisBorder = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? .white : .black
    })
}

// MARK: - Rounded corners on specific sides

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// MARK: - Date formatting helpers

extension String {
    /// Converts a "yyyy-MM-dd" string to a display format like "Mar 5" or "Mar 5, 2026".
    func formattedDate(showYear: Bool = false) -> String {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"
        parser.locale = Locale(identifier: "en_US_POSIX")
        guard let date = parser.date(from: self) else { return self }
        let display = DateFormatter()
        display.dateFormat = showYear ? "MMM d, yyyy" : "MMM d"
        return display.string(from: date)
    }

    /// Formats a date range from two "yyyy-MM-dd" strings: "Mar 5 – Mar 10".
    static func formattedRange(start: String, end: String) -> String {
        "\(start.formattedDate()) – \(end.formattedDate())"
    }
}

// MARK: - StyledTextField

struct StyledTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary, lineWidth: 1.5)
        )
    }
}
