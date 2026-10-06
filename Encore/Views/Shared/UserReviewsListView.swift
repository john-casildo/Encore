//
//  UserReviewsListView.swift
//  Encore
//
//  Shows reviews received by a user (host or renter).
//

import SwiftUI

struct UserReviewsListView: View {
    @EnvironmentObject var language: LanguageManager
    @EnvironmentObject var auth: AuthManager
    let userId: UUID
    let userName: String

    @State private var reviews: [UserReview] = []
    @State private var isLoading = true

    private var avgRating: Double {
        guard !reviews.isEmpty else { return 0 }
        return Double(reviews.map(\.rating).reduce(0, +)) / Double(reviews.count)
    }

    private var starCounts: [Int: Int] {
        Dictionary(grouping: reviews, by: { $0.rating }).mapValues { $0.count }
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView(language.sp ? "Cargando…" : "Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if reviews.isEmpty {
                MemphisEmptyView(
                    icon: "star.slash",
                    circleColor: Color.encoreAccent,
                    accentColor: Color.encorePrimary,
                    secondAccent: Color.encorePink,
                    title: language.sp ? "Aún no hay reseñas" : "No reviews yet",
                    subtitle: language.sp ? "Las reseñas recibidas aparecerán aquí." : "Reviews received will show up here."
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        summaryCard
                        ForEach(reviews) { review in
                            UserReviewCard(
                                review: review,
                                language: language,
                                currentUserId: auth.session?.userId,
                                onEdit: { newRating, newComment in
                                    updateReview(review, rating: newRating, comment: newComment)
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(language.sp ? "Reseñas" : "Reviews")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadReviews() }
    }

    // MARK: - Summary

    private var summaryCard: some View {
        HStack(alignment: .top, spacing: 20) {
            // Big average
            VStack(spacing: 6) {
                Text(String(format: "%.1f", avgRating))
                    .font(.system(size: 44, weight: .black))
                    .foregroundStyle(Color.encoreText)
                HStack(spacing: 3) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: Double(i) <= avgRating ? "star.fill" : (Double(i) - 0.5 <= avgRating ? "star.leadinghalf.filled" : "star"))
                            .font(.caption)
                            .foregroundStyle(Color.encoreAccent)
                    }
                }
                Text("\(reviews.count) \(language.sp ? "reseñas" : "reviews")")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.encoreTextSecondary)
            }

            // Bar chart per star
            VStack(alignment: .leading, spacing: 6) {
                ForEach([5, 4, 3, 2, 1], id: \.self) { star in
                    HStack(spacing: 6) {
                        Text("\(star)")
                            .font(.caption.weight(.bold))
                            .frame(width: 10, alignment: .trailing)
                            .foregroundStyle(Color.encoreText)
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3).fill(Color.encoreLightPurple)
                                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.primary, lineWidth: 1))
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.encoreAccent)
                                    .frame(width: max(g.size.width * barFraction(star), barFraction(star) > 0 ? 6 : 0))
                            }
                        }
                        .frame(height: 10)
                        Text("\(starCounts[star] ?? 0)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.encoreTextSecondary)
                            .frame(width: 20, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .memphisCard(cornerRadius: 16, offset: 4, lineWidth: 1.5)
    }

    private func barFraction(_ star: Int) -> CGFloat {
        guard !reviews.isEmpty else { return 0 }
        return CGFloat(starCounts[star] ?? 0) / CGFloat(reviews.count)
    }

    // MARK: - Update

    private func updateReview(_ review: UserReview, rating: Int, comment: String) {
        if let idx = reviews.firstIndex(where: { $0.id == review.id }) {
            reviews[idx].rating  = rating
            reviews[idx].comment = comment.isEmpty ? nil : comment
        }
        Task {
            do {
                try await SupabaseClient.shared.update(
                    table: "user_reviews", id: review.id,
                    body: ["rating": rating, "comment": comment.isEmpty ? NSNull() : comment]
                )
            } catch {
                await MainActor.run { loadReviews() }
            }
        }
    }

    // MARK: - Data

    private func loadReviews() {
        isLoading = true
        Task {
            do {
                let list: [UserReview] = try await SupabaseClient.shared.fetch(
                    table: "user_reviews",
                    query: [
                        URLQueryItem(name: "select", value: "*,users!reviewer_id(avatar_url)"),
                        URLQueryItem(name: "reviewee_id", value: "eq.\(userId.uuidString)"),
                        URLQueryItem(name: "order", value: "created_at.desc")
                    ]
                )
                await MainActor.run {
                    reviews = list
                    isLoading = false
                }
            } catch {
                print("[UserReviewsListView] load failed: \(error)")
                await MainActor.run { reviews = []; isLoading = false }
            }
        }
    }
}

// MARK: - User Review Card

struct UserReviewCard: View {
    let review: UserReview
    let language: LanguageManager
    var currentUserId: UUID? = nil
    var onEdit: ((Int, String) -> Void)? = nil

    @State private var showEditSheet = false
    @State private var editRating: Int = 5
    @State private var editComment: String = ""
    @Environment(\.colorScheme) private var colorScheme

    private var isOwner: Bool { currentUserId == review.reviewerId }
    private var canEdit: Bool {
        guard isOwner, let raw = review.createdAt else { return false }
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = fmt.date(from: raw) ?? (ISO8601DateFormatter().date(from: raw) ?? .distantPast)
        return Date().timeIntervalSince(date) < 48 * 3600
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ProfileAvatarView(url: review.reviewerAvatarUrl, size: 40)
                    .overlay(Circle().stroke(Color.primary, lineWidth: 1.5))
                VStack(alignment: .leading, spacing: 2) {
                    Text(review.reviewerName ?? "—")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.encoreText)
                    HStack(spacing: 3) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= review.rating ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundStyle(i <= review.rating ? Color.encoreAccent : Color.encoreTextSecondary)
                        }
                        if let date = review.createdAt {
                            Text("· \(String(date.prefix(10)).formattedDate())")
                                .font(.caption)
                                .foregroundStyle(Color.encoreTextSecondary)
                        }
                    }
                }
                Spacer()
                let isRenter = review.reviewerRole == "renter"
                Text(isRenter
                     ? (language.sp ? "Arrendatario" : "Renter")
                     : (language.sp ? "Anfitrión" : "Host"))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isRenter ? Color.encorePrimary : Color.encoreGreen)
                    .clipShape(Capsule())
                if canEdit {
                    Button {
                        editRating = review.rating
                        editComment = review.comment ?? ""
                        showEditSheet = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.encorePrimary)
                            .padding(8)
                            .background(Color.encoreLightPurple)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.primary, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            if let c = review.comment, !c.isEmpty {
                Text(c)
                    .font(.subheadline)
                    .foregroundStyle(Color.encoreText)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .memphisCard(cornerRadius: 12, offset: 3, lineWidth: 1.5)
        .sheet(isPresented: $showEditSheet) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(language.sp ? "Calificación" : "Rating")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.encoreText)
                            HStack(spacing: 10) {
                                ForEach(1...5, id: \.self) { star in
                                    Button {
                                        withAnimation(.spring(response: 0.2)) { editRating = star }
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .fill(star <= editRating ? Color.encoreAccent : Color(.systemBackground))
                                                .frame(width: 44, height: 44)
                                                .overlay(Circle().stroke(Color.primary, lineWidth: 1.5))
                                                .shadow(
                                                    color: star <= editRating ? (colorScheme == .dark ? .clear : .black) : .clear,
                                                    radius: 0, x: 2, y: 2
                                                )
                                            Image(systemName: "star.fill")
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundStyle(star <= editRating ? Color.encoreText : Color.encoreTextSecondary)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text(language.sp ? "Comentario" : "Comment")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.encoreText)
                            TextField(language.sp ? "Comparte tu experiencia…" : "Share your experience…",
                                      text: $editComment, axis: .vertical)
                                .lineLimit(4...8)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .memphisCard(cornerRadius: 12, offset: 3, lineWidth: 1.5)
                        }
                        HStack(spacing: 8) {
                            Image(systemName: "clock")
                                .font(.caption)
                                .foregroundStyle(Color.encoreTextSecondary)
                            Text(language.sp
                                 ? "Las reseñas solo se pueden editar dentro de las primeras 48 horas."
                                 : "Reviews can only be edited within the first 48 hours.")
                                .font(.caption)
                                .foregroundStyle(Color.encoreTextSecondary)
                        }
                    }
                    .padding()
                }
                .navigationTitle(language.sp ? "Editar reseña" : "Edit Review")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(language.sp ? "Cancelar" : "Cancel") { showEditSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(language.sp ? "Guardar" : "Save") {
                            onEdit?(editRating, editComment)
                            showEditSheet = false
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}
