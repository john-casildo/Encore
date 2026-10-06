//
//  BrowseView.swift
//  Encore
//

import SwiftUI
import CoreLocation

enum BrowseSort: String, CaseIterable {
    case newest
    case priceLow
    case priceHigh
    case topRated
    case nearest
}

struct BrowseView: View {
    @EnvironmentObject var language: LanguageManager
    @EnvironmentObject var favorites: FavoritesStore
    @ObservedObject private var locationManager = LocationManager.shared

    @State private var instruments: [Instrument] = []
    @State private var isLoading = true
    @State private var isOffline = false
    @State private var cacheDate: Date? = nil
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var sort: BrowseSort = .newest

    // Nearby
    @State private var nearbyEnabled = false
    @State private var radiusKm: Double = 10
    @State private var locationAccessDenied = false

    // Filters
    @State private var showFilters = false
    @State private var filterMinPrice: Double = 0
    @State private var filterMaxPrice: Double = 500_000
    @State private var filterCondition: String? = nil

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 16)]
    private static let categoryKeys = ["string", "percussion", "keys", "brass", "other"]
    private static let radiusOptions: [Double] = [5, 10, 25, 50]

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView(Strings.loading(language.sp))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 20) {
                            heroBanner
                            categoryChips
                            if nearbyEnabled { nearbyControls }
                            if locationAccessDenied {
                                locationDeniedBanner
                            }
                            if isOffline {
                                offlineBanner
                            }
                            if filteredInstruments.isEmpty {
                                emptyState
                            } else {
                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(sortedInstruments) { instrument in
                                        NavigationLink(value: instrument) {
                                            InstrumentCard(
                                                instrument: instrument,
                                                distanceKm: distanceTo(instrument)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await loadInstrumentsAsync(silent: false)
                        favorites.load()
                    }
                }
            }
            .navigationTitle(Strings.home(language.sp))
            .searchable(text: $searchText, prompt: Strings.search(language.sp))
            .searchSuggestions {
                ForEach(searchSuggestions, id: \.self) { suggestion in
                    Label(suggestion, systemImage: "magnifyingglass")
                        .searchCompletion(suggestion)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showFilters = true } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "slider.horizontal.3")
                            if hasActiveFilters {
                                Circle()
                                    .fill(Color.encorePrimary)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 4, y: -4)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterSheetView(
                    minPrice: $filterMinPrice,
                    maxPrice: $filterMaxPrice,
                    condition: $filterCondition,
                    language: language
                )
            }
            .navigationDestination(for: Instrument.self) { instrument in
                InstrumentDetailView(instrument: instrument)
            }
            .onAppear {
                loadInstruments()
                favorites.load()
            }
        }
    }

    // MARK: - Hero banner

    private var heroBanner: some View {
        ZStack(alignment: .leading) {
            // Flat Memphis background
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.encorePrimary)

            // Decorative Memphis shapes (clipped to banner)
            GeometryReader { geo in
                ZStack {
                    Circle()
                        .fill(Color.encoreAccent)
                        .frame(width: 72, height: 72)
                        .position(x: geo.size.width - 38, y: 30)
                    Circle()
                        .fill(Color.encorePink.opacity(0.85))
                        .frame(width: 28, height: 28)
                        .position(x: geo.size.width - 82, y: geo.size.height - 18)
                    Circle()
                        .fill(.white.opacity(0.3))
                        .frame(width: 16, height: 16)
                        .position(x: geo.size.width - 118, y: 16)
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.encoreTeal.opacity(0.7))
                        .frame(width: 18, height: 18)
                        .rotationEffect(.degrees(22))
                        .position(x: geo.size.width - 58, y: geo.size.height - 20)
                }
            }
            .frame(height: 155)
            .clipShape(RoundedRectangle(cornerRadius: 24))

            // Content
            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(language.sp ? "Encuentra tu\nsonido perfecto" : "Find your\nperfect sound")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Text(language.sp ? "Alquila instrumentos premium" : "Rent premium instruments")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(.leading, 20)
                Spacer()
                Image("EncoreLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .padding(.trailing, 16)
            }
        }
        .frame(height: 155)
        .memphisCard(cornerRadius: 24, offset: 4, lineWidth: 2)
        .overlay(alignment: .topTrailing) {
            Menu {
                ForEach([BrowseSort.newest, .priceLow, .priceHigh, .topRated], id: \.self) { option in
                    Button {
                        sort = option
                        if option != .nearest { nearbyEnabled = false }
                    } label: {
                        HStack {
                            Text(sortLabel(option))
                            if sort == option { Image(systemName: "checkmark") }
                        }
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(.white.opacity(0.25))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 1))
            }
            .padding(12)
        }
    }

    // MARK: - Sort menu (kept for label helper)

    private var sortMenu: some View { EmptyView() }

    private func sortLabel(_ option: BrowseSort) -> String {
        switch option {
        case .newest:   return Strings.newest(language.sp)
        case .priceLow:  return Strings.priceLowToHigh(language.sp)
        case .priceHigh: return Strings.priceHighToLow(language.sp)
        case .topRated:  return Strings.topRated(language.sp)
        case .nearest:   return Strings.nearest(language.sp)
        }
    }

    private var sortedInstruments: [Instrument] {
        switch sort {
        case .newest:    return filteredInstruments.sorted { ($0.createdAt ?? "") > ($1.createdAt ?? "") }
        case .priceLow:  return filteredInstruments.sorted { $0.pricePerDay < $1.pricePerDay }
        case .priceHigh: return filteredInstruments.sorted { $0.pricePerDay > $1.pricePerDay }
        case .topRated:  return filteredInstruments.sorted {
            NSDecimalNumber(decimal: $0.rating ?? 0).doubleValue >
            NSDecimalNumber(decimal: $1.rating ?? 0).doubleValue
        }
        case .nearest:
            return filteredInstruments.sorted {
                (distanceTo($0) ?? .greatestFiniteMagnitude) <
                (distanceTo($1) ?? .greatestFiniteMagnitude)
            }
        }
    }

    // MARK: - Category chips

    private var categoryChips: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Strings.categories(language.sp))
                .font(.title3.bold())
                .foregroundStyle(Color.encoreText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    nearbyChip
                    categoryChip(nil, icon: "music.note.list", label: language.sp ? "Todos" : "All")
                    ForEach(Self.categoryKeys, id: \.self) { key in
                        categoryChip(key, icon: categoryIcon(key), label: categoryLabel(key))
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var nearbyChip: some View {
        Button { toggleNearby() } label: {
            HStack(spacing: 5) {
                Image(systemName: nearbyEnabled ? "location.fill" : "location")
                    .font(.caption.weight(.bold))
                Text(Strings.nearby(language.sp))
                    .font(.subheadline.weight(.bold))
            }
            .foregroundStyle(nearbyEnabled ? .white : Color.encorePrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(nearbyEnabled ? Color.encorePrimary : Color(.systemBackground))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.primary, lineWidth: 2))
            .memphisShadow(x: nearbyEnabled ? 3 : 0, y: nearbyEnabled ? 3 : 0)
        }
        .buttonStyle(.plain)
    }

    private func categoryChip(_ value: String?, icon: String, label: String) -> some View {
        let isSelected = selectedCategory == value
        return Button { selectedCategory = value } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                Text(label)
                    .font(.subheadline.weight(.bold))
            }
            .foregroundStyle(isSelected ? .white : Color.encorePrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.encorePrimary : Color(.systemBackground))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.primary, lineWidth: 2))
            .memphisShadow(x: isSelected ? 3 : 0, y: isSelected ? 3 : 0)
        }
        .buttonStyle(.plain)
    }

    private func categoryIcon(_ key: String) -> String {
        switch key {
        case "string":     return "guitars"
        case "percussion": return "music.note"
        case "keys":       return "pianokeys"
        case "brass":      return "music.quarternote.3"
        default:           return "ellipsis.circle"
        }
    }

    private func categoryLabel(_ key: String) -> String {
        switch key {
        case "string":     return Strings.string(language.sp)
        case "percussion": return Strings.percussion(language.sp)
        case "keys":       return Strings.keys(language.sp)
        case "brass":      return Strings.brass(language.sp)
        default:           return Strings.other(language.sp)
        }
    }

    // MARK: - Nearby controls (radius slider)

    private var nearbyControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(Color.encoreTextSecondary)
                Text(Strings.radius(language.sp))
                    .font(.subheadline)
                    .foregroundStyle(Color.encoreTextSecondary)
                Spacer()
                Text(language.sp ? "\(Int(radiusKm)) km" : "\(Int(radiusKm)) km")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.encoreText)
                    .frame(minWidth: 52, alignment: .trailing)
            }

            // Segmented radius options
            HStack(spacing: 8) {
                ForEach(Self.radiusOptions, id: \.self) { r in
                    Button {
                        radiusKm = r
                    } label: {
                        Text("\(Int(r)) km")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(radiusKm == r ? .black : Color.encorePrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(radiusKm == r ? Color.encoreAccent : Color(.systemBackground))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(radiusKm == r ? Color.clear : Color.encorePrimary, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
            }

            if let loc = locationManager.currentLocation {
                Text(language.sp
                     ? "Buscando cerca de \(locationManager.cityName ?? "tu ubicación")"
                     : "Searching near \(locationManager.cityName ?? "your location")")
                    .font(.caption)
                    .foregroundStyle(Color.encoreTextSecondary)
                    .id(loc.coordinate.latitude)
            } else if locationManager.isLocating {
                HStack(spacing: 6) {
                    ProgressView().scaleEffect(0.7)
                    Text(language.sp ? "Detectando ubicación…" : "Detecting location…")
                        .font(.caption)
                        .foregroundStyle(Color.encoreTextSecondary)
                }
            }
        }
        .padding(14)
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }

    private var offlineBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "wifi.slash")
                .foregroundStyle(Color.encoreTextSecondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(language.sp ? "Sin conexión · Mostrando resultados guardados" : "Offline · Showing cached results")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.encoreText)
                if let date = cacheDate {
                    Text(language.sp ? "Actualizado \(relativeDate(date))" : "Updated \(relativeDate(date))")
                        .font(.caption2)
                        .foregroundStyle(Color.encoreTextSecondary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private var locationDeniedBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "location.slash")
                .foregroundStyle(.orange)
            Text(language.sp
                 ? "Activa la ubicación en Ajustes para ver instrumentos cercanos."
                 : "Enable location in Settings to see nearby instruments.")
                .font(.caption)
                .foregroundStyle(Color.encoreTextSecondary)
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            MemphisEmptyStateIllustration()
                .padding(.top, 12)

            Text(Strings.noResults(language.sp))
                .font(.title3.bold())
                .foregroundStyle(Color.encoreText)

            Text(nearbyEnabled
                 ? (language.sp
                    ? "No hay instrumentos en un radio de \(Int(radiusKm)) km."
                    : "No instruments within \(Int(radiusKm)) km.")
                 : (searchText.isEmpty && selectedCategory == nil
                    ? (language.sp ? "No hay instrumentos disponibles aún." : "No instruments available yet.")
                    : (language.sp ? "Prueba otro filtro." : "Try another filter."))
            )
            .font(.subheadline)
            .foregroundStyle(Color.encoreTextSecondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
    }

    // MARK: - Nearby toggle

    private func toggleNearby() {
        if nearbyEnabled {
            nearbyEnabled = false
            if sort == .nearest { sort = .newest }
            return
        }
        switch locationManager.authStatus {
        case .denied, .restricted:
            locationAccessDenied = true
        case .notDetermined, .authorizedWhenInUse, .authorizedAlways:
            locationAccessDenied = false
            nearbyEnabled = true
            sort = .nearest
            locationManager.requestLocation { loc in
                if let loc {
                    Task { await LocationManager.shared.reverseGeocode(loc) }
                }
            }
        @unknown default:
            break
        }
    }

    // MARK: - Distance helpers

    private func distanceTo(_ instrument: Instrument) -> Double? {
        guard nearbyEnabled,
              let userLoc = locationManager.currentLocation,
              let lat = instrument.latitude,
              let lon = instrument.longitude else { return nil }
        return userLoc.kilometersFrom(latitude: lat, longitude: lon)
    }

    // MARK: - Filtering

    private var filteredInstruments: [Instrument] {
        var list = instruments

        // Category filter
        if let cat = selectedCategory {
            list = list.filter { $0.category == cat }
        }
        // Search text — name only
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            list = list.filter { $0.name.lowercased().contains(q) }
        }
        // Nearby radius — only keep instruments that have coords and are within radius
        if nearbyEnabled, let userLoc = locationManager.currentLocation {
            list = list.filter { instrument in
                guard let lat = instrument.latitude, let lon = instrument.longitude else { return false }
                return userLoc.kilometersFrom(latitude: lat, longitude: lon) <= radiusKm
            }
        }
        // Price range filter
        let minP = Decimal(filterMinPrice)
        let maxP = Decimal(filterMaxPrice)
        if filterMinPrice > 0 || filterMaxPrice < 500_000 {
            list = list.filter { $0.pricePerDay >= minP && $0.pricePerDay <= maxP }
        }
        // Condition filter
        if let cond = filterCondition {
            list = list.filter { $0.condition == cond }
        }
        return list
    }

    private var hasActiveFilters: Bool {
        filterCondition != nil || filterMinPrice > 0 || filterMaxPrice < 500_000
    }

    private var searchSuggestions: [String] {
        guard !searchText.isEmpty else { return [] }
        let q = searchText.lowercased()
        let names = instruments
            .map(\.name)
            .filter { $0.lowercased().contains(q) }
        return Array(Set(names)).sorted().prefix(5).map { $0 }
    }

    // MARK: - Data

    private func loadInstruments() {
        // Show cache immediately if available — no spinner
        if let cached = ListingsCache.load(), !cached.isEmpty {
            instruments = cached
            cacheDate = ListingsCache.date()
            isLoading = false
            // Refresh silently in background
            Task { await loadInstrumentsAsync(silent: true) }
        } else {
            isLoading = true
            Task { await loadInstrumentsAsync(silent: false) }
        }
    }

    private func loadInstrumentsAsync(silent: Bool = false) async {
        do {
            let list: [Instrument] = try await SupabaseClient.shared.fetch(
                table: "instruments",
                query: [URLQueryItem(name: "is_available", value: "eq.true")]
            )
            ListingsCache.save(list)
            await MainActor.run {
                instruments = list
                cacheDate = ListingsCache.date()
                isOffline = false
                isLoading = false
            }
        } catch {
            print("[BrowseView] load failed: \(error)")
            await MainActor.run {
                // If we have cached data, keep showing it with offline banner
                if instruments.isEmpty {
                    isLoading = false
                }
                isOffline = true
            }
        }
    }
}

// MARK: - Filter sheet

struct FilterSheetView: View {
    @Binding var minPrice: Double
    @Binding var maxPrice: Double
    @Binding var condition: String?
    @ObservedObject var language: LanguageManager
    @Environment(\.dismiss) private var dismiss

    // Local draft state — only committed on "Apply"
    @State private var draftMin: Double = 0
    @State private var draftMax: Double = 500_000
    @State private var draftCondition: String? = nil

    private var priceRanges: [(label: String, min: Double, max: Double)] {[
        (language.sp ? "Cualquier precio" : "Any", 0, 500_000),
        ("₡0–5k", 0, 5_000),
        ("₡5k–20k", 5_000, 20_000),
        ("₡20k–50k", 20_000, 50_000),
        ("₡50k+", 50_000, 500_000),
    ]}
    private let conditions = ["excellent", "good", "fair"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // Price range
                    VStack(alignment: .leading, spacing: 12) {
                        Text(language.sp ? "Precio por día" : "Price per day")
                            .font(.headline)
                            .foregroundStyle(Color.encoreText)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 10)], spacing: 10) {
                            ForEach(priceRanges, id: \.label) { range in
                                let isSelected = draftMin == range.min && draftMax == range.max
                                Button {
                                    draftMin = range.min
                                    draftMax = range.max
                                } label: {
                                    Text(range.label)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(isSelected ? .black : Color.encorePrimary)
                                        .padding(.vertical, 10)
                                        .frame(maxWidth: .infinity)
                                        .background(isSelected ? Color.encoreAccent : Color(.systemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary, lineWidth: 2))
                                        .memphisShadow(x: isSelected ? 3 : 0, y: isSelected ? 3 : 0)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Divider()

                    // Condition
                    VStack(alignment: .leading, spacing: 12) {
                        Text(language.sp ? "Condición" : "Condition")
                            .font(.headline)
                            .foregroundStyle(Color.encoreText)

                        HStack(spacing: 10) {
                            conditionChip(nil, label: language.sp ? "Cualquiera" : "Any")
                            ForEach(conditions, id: \.self) { cond in
                                conditionChip(cond, label: conditionLabel(cond))
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle(language.sp ? "Filtros" : "Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(language.sp ? "Limpiar" : "Clear all") {
                        draftMin = 0
                        draftMax = 500_000
                        draftCondition = nil
                    }
                    .foregroundStyle(Color.encoreTextSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(language.sp ? "Aplicar" : "Apply") {
                        minPrice = draftMin
                        maxPrice = draftMax
                        condition = draftCondition
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.encoreText)
                }
            }
        }
        .onAppear {
            draftMin = minPrice
            draftMax = maxPrice
            draftCondition = condition
        }
    }

    private func conditionChip(_ value: String?, label: String) -> some View {
        let isSelected = draftCondition == value
        return Button {
            draftCondition = value
        } label: {
            Text(label)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(isSelected ? .black : Color.encorePrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(isSelected ? Color.encoreAccent : Color(.systemBackground))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.primary, lineWidth: 2))
                .memphisShadow(x: isSelected ? 3 : 0, y: isSelected ? 3 : 0)
        }
        .buttonStyle(.plain)
    }

    private func conditionLabel(_ key: String) -> String {
        switch key {
        case "excellent": return language.sp ? "Excelente" : "Excellent"
        case "good":      return language.sp ? "Bueno" : "Good"
        case "fair":      return language.sp ? "Regular" : "Fair"
        default:          return key
        }
    }
}

// MARK: - Instrument card

struct InstrumentCard: View {
    @EnvironmentObject var language: LanguageManager
    @EnvironmentObject var favorites: FavoritesStore
    let instrument: Instrument
    var distanceKm: Double? = nil

    private var isFavorite: Bool { favorites.isFavorite(instrument.id) }

    private static let cardPalette: [Color] = [
        Color(hex: "7C3AED"),
        Color(hex: "059669"),
        Color(hex: "D97706"),
        Color(hex: "DB2777"),
        Color(hex: "2563EB"),
        Color(hex: "0891B2"),
    ]

    private var tileColor: Color {
        let idx = abs(instrument.id.hashValue) % Self.cardPalette.count
        return Self.cardPalette[idx]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Colored top — image on solid background
            ZStack {
                tileColor
                RemoteImage(url: instrument.imageUrls.first, emojiFallback: instrument.imageEmoji ?? "🎸", category: instrument.category)
                    .clipped()
            }
            .frame(height: 130)
            .clipped()
            .overlay(alignment: .top) {
                HStack {
                    if let km = distanceKm {
                        Text(km < 1 ? "< 1 km" : "\(String(format: "%.1f", km)) km")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.45))
                            .clipShape(Capsule())
                    }
                    Spacer()
                    Button(action: { favorites.toggle(instrument.id) }) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(isFavorite ? Color(hex: "F43F5E") : .white)
                            .shadow(color: .black.opacity(0.6), radius: 3)
                    }
                    .buttonStyle(.plain)
                }
                .padding(9)
            }

            // Colored bottom info area
            VStack(alignment: .leading, spacing: 5) {
                Text(instrument.name)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if let rating = instrument.rating, (instrument.reviewCount ?? 0) > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.encoreAccent)
                        Text(NSDecimalNumber(decimal: rating).doubleValue, format: .number.precision(.fractionLength(1)))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }

                HStack(alignment: .bottom) {
                    Text("₡\(NSDecimalNumber(decimal: instrument.pricePerDay).intValue)/\(language.sp ? "día" : "day")")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Color.encoreAccent)
                        .clipShape(Capsule())
                    Spacer()
                }

                Text(language.sp ? "Reservar" : "Rent Now")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(tileColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(.white)
                    .clipShape(Capsule())
                    .padding(.top, 2)
            }
            .padding(12)
            .background(tileColor)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.primary, lineWidth: 2))
        .memphisShadow(x: 4, y: 4)
    }
}
