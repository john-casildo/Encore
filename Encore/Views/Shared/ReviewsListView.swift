//
//  ReviewsListView.swift
//  Encore
//

import SwiftUI

struct ReviewsListView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var language: LanguageManager
    let instrument: Instrument

    @State private var reviews: [Review] = []
    @State private var isLoading = true
    @State private var replyingReviewId: UUID?
    @State private var replyDraft = ""
    @State private var isSavingReply = false
    @State private var replyError: String?
    @State private var toast: Toast?

    private var isHost: Bool { auth.currentUser?.id == instrument.hostId }

    private var ratingSummary: (avg: Double, counts: [Int: Int]) {
        let counts = Dictionary(grouping: reviews, by: { $0.rating })
            .mapValues { $0.count }
        let total = reviews.count
        let avg = total > 0 ? Double(reviews.map(\.rating).reduce(0, +)) / Double(total) : 0
        return (avg, counts)
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView(Strings.loading(language.sp))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if reviews.isEmpty {
                Text(language.sp ? "Aún no hay reseñas." : "No reviews yet.")
                    .foregroundStyle(Color.encoreTextSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        summarySection
                        ForEach(reviews) { review in
                            VStack(alignment: .leading, spacing: 8) {
                                ReviewCard(
                                    review: review,
                                    language: language,
                                    currentUserId: auth.session?.userId,
                                    onEdit: { newRating, newComment in
                                        updateReview(review, rating: newRating, comment: newComment)
                                    }
                                )
                                if isHost && (review.hostReply ?? "").isEmpty {
                                    Button {
                                        replyingReviewId = review.id
                                        replyDraft = ""
                                    } label: {
                                        Text(Strings.reply(language.sp))
                                            .font(.caption)
                                            .foregroundStyle(Color.encorePrimary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding()
                }
                .sheet(item: Binding(
                    get: { replyingReviewId.map { ReplySheetItem(id: $0) } },
                    set: { replyingReviewId = $0?.id }
                )) { item in
                    replySheetContent(reviewId: item.id)
                }
            }
        }
        .navigationTitle(Strings.reviews(language.sp))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadReviews() }
        .toast($toast)
    }

    private var summarySection: some View {
        let (avg, counts) = ratingSummary
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", avg))
                        .font(.system(size: 40, weight: .black))
                        .foregroundStyle(Color.encoreText)
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: Double(i) <= avg ? "star.fill" : (Double(i) - 0.5 <= avg ? "star.leadinghalf.filled" : "star"))
                                .font(.caption2)
                                .foregroundStyle(Color.encoreAccent)
                        }
                    }
                    Text("\(reviews.count) \(Strings.reviews(language.sp))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.encoreTextSecondary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    ForEach([5, 4, 3, 2, 1], id: \.self) { star in
                        HStack(spacing: 8) {
                            Text("\(star)")
                                .font(.caption.weight(.bold))
                                .frame(width: 12, alignment: .leading)
                                .foregroundStyle(Color.encoreText)
                            GeometryReader { g in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.encoreLightPurple)
                                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.encoreAccent)
                                        .frame(width: max(g.size.width * barFraction(star, counts), barFraction(star, counts) > 0 ? 6 : 0))
                                }
                            }
                            .frame(height: 8)
                            Text("\(counts[star] ?? 0)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.encoreTextSecondary)
                                .frame(width: 20, alignment: .trailing)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .memphisCard(cornerRadius: 14, offset: 3, lineWidth: 1.5)
        }
    }

    private func barFraction(_ star: Int, _ counts: [Int: Int]) -> CGFloat {
        let total = reviews.count
        guard total > 0 else { return 0 }
        return CGFloat(counts[star] ?? 0) / CGFloat(total)
    }

    private func loadReviews() {
        isLoading = true
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
                    isLoading = false
                }
            } catch {
                print("[ReviewsListView] load failed: \(error)")
                await MainActor.run {
                    reviews = []
                    isLoading = false
                }
            }
        }
    }

    @ViewBuilder
    private func replySheetContent(reviewId: UUID) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                TextField(Strings.comment(language.sp), text: $replyDraft, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
                if let err = replyError {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                Spacer()
            }
            .padding()
            .navigationTitle(Strings.addReply(language.sp))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.cancel(language.sp)) {
                        replyingReviewId = nil
                        replyError = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.save(language.sp)) {
                        submitReply(reviewId: reviewId)
                    }
                    .disabled(replyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSavingReply)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func updateReview(_ review: Review, rating: Int, comment: String) {
        if let idx = reviews.firstIndex(where: { $0.id == review.id }) {
            reviews[idx].rating  = rating
            reviews[idx].comment = comment.isEmpty ? nil : comment
        }
        Task {
            do {
                try await SupabaseClient.shared.update(
                    table: "reviews", id: review.id,
                    body: ["rating": rating, "comment": comment.isEmpty ? NSNull() : comment]
                )
                await MainActor.run {
                    toast = Toast(message: language.sp ? "Reseña actualizada" : "Review updated")
                }
            } catch {
                await MainActor.run { loadReviews() }
            }
        }
    }

    private func submitReply(reviewId: UUID) {
        let text = replyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        isSavingReply = true
        replyError = nil
        Task {
            do {
                try await SupabaseClient.shared.update(table: "reviews", id: reviewId, body: ["host_reply": text])
                await MainActor.run {
                    isSavingReply = false
                    replyingReviewId = nil
                    replyDraft = ""
                    toast = Toast(message: language.sp ? "Respuesta enviada" : "Reply sent")
                    loadReviews()
                }
            } catch {
                await MainActor.run {
                    isSavingReply = false
                    replyError = error.localizedDescription
                }
            }
        }
    }
}

// Wrapper for sheet(item:) so we can pass a UUID.
private struct ReplySheetItem: Identifiable {
    let id: UUID
}

// MARK: - Review card

struct ReviewCard: View {
    let review: Review
    let language: LanguageManager
    var currentUserId: UUID? = nil
    var onEdit: ((Int, String) -> Void)? = nil

    @State private var showEditSheet = false
    @State private var editRating: Int = 5
    @State private var editComment: String = ""
    @State private var isSaving = false
    @Environment(\.colorScheme) private var colorScheme

    private var isOwner: Bool { currentUserId == review.renterId }
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
                VStack(alignment: .leading, spacing: 3) {
                    Text(review.reviewerName ?? "—")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.encoreText)
                    HStack(spacing: 3) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= review.rating ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundStyle(i <= review.rating ? Color.encoreAccent : Color.encoreTextSecondary)
                        }
                        if let created = review.createdAt {
                            Text("· \(String(created.prefix(10)).formattedDate())")
                                .font(.caption)
                                .foregroundStyle(Color.encoreTextSecondary)
                        }
                    }
                }
                Spacer()
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

            if let comment = review.comment, !comment.isEmpty {
                Text(comment)
                    .font(.subheadline)
                    .foregroundStyle(Color.encoreText)
            }

            if let reply = review.hostReply, !reply.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrowshape.turn.up.left.fill")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.encorePrimary)
                        Text(language.sp ? "Respuesta del anfitrión" : "Host response")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.encorePrimary)
                    }
                    Text(reply)
                        .font(.caption)
                        .foregroundStyle(Color.encoreText)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.encoreLightPurple)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.encorePrimary.opacity(0.3), lineWidth: 1))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .memphisCard(cornerRadius: 14, offset: 3, lineWidth: 1.5)
        .sheet(isPresented: $showEditSheet) {
            editSheet
        }
    }

    private var editSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Stars
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
                    // Comment
                    VStack(alignment: .leading, spacing: 8) {
                        Text(language.sp ? "Comentario" : "Comment")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.encoreText)
                        TextField(language.sp ? "Escribe tu opinión…" : "Write your review…",
                                  text: $editComment, axis: .vertical)
                            .lineLimit(4...8)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .memphisCard(cornerRadius: 12, offset: 3, lineWidth: 1.5)
                    }

                    // 48h notice
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
                    if isSaving {
                        ProgressView()
                    } else {
                        Button(language.sp ? "Guardar" : "Save") {
                            isSaving = true
                            onEdit?(editRating, editComment)
                            showEditSheet = false
                            isSaving = false
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
