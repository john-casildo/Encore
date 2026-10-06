//
//  PrivacySettingsView.swift
//  Encore
//

import SwiftUI

struct PrivacySettingsView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var language: LanguageManager

    @State private var settings: UserSettings? = nil
    @State private var isLoading = true
    @State private var isSaving = false

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                VStack(spacing: 16) {
                    settingsSection(
                        header: language.sp ? "Notificaciones" : "Notifications",
                        rows: [
                            (language.sp ? "Reservas" : "Bookings", "calendar.badge.checkmark", Color.encorePrimary, binding(\.notifBookings)),
                            (language.sp ? "Mensajes" : "Messages", "message.fill", Color.encoreBlue, binding(\.notifMessages)),
                            (language.sp ? "Recordatorios" : "Reminders", "bell.fill", Color.encoreOrange, binding(\.notifReminders)),
                            (language.sp ? "Promociones" : "Promotions", "tag.fill", Color.encorePink, binding(\.notifPromotions)),
                        ]
                    )

                    settingsSection(
                        header: language.sp ? "Privacidad" : "Privacy",
                        rows: [
                            (language.sp ? "Mostrar teléfono en mi perfil" : "Show phone on my profile", "phone.fill", Color.encoreGreen, binding(\.showPhone)),
                            (language.sp ? "Mostrar ubicación en mi perfil" : "Show location on my profile", "location.fill", Color.encoreTeal, binding(\.showLocation)),
                        ]
                    )

                    // Security badge
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.encorePrimary.opacity(0.12))
                                .frame(width: 36, height: 36)
                                .overlay(Circle().stroke(Color.primary, lineWidth: 1.5))
                            Image(systemName: "lock.shield.fill")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.encorePrimary)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(language.sp ? "Datos y seguridad" : "Data & security")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.encoreText)
                            Text(language.sp
                                 ? "Tus datos se almacenan de forma segura."
                                 : "Your data is stored securely.")
                                .font(.caption)
                                .foregroundStyle(Color.encoreTextSecondary)
                        }
                        Spacer()
                        Text(language.sp ? "Protegido" : "Protected")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.encoreGreen)
                            .clipShape(Capsule())
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(14)
                    .memphisCard(cornerRadius: 14, offset: 3, lineWidth: 1.5)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .background(Color.encoreFrame.ignoresSafeArea())
        .navigationTitle(Strings.privacy(language.sp))
        .navigationBarTitleDisplayMode(.large)
        .task { await loadSettings() }
    }

    private func settingsSection(header: String, rows: [(String, String, Color, Binding<Bool>)]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(header)
                .font(.caption.weight(.black))
                .foregroundStyle(Color.encoreTextSecondary)
                .textCase(.uppercase)
                .padding(.horizontal, 4)
                .padding(.bottom, 8)
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
                    let (label, icon, color, binding) = row
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(color.opacity(0.18))
                                .frame(width: 32, height: 32)
                                .overlay(Circle().stroke(Color.primary, lineWidth: 1))
                            Image(systemName: icon)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(color)
                        }
                        Text(label)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.encoreText)
                        Spacer()
                        Toggle("", isOn: binding)
                            .labelsHidden()
                            .tint(Color.encorePrimary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    if idx < rows.count - 1 {
                        Divider().padding(.horizontal)
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .memphisCard(cornerRadius: 14, offset: 3, lineWidth: 1.5)
        }
    }

    // MARK: - Binding helper

    private func binding(_ keyPath: WritableKeyPath<UserSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { settings?[keyPath: keyPath] ?? false },
            set: { newVal in
                settings?[keyPath: keyPath] = newVal
                Task { await saveSettings() }
            }
        )
    }

    // MARK: - Load

    private func loadSettings() async {
        guard let uid = auth.session?.userId else {
            isLoading = false
            return
        }
        do {
            let query = [URLQueryItem(name: "user_id", value: "eq.\(uid.uuidString)")]
            let rows: [UserSettings] = try await SupabaseClient.shared.fetch(
                table: "user_settings",
                query: query
            )
            await MainActor.run {
                settings = rows.first ?? UserSettings.defaults(for: uid)
                isLoading = false
            }
        } catch {
            await MainActor.run {
                settings = UserSettings.defaults(for: uid)
                isLoading = false
            }
        }
    }

    // MARK: - Save (upsert)

    private func saveSettings() async {
        guard let s = settings else { return }
        let body: [String: Any] = [
            "user_id": s.userId.uuidString,
            "notif_bookings": s.notifBookings,
            "notif_messages": s.notifMessages,
            "notif_reminders": s.notifReminders,
            "notif_promotions": s.notifPromotions,
            "show_phone": s.showPhone,
            "show_location": s.showLocation
        ]
        do {
            let url = URL(string: "\(SupabaseConfig.restURL)/user_settings")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            var headers: [String: String] = [
                "apikey": SupabaseConfig.anonKey,
                "Content-Type": "application/json",
                "Prefer": "resolution=merge-duplicates,return=minimal"
            ]
            if let token = SupabaseClient.shared.accessToken {
                headers["Authorization"] = "Bearer \(token)"
            }
            headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            _ = try await URLSession.shared.data(for: request)
        } catch {
            print("[PrivacySettingsView] save failed: \(error)")
        }
    }
}

