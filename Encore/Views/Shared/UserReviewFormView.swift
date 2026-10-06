//
//  UserReviewFormView.swift
//  Encore
//
//  Shared form used for:
//    - Renter reviewing a Host  (reviewerRole = "renter")
//    - Host reviewing a Renter  (reviewerRole = "host")
//

import SwiftUI

struct UserReviewFormView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var language: LanguageManager
    @Environment(\.dismiss) private var dismiss

    let rental: Rental
    let revieweeId: UUID
    let revieweeName: String
    let reviewerRole: String     // "renter" | "host"
    var onSubmitted: (() -> Void)?

    @State private var rating = 5
    @State private var comment = ""
    @State private var isSubmitting = false
    @State private var alreadyReviewed = false
    @State private var errorMessage: String?
    @State private var loadedReviewee: AppUser?

    private var displayName: String {
        loadedReviewee?.displayName ?? revieweeName
    }

    private var subjectLabel: String {
        if reviewerRole == "renter" {
            return language.sp ? "Anfitrión" : "Host"
        } else {
            return language.sp ? "Arrendatario" : "Renter"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Who is being reviewed
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.encoreLightPurple)
                                .frame(width: 56, height: 56)
                                .overlay(Circle().stroke(Color.primary, lineWidth: 1.5))
                            ProfileAvatarView(url: loadedReviewee?.avatarUrl, size: 52)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(displayName)
                                .font(.headline.weight(.black))
                                .foregroundStyle(Color.encoreText)
                            Text(subjectLabel)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(reviewerRole == "renter" ? Color.encorePrimary : Color.encoreGreen)
                                .clipShape(Capsule())
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(14)
                    .memphisCard(cornerRadius: 14, offset: 3, lineWidth: 1.5)

                    // Star picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text(language.sp ? "Calificación" : "Rating")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.encoreText)
                        HStack(spacing: 10) {
                            ForEach(1...5, id: \.self) { star in
                                Button {
                                    withAnimation(.spring(response: 0.2)) { rating = star }
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(star <= rating ? Color.encoreAccent : Color(.systemBackground))
                                            .frame(width: 48, height: 48)
                                            .overlay(Circle().stroke(Color.primary, lineWidth: 1.5))
                                            .memphisShadow(x: star <= rating ? 2 : 0, y: star <= rating ? 2 : 0)
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundStyle(star <= rating ? Color.encoreText : Color.encoreTextSecondary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        Text(ratingLabel)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.encorePrimary)
                    }

                    // Comment
                    VStack(alignment: .leading, spacing: 8) {
                        Text(language.sp ? "Comentario (opcional)" : "Comment (optional)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.encoreText)
                        TextField(
                            language.sp ? "Comparte tu experiencia…" : "Share your experience…",
                            text: $comment,
                            axis: .vertical
                        )
                        .lineLimit(4...8)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .memphisCard(cornerRadius: 12, offset: 3, lineWidth: 1.5)
                    }

                    if let err = errorMessage {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
            }
            .navigationTitle(language.sp ? "Escribir reseña" : "Write a Review")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadReviewee()
                await checkAlreadyReviewed()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language.sp ? "Cancelar" : "Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(language.sp ? "Publicar" : "Submit") {
                        Task { await submitReview() }
                    }
                    .fontWeight(.semibold)
                    .disabled(isSubmitting || alreadyReviewed)
                }
            }
            .overlay {
                if isSubmitting {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.15))
                }
            }
        }
    }

    // MARK: - Helpers

    private var ratingLabel: String {
        switch rating {
        case 1: return language.sp ? "Muy malo" : "Very bad"
        case 2: return language.sp ? "Malo" : "Poor"
        case 3: return language.sp ? "Aceptable" : "Okay"
        case 4: return language.sp ? "Bueno" : "Good"
        case 5: return language.sp ? "Excelente" : "Excellent"
        default: return ""
        }
    }

    // MARK: - Data

    private func loadReviewee() async {
        do {
            let list: [AppUser] = try await SupabaseClient.shared.fetch(
                table: "users",
                query: [
                    URLQueryItem(name: "select", value: "id,name,last_name,avatar_url"),
                    URLQueryItem(name: "id", value: "eq.\(revieweeId.uuidString)")
                ]
            )
            await MainActor.run { loadedReviewee = list.first }
        } catch {
            print("[UserReviewFormView] load reviewee failed: \(error)")
        }
    }

    // MARK: - Submit

    private func checkAlreadyReviewed() async {
        guard let reviewerId = auth.session?.userId else { return }
        do {
            let list: [UserReview] = try await SupabaseClient.shared.fetch(
                table: "user_reviews",
                query: [
                    URLQueryItem(name: "rental_id", value: "eq.\(rental.id.uuidString)"),
                    URLQueryItem(name: "reviewer_id", value: "eq.\(reviewerId.uuidString)"),
                    URLQueryItem(name: "reviewer_role", value: "eq.\(reviewerRole)")
                ]
            )
            await MainActor.run { alreadyReviewed = !list.isEmpty }
        } catch {}
    }

    private func submitReview() async {
        guard let reviewerId = auth.session?.userId else { return }
        await MainActor.run { errorMessage = nil; isSubmitting = true }

        let body: [String: Any] = [
            "rental_id":           rental.id.uuidString,
            "reviewer_id":         reviewerId.uuidString,
            "reviewee_id":         revieweeId.uuidString,
            "reviewer_role":       reviewerRole,
            "rating":              rating,
            "comment":             comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                       ? NSNull()
                                       : comment.trimmingCharacters(in: .whitespacesAndNewlines),
            "reviewer_name":       auth.currentUser?.displayName ?? "—",
            "reviewer_avatar_url": auth.currentUser?.avatarUrl ?? NSNull()
        ]

        do {
            _ = try await SupabaseClient.shared.insert(table: "user_reviews", body: body)
            await MainActor.run {
                isSubmitting = false
                onSubmitted?()
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isSubmitting = false
            }
        }
    }
}
