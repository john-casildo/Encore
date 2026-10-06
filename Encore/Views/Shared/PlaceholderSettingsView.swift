//
//  PlaceholderSettingsView.swift
//  Encore
//

import SwiftUI

struct PlaceholderSettingsView: View {
    let title: String
    let message: String
    @EnvironmentObject var language: LanguageManager

    var body: some View {
        VStack(spacing: 16) {
            Text(message)
                .font(.body)
                .foregroundStyle(Color.encoreTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
