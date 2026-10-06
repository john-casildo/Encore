//
//  FavoritesView.swift
//  Encore
//

import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var language: LanguageManager
    @EnvironmentObject var favorites: FavoritesStore
    @State private var instruments: [Instrument] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView(Strings.loading(language.sp))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if instruments.isEmpty {
                MemphisEmptyView(
                    icon: "heart.fill",
                    circleColor: Color.encorePink,
                    accentColor: Color.encoreAccent,
                    secondAccent: Color.encorePrimary,
                    title: language.sp ? "Nada guardado aún" : "Nothing saved yet",
                    subtitle: language.sp
                        ? "Toca el corazón en un instrumento para guardarlo aquí."
                        : "Tap the heart on any instrument to save it here."
                )
            } else {
                let columns = [GridItem(.adaptive(minimum: 160), spacing: 16)]
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(instruments) { instrument in
                            NavigationLink(value: instrument) {
                                InstrumentCard(instrument: instrument)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
                .refreshable {
                    await loadInstrumentsAsync()
                }
            }
        }
        .navigationTitle(Strings.saved(language.sp))
        .onAppear {
            favorites.load()
            loadInstruments()
        }
        .onChange(of: favorites.favoriteInstrumentIds) { _ in
            loadInstruments()
        }
        .navigationDestination(for: Instrument.self) { instrument in
            InstrumentDetailView(instrument: instrument)
        }
    }

    private func loadInstruments() {
        let ids = Array(favorites.favoriteInstrumentIds)
        guard !ids.isEmpty else {
            instruments = []
            isLoading = false
            return
        }
        isLoading = true
        Task { await loadInstrumentsAsync() }
    }

    private func loadInstrumentsAsync() async {
        let ids = Array(favorites.favoriteInstrumentIds)
        guard !ids.isEmpty else {
            await MainActor.run { instruments = []; isLoading = false }
            return
        }
        await MainActor.run { isLoading = true }
        let inFilter = "in.(\(ids.map(\.uuidString).joined(separator: ",")))"
        do {
            let list: [Instrument] = try await SupabaseClient.shared.fetch(
                table: "instruments",
                query: [
                    URLQueryItem(name: "id", value: inFilter),
                    URLQueryItem(name: "is_available", value: "eq.true")
                ]
            )
            await MainActor.run { instruments = list; isLoading = false }
        } catch {
            print("[FavoritesView] load failed: \(error)")
            await MainActor.run { instruments = []; isLoading = false }
        }
    }
}

#Preview {
    NavigationStack {
        FavoritesView()
            .environmentObject(LanguageManager.shared)
            .environmentObject(FavoritesStore.shared)
    }
}
