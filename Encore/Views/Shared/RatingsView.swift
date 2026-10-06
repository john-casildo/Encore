//
//  RatingsView.swift
//  Encore
//

import SwiftUI

struct RatingsView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var language: LanguageManager
    @Environment(\.dismiss) private var dismiss
    let rental: Rental

    @State private var rating = 5
    @State private var comment = ""
    @State private var isSubmitting = false
    @State private var alreadyReviewed = false
    @State private var errorMessage: String?
    @State private var toast: Toast?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Instrument header card
                HStack(spacing: 14) {
                    RemoteImage(
                        url: rental.instrumentImageUrl,
                        emojiFallback: rental.instrumentEmoji ?? "🎸",
                        storageBucket: nil
                    )
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary, lineWidth: 1.5))
                    .memphisShadow(x: 2, y: 2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(rental.instrumentName ?? "—")
                            .font(.headline.weight(.black))
                            .foregroundStyle(Color.encoreText)
                        Text(String.formattedRange(start: rental.startDate, end: rental.endDate))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.encoreTextSecondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(14)
                .memphisCard(cornerRadius: 14, offset: 3, lineWidth: 1.5)

                if alreadyReviewed {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.encoreGreen)
                        Text(language.sp ? "Ya enviaste una reseña para esta reserva." : "You already reviewed this booking.")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.encoreText)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.encoreGreen.opacity(0.12))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.encoreGreen, lineWidth: 1.5))
                } else {
                    // Star rating
                    VStack(alignment: .leading, spacing: 10) {
                        Text(Strings.writeReview(language.sp))
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
                                            .frame(width: 44, height: 44)
                                            .overlay(Circle().stroke(Color.primary, lineWidth: 1.5))
                                            .shadow(
                                                color: star <= rating ? (colorScheme == .dark ? .clear : .black) : .clear,
                                                radius: 0, x: 2, y: 2
                                            )
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 18, weight: .bold))
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

                    // Comment field
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Strings.comment(language.sp))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.encoreText)
                        TextField(language.sp ? "Escribe tu opinión…" : "Write your review…", text: $comment, axis: .vertical)
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
            }
            .padding()
        }
        .toast($toast)
        .navigationTitle(Strings.reviews(language.sp))
        .navigationBarTitleDisplayMode(.inline)
        .task { await checkAlreadyReviewed() }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if isSubmitting {
                    ProgressView()
                } else {
                    Button(Strings.submitReview(language.sp)) { submitReview() }
                        .disabled(alreadyReviewed)
                }
            }
        }
    }

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

    private func checkAlreadyReviewed() async {
        guard let renterId = auth.session?.userId else { return }
        do {
            let list: [Review] = try await SupabaseClient.shared.fetch(
                table: "reviews",
                query: [
                    URLQueryItem(name: "rental_id", value: "eq.\(rental.id.uuidString)"),
                    URLQueryItem(name: "renter_id", value: "eq.\(renterId.uuidString)")
                ]
            )
            await MainActor.run { alreadyReviewed = !list.isEmpty }
        } catch {
            print("[RatingsView] checkAlreadyReviewed failed: \(error)")
        }
    }

    private func submitReview() {
        guard let renterId = auth.session?.userId else { return }
        errorMessage = nil
        isSubmitting = true
        let reviewerName = auth.currentUser?.displayName ?? "—"
        let body: [String: Any] = [
            "rental_id": rental.id.uuidString,
            "instrument_id": rental.instrumentId.uuidString,
            "renter_id": renterId.uuidString,
            "rating": rating,
            "comment": comment.isEmpty ? NSNull() : comment,
            "reviewer_name": reviewerName,
            "reviewer_avatar_url": auth.currentUser?.avatarUrl ?? NSNull()
        ]
        Task {
            do {
                _ = try await SupabaseClient.shared.insert(table: "reviews", body: body)
                try await SupabaseClient.shared.update(
                    table: "rentals",
                    id: rental.id,
                    body: ["has_been_reviewed": true]
                )
                await MainActor.run {
                    isSubmitting = false
                    toast = Toast(message: language.sp ? "Reseña enviada" : "Review submitted")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSubmitting = false
                }
            }
        }
    }
}
