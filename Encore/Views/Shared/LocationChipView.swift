//
//  LocationChipView.swift
//  Encore
//

import SwiftUI

/// Simple location display (city + country) for profile headers.
struct LocationChipView: View {
    let city: String?
    let country: CountryDialCode?

    /// Shared logic for testability.
    static func locationText(city: String?, country: CountryDialCode?) -> String {
        let c = city?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let co = country?.name ?? ""
        if !c.isEmpty && !co.isEmpty { return "\(c), \(co)" }
        if !c.isEmpty { return c }
        return co
    }

    private var locationText: String {
        Self.locationText(city: city, country: country)
    }

    var body: some View {
        Group {
            if !locationText.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.encoreTextSecondary)
                    Text(locationText)
                        .font(.subheadline)
                        .foregroundStyle(Color.encoreTextSecondary)
                        .lineLimit(1)
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        LocationChipView(city: "Alajuela", country: CountryDialCode.forIso("CR"))
        LocationChipView(city: nil, country: CountryDialCode.forIso("US"))
        LocationChipView(city: "San José", country: nil)
    }
    .padding()
}
