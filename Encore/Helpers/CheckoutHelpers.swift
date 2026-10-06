//
//  CheckoutHelpers.swift
//  Encore
//

import Foundation

/// Extracted checkout logic for testability.
enum CheckoutHelpers {
    static func cardBrand(from number: String) -> String {
        let digits = number.filter { $0.isNumber }
        if digits.hasPrefix("4") { return "visa" }
        if digits.hasPrefix("5") || digits.hasPrefix("2") { return "mastercard" }
        if digits.hasPrefix("34") || digits.hasPrefix("37") { return "amex" }
        return "card"
    }

    static func formatCardNumber(_ raw: String) -> String {
        let digits = raw.filter { $0.isNumber }.prefix(16)
        var result = ""
        for (i, ch) in digits.enumerated() {
            if i > 0 && i % 4 == 0 { result += " " }
            result.append(ch)
        }
        return result
    }

    static func formatExpiry(_ raw: String) -> String {
        let digits = raw.filter { $0.isNumber }.prefix(4)
        if digits.count <= 2 { return String(digits) }
        return "\(digits.prefix(2)) / \(digits.dropFirst(2))"
    }
}
