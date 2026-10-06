//
//  InstrumentDetailView.swift
//  Encore
//

import SwiftUI
import MapKit

struct InstrumentDetailView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var language: LanguageManager
    @EnvironmentObject var favorites: FavoritesStore
    let instrument: Instrument
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 9.93, longitude: -84.08),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var hasValidRegion = false
    @State private var hostUser: AppUser?
    @State private var currentImageIndex = 0
    @State private var conversationSheetItem: ConversationSheetItem?
    @State private var isFindingOrCreatingConversation = false
    @State private var reviews: [Review] = []
    @State private var reviewsLoading = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                heroImage
                titleAndPrice
                hostRow
                descriptionSection
                reviewsSection
                locationSection
            }
            .padding(.bottom, 100)
        }
        .overlay(alignment: .bottom) { reserveButton }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    favorites.toggle(instrument.id)
                } label: {
                    Image(systemName: favorites.isFavorite(instrument.id) ? "heart.fill" : "heart")
                        .foregroundStyle(favorites.isFavorite(instrument.id) ? .red : Color.encoreText)
                }
            }
        }
        .onAppear {
            setRegion()
            favorites.load()
            loadHost()
            loadReviews()
        }
        .fullScreenCover(item: $conversationSheetItem) { item in
            NavigationStack {
                Group {
                    switch item {
                    case .existing(let conv, let other):
                        ConversationView(conversation: conv, otherUser: other)
                    case .pending(let hostId, let hostUser, let inst):
                        ConversationView(
                            pendingHostId: hostId,
                            pendingHostUser: hostUser,
                            instrument: inst,
                            onConversationCreated: { conv in
                                conversationSheetItem = .existing(conv, hostUser)
                            }
                        )
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(Strings.done(language.sp)) {
                            conversationSheetItem = nil
                        }
                    }
                }
            }
            .environmentObject(auth)
            .environmentObject(language)
        }
    }

    private var heroImage: some View {
        Group {
            if instrument.imageUrls.isEmpty || instrument.imageUrls.count == 1 {
                RemoteImage(
                    url: instrument.imageUrls.first,
                    emojiFallback: instrument.imageEmoji ?? "🎸",
                    category: instrument.category
                )
                .background(Color.encorePrimary)
                .frame(height: 240)
                .frame(maxWidth: .infinity)
                .clipped()
            } else {
                TabView(selection: $currentImageIndex) {
                    ForEach(Array(instrument.imageUrls.enumerated()), id: \.offset) { index, url in
                        RemoteImage(url: url, emojiFallback: instrument.imageEmoji ?? "🎸", category: instrument.category)
                            .background(Color.encorePrimary)
                            .frame(height: 240)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .frame(height: 240)
            }
        }
    }

    private var titleAndPrice: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(instrument.name)
                    .font(.title2.bold())
                    .foregroundStyle(Color.encoreText)
                if let rating = instrument.rating, (instrument.reviewCount ?? 0) > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.encorePrimary)
                        Text(NSDecimalNumber(decimal: rating).doubleValue, format: .number.precision(.fractionLength(1)))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.encoreText)
                        Text("· \(instrument.reviewCount ?? 0) \(Strings.reviews(language.sp))")
                            .font(.caption)
                            .foregroundStyle(Color.encoreTextSecondary)
                    }
                }
            }
            Spacer()
            Text(priceString(instrument.pricePerDay))
                .font(.title2.bold())
                .foregroundStyle(Color.encoreText)
        }
        .padding(.horizontal)
    }

    private var hostRow: some View {
        HStack(spacing: 12) {
            ProfileAvatarView(url: hostUser?.avatarUrl, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(language.sp ? "Anfitrión" : "Host")
                    .font(.caption)
                    .foregroundStyle(Color.encoreTextSecondary)
                HStack(spacing: 6) {
                    Text(hostUser?.displayName ?? "—")
                        .font(.subheadline.weight(.medium))
                    if hostUser?.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(Color.encorePrimary)
                    }
                }
                if hostUser?.isVerified == true {
                    Text(Strings.verifiedHost(language.sp))
                        .font(.caption2)
                        .foregroundStyle(Color.encoreTextSecondary)
                }
            }
            Spacer()
            if hostUser != nil {
                Button {
                    findOrCreateConversation()
                } label: {
                    Text(Strings.messageHost(language.sp))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.encorePrimary)
                }
                .disabled(isFindingOrCreatingConversation)
                .contentShape(Rectangle())
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }

    private func findOrCreateConversation() {
        guard auth.currentUser?.id != nil else { return }
        isFindingOrCreatingConversation = true
        Task {
            do {
                let uid = auth.currentUser!.id
                let existing: [Conversation] = try await SupabaseClient.shared.fetch(
                    table: "conversations",
                    query: [
                        URLQueryItem(name: "select", value: "*,instruments(name,image_urls,image_emoji)"),
                        URLQueryItem(name: "renter_id", value: "eq.\(uid.uuidString)"),
                        URLQueryItem(name: "host_id", value: "eq.\(instrument.hostId.uuidString)")
                    ]
                )
                await MainActor.run {
                    if let first = existing.first {
                        conversationSheetItem = .existing(first, hostUser)
                    } else {
                        // Don't create conversation yet — only when user sends first message
                        conversationSheetItem = .pending(hostId: instrument.hostId, hostUser: hostUser, instrument: instrument)
                    }
                    isFindingOrCreatingConversation = false
                }
            } catch {
                print("[InstrumentDetailView] findOrCreateConversation failed: \(error)")
                await MainActor.run { isFindingOrCreatingConversation = false }
            }
        }
    }

    private func loadHost() {
        Task {
            do {
                let list: [AppUser] = try await SupabaseClient.shared.fetch(
                    table: "users",
                    query: [URLQueryItem(name: "id", value: "eq.\(instrument.hostId.uuidString)")]
                )
                await MainActor.run { hostUser = list.first }
            } catch {
                print("[InstrumentDetailView] loadHost failed: \(error)")
            }
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.description(language.sp))
                .font(.headline)
                .foregroundStyle(Color.encoreText)
            Text(instrument.description ?? (language.sp ? "Sin descripción." : "No description."))
                .font(.body)
                .foregroundStyle(Color.encoreTextSecondary)
        }
        .padding(.horizontal)
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.rentalLocation(language.sp))
                .font(.headline)
                .foregroundStyle(Color.encoreText)
            Text(instrument.location ?? "—")
                .font(.subheadline)
                .foregroundStyle(Color.encoreTextSecondary)
            if hasValidRegion {
                Map(coordinateRegion: $mapRegion)
                    .frame(height: 160)
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }

    private var reserveButton: some View {
        VStack(spacing: 0) {
            Divider()
            NavigationLink(destination: CheckoutView(instrument: instrument)) {
                Text(Strings.reserve(language.sp))
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.encorePrimary)
                    .cornerRadius(12)
                    .contentShape(Rectangle())
                    .memphisCard(cornerRadius: 12, offset: 3, lineWidth: 2)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.encoreBackground)
        }
    }

    // MARK: - Reviews preview

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack {
                Text(language.sp ? "Reseñas" : "Reviews")
                    .font(.headline)
                    .foregroundStyle(Color.encoreText)
                if !reviews.isEmpty {
                    Text("(\(reviews.count))")
                        .font(.subheadline)
                        .foregroundStyle(Color.encoreTextSecondary)
                }
                Spacer()
                if !reviews.isEmpty {
                    NavigationLink(destination: ReviewsListView(instrument: instrument)) {
                        Text(language.sp ? "Ver todas" : "See all")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.encorePrimary)
                    }
                }
            }

            if reviewsLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else if reviews.isEmpty {
                Text(language.sp ? "Aún no hay reseñas." : "No reviews yet.")
                    .font(.subheadline)
                    .foregroundStyle(Color.encoreTextSecondary)
                    .frame(maxWidth: .infinity, minHeight: 40)
            } else {
                // Average + star bar summary
                let avg = Double(reviews.map(\.rating).reduce(0, +)) / Double(reviews.count)
                let counts = Dictionary(grouping: reviews, by: { $0.rating }).mapValues { $0.count }

                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 2) {
                        Text(String(format: "%.1f", avg))
                            .font(.system(size: 34, weight: .black))
                            .foregroundStyle(Color.encoreText)
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { i in
                                Image(systemName: i <= Int(avg.rounded()) ? "star.fill" : "star")
                                    .font(.caption2)
                                    .foregroundStyle(Color.encorePrimary)
                            }
                        }
                        Text("\(reviews.count) \(language.sp ? "reseñas" : "reviews")")
                            .font(.caption2)
                            .foregroundStyle(Color.encoreTextSecondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        ForEach((1...5).reversed(), id: \.self) { star in
                            HStack(spacing: 6) {
                                Text("\(star)")
                                    .font(.caption2)
                                    .foregroundStyle(Color.encoreTextSecondary)
                                    .frame(width: 8)
                                GeometryReader { g in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Color(.systemGray5))
                                        Capsule()
                                            .fill(Color.encorePrimary)
                                            .frame(width: g.size.width * (reviews.count > 0 ? CGFloat(counts[star] ?? 0) / CGFloat(reviews.count) : 0))
                                    }
                                }
                                .frame(height: 7)
                            }
                        }
                    }
                }
                .padding(14)
                .background(Color(.systemGray6))
                .cornerRadius(14)

                // First 3 reviews inline
                ForEach(reviews.prefix(3)) { review in
                    ReviewCard(
                        review: review,
                        language: language,
                        currentUserId: auth.session?.userId,
                        onEdit: { newRating, newComment in
                            if let idx = reviews.firstIndex(where: { $0.id == review.id }) {
                                reviews[idx].rating  = newRating
                                reviews[idx].comment = newComment.isEmpty ? nil : newComment
                            }
                            Task {
                                try? await SupabaseClient.shared.update(
                                    table: "reviews", id: review.id,
                                    body: ["rating": newRating, "comment": newComment.isEmpty ? NSNull() : newComment]
                                )
                            }
                        }
                    )
                }

                // "See all" footer if there are more
                if reviews.count > 3 {
                    NavigationLink(destination: ReviewsListView(instrument: instrument)) {
                        Text(language.sp ? "Ver las \(reviews.count) reseñas →" : "See all \(reviews.count) reviews →")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.encorePrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.encorePrimary.opacity(0.1))
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal)
    }

    private func loadReviews() {
        reviewsLoading = true
        Task {
            do {
                let list: [Review] = try await SupabaseClient.shared.fetch(
                    table: "reviews",
                    query: [
                        URLQueryItem(name: "select", value: "*,users!renter_id(avatar_url)"),
                        URLQueryItem(name: "instrument_id", value: "eq.\(instrument.id.uuidString)")
                    ]
                )
                await MainActor.run {
                    reviews = list.sorted { ($0.createdAt ?? "") > ($1.createdAt ?? "") }
                    reviewsLoading = false
                }
            } catch {
                await MainActor.run { reviewsLoading = false }
            }
        }
    }

    private func priceString(_ value: Decimal) -> String {
        "₡\(NSDecimalNumber(decimal: value).intValue)"
    }

    private func setRegion() {
        if let lat = instrument.latitude, let lon = instrument.longitude {
            mapRegion = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            hasValidRegion = true
        }
    }
}

// MARK: - Full-screen conversation (replaces deprecated NavigationLink isActive)
private enum ConversationSheetItem: Identifiable {
    case existing(Conversation, AppUser?)
    case pending(hostId: UUID, hostUser: AppUser?, instrument: Instrument)

    var id: UUID {
        switch self {
        case .existing(let c, _): return c.id
        case .pending(_, _, let inst): return inst.id
        }
    }
}
