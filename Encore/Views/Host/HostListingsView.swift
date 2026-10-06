//
//  HostListingsView.swift
//  Encore
//

import SwiftUI

struct HostListingsView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var language: LanguageManager
    @State private var instruments: [Instrument] = []
    @State private var isLoading = true
    @State private var toast: Toast?
    @State private var togglingIds: Set<UUID> = []

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView(Strings.loading(language.sp))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if instruments.isEmpty {
                    MemphisEmptyView(
                        icon: "guitars.fill",
                        circleColor: Color.encorePrimary,
                        accentColor: Color.encoreAccent,
                        secondAccent: Color.encoreTeal,
                        title: language.sp ? "Sin anuncios aún" : "No listings yet",
                        subtitle: language.sp
                            ? "Toca + para publicar tu primer instrumento."
                            : "Tap + to publish your first instrument."
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(instruments) { instrument in
                                NavigationLink(destination: EditInstrumentView(instrument: instrument) { _ in
                                    Task { await loadListingsAsync() }
                                    toast = Toast(message: language.sp ? "Anuncio actualizado" : "Listing updated")
                                }) {
                                    HostListingCard(
                                        instrument: instrument,
                                        isAvailable: binding(for: instrument),
                                        isToggling: togglingIds.contains(instrument.id),
                                        language: language,
                                        onToggleAvailability: { persistAvailability(instrument) }
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                    .refreshable { await loadListingsAsync() }
                }
            }
            .navigationTitle(Strings.yourListings(language.sp))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink(destination: AddInstrumentView()) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.encorePrimary)
                    }
                }
            }
            .task { await loadListingsAsync() }
        }
        .toast($toast)
    }

    private func loadListingsAsync() async {
        guard let hostId = auth.session?.userId else {
            await MainActor.run { instruments = []; isLoading = false }
            return
        }
        do {
            let query: [URLQueryItem] = [
                URLQueryItem(name: "host_id", value: "eq.\(hostId.uuidString)"),
                URLQueryItem(name: "order", value: "created_at.desc")
            ]
            let list: [Instrument] = try await SupabaseClient.shared.fetch(table: "instruments", query: query)
            await MainActor.run { instruments = list; isLoading = false }
        } catch {
            print("[HostListingsView] load failed: \(error)")
            await MainActor.run { instruments = []; isLoading = false }
        }
    }

    private func binding(for instrument: Instrument) -> Binding<Bool> {
        guard let idx = instruments.firstIndex(where: { $0.id == instrument.id }) else {
            return .constant(false)
        }
        return $instruments[idx].isAvailable
    }

    private func persistAvailability(_ instrument: Instrument) {
        guard !togglingIds.contains(instrument.id),
              let idx = instruments.firstIndex(where: { $0.id == instrument.id }) else { return }
        let newValue = instruments[idx].isAvailable
        togglingIds.insert(instrument.id)
        Task {
            do {
                try await SupabaseClient.shared.update(
                    table: "instruments",
                    id: instrument.id,
                    body: ["is_available": newValue]
                )
                ListingsCache.invalidate()
                await MainActor.run {
                    togglingIds.remove(instrument.id)
                    let msg = newValue
                        ? (language.sp ? "Disponible" : "Now available")
                        : (language.sp ? "No disponible" : "Now unavailable")
                    toast = Toast(message: msg)
                }
            } catch {
                print("[HostListingsView] toggle failed: \(error)")
                await MainActor.run {
                    instruments[idx].isAvailable = !newValue
                    togglingIds.remove(instrument.id)
                }
            }
        }
    }
}

// MARK: - Host listing card

struct HostListingCard: View {
    let instrument: Instrument
    @Binding var isAvailable: Bool
    var isToggling: Bool = false
    let language: LanguageManager
    let onToggleAvailability: () -> Void

    private static let tilePalette: [Color] = [
        Color(hex: "7C3AED"), Color(hex: "059669"),
        Color(hex: "D97706"), Color(hex: "DB2777"),
        Color(hex: "2563EB"), Color(hex: "0891B2"),
    ]
    private var tileColor: Color {
        let idx = abs(instrument.id.hashValue) % Self.tilePalette.count
        return Self.tilePalette[idx]
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(tileColor)
                    .frame(width: 68, height: 68)
                RemoteImage(url: instrument.imageUrls.first, emojiFallback: instrument.imageEmoji ?? "🎸", category: instrument.category)
                    .frame(width: 68, height: 68)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(instrument.name)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.encoreText)
                Text(instrument.location ?? "—")
                    .font(.caption)
                    .foregroundStyle(Color.encoreTextSecondary)
                Text("₡\(NSDecimalNumber(decimal: instrument.pricePerDay).intValue)/\(language.sp ? "día" : "day")")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.encorePrimary)
            }
            Spacer()
            Toggle("", isOn: $isAvailable)
                .labelsHidden()
                .tint(Color.encorePrimary)
                .disabled(isToggling)
                .onChange(of: isAvailable) { _ in onToggleAvailability() }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .memphisCard(cornerRadius: 16, offset: 3, lineWidth: 1.5)
    }
}
