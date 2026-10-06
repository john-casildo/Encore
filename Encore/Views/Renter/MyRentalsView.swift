//
//  MyRentalsView.swift
//  Encore
//

import SwiftUI

struct MyRentalsView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var language: LanguageManager
    @State private var rentals: [Rental] = []
    @State private var isLoading = true
    @State private var activeTab = 0              // 0 = Active, 1 = History
    @State private var reviewedHostRentalIds: Set<UUID> = []
    @State private var toast: Toast?

    private var activeRentals: [Rental] {
        rentals.filter { [.pending, .confirmed, .active].contains($0.status) }
    }

    private var historyRentals: [Rental] {
        rentals.filter { [.completed, .cancelled].contains($0.status) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    tabButton(0, title: Strings.active(language.sp))
                    tabButton(1, title: Strings.history(language.sp))
                }
                .padding(4)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)

                if isLoading {
                    ProgressView(Strings.loading(language.sp))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    let list = activeTab == 0 ? activeRentals : historyRentals
                    if list.isEmpty {
                        if activeTab == 0 {
                            MemphisEmptyView(
                                icon: "calendar",
                                circleColor: Color.encorePrimary,
                                accentColor: Color.encoreAccent,
                                secondAccent: Color.encorePink,
                                title: language.sp ? "Sin reservas activas" : "No active rentals",
                                subtitle: language.sp
                                    ? "Tus reservas confirmadas aparecerán aquí."
                                    : "Your confirmed bookings will appear here."
                            )
                        } else {
                            MemphisEmptyView(
                                icon: "clock.fill",
                                circleColor: Color.encoreOrange,
                                accentColor: Color.encoreAccent,
                                secondAccent: Color.encorePrimary,
                                title: language.sp ? "Sin historial aún" : "No history yet",
                                subtitle: language.sp
                                    ? "Tus reservas completadas aparecerán aquí."
                                    : "Your completed rentals will show up here."
                            )
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(list) { rental in
                                    NavigationLink(destination: RentalDetailView(
                                        rental: rental,
                                        isHostReviewed: reviewedHostRentalIds.contains(rental.id),
                                        onHostReviewed: { reviewedHostRentalIds.insert(rental.id) },
                                        onBookingEdited: {
                                            toast = Toast(message: language.sp ? "Reserva actualizada" : "Booking updated")
                                            Task { await loadRentalsAsync() }
                                        }
                                    )
                                    .environmentObject(auth)
                                    .environmentObject(language)
                                    ) {
                                        RentalCard(
                                            rental: rental,
                                            language: language,
                                            isHostReviewed: reviewedHostRentalIds.contains(rental.id),
                                            onHostReviewed: { reviewedHostRentalIds.insert(rental.id) },
                                            onBookingEdited: {
                                                toast = Toast(message: language.sp ? "Reserva actualizada" : "Booking updated")
                                                Task { await loadRentalsAsync() }
                                            }
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding()
                        }
                        .refreshable {
                            await loadRentalsAsync()
                            await loadReviewedIdsAsync()
                        }
                    }
                }
            }
            .navigationTitle(Strings.myRentals(language.sp))
            .toast($toast)
            .onAppear {
                loadRentals()
                loadReviewedIds()
            }
        }
    }

    private func tabButton(_ tag: Int, title: String) -> some View {
        let isSelected = activeTab == tag
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { activeTab = tag }
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : Color.encoreText.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color.encorePrimary : Color(.systemBackground))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? .black : Color.clear, lineWidth: 1.5))
                .memphisShadow(x: isSelected ? 2 : 0, y: isSelected ? 2 : 0)
        }
        .buttonStyle(.plain)
    }

    private func loadRentals() {
        guard auth.session?.userId != nil else {
            rentals = []; isLoading = false; return
        }
        isLoading = true
        Task { await loadRentalsAsync() }
    }

    private func loadRentalsAsync() async {
        guard let renterId = auth.session?.userId else {
            await MainActor.run { rentals = []; isLoading = false }
            return
        }
        do {
            let list: [Rental] = try await SupabaseClient.shared.fetch(
                table: "rentals",
                query: [
                    URLQueryItem(name: "renter_id", value: "eq.\(renterId.uuidString)"),
                    URLQueryItem(name: "select", value: "*,instruments(image_urls,image_emoji)")
                ]
            )
            await MainActor.run {
                rentals = list.sorted { ($0.createdAt ?? "") > ($1.createdAt ?? "") }
                isLoading = false
            }
        } catch {
            print("[MyRentalsView] load failed: \(error)")
            await MainActor.run { rentals = []; isLoading = false }
        }
    }

    // Load rental IDs where this renter already reviewed the host
    private func loadReviewedIds() {
        Task { await loadReviewedIdsAsync() }
    }

    private func loadReviewedIdsAsync() async {
        guard let uid = auth.session?.userId else { return }
        do {
            let list: [UserReview] = try await SupabaseClient.shared.fetch(
                table: "user_reviews",
                query: [
                    URLQueryItem(name: "reviewer_id", value: "eq.\(uid.uuidString)"),
                    URLQueryItem(name: "reviewer_role", value: "eq.renter")
                ]
            )
            await MainActor.run {
                reviewedHostRentalIds = Set(list.map(\.rentalId))
            }
        } catch {
            print("[MyRentalsView] loadReviewedIds failed: \(error)")
        }
    }
}

// MARK: - Rental card (tappable summary – tap to see full details)

struct RentalCard: View {
    let rental: Rental
    let language: LanguageManager
    var isHostReviewed: Bool = false
    var onHostReviewed: (() -> Void)?
    var onBookingEdited: (() -> Void)?

    var body: some View {
        HStack {
            RemoteImage(url: rental.instrumentImageUrl, emojiFallback: rental.instrumentEmoji ?? "🎸", storageBucket: .instruments)
                .frame(width: 56, height: 56)
                .cornerRadius(8)
            VStack(alignment: .leading, spacing: 4) {
                Text(rental.instrumentName ?? "—")
                    .font(.headline)
                    .foregroundStyle(Color.encoreText)
                Text(String.formattedRange(start: rental.startDate, end: rental.endDate))
                    .font(.caption)
                    .foregroundStyle(Color.encoreTextSecondary)
                statusBadge(rental.status)
            }
            Spacer()
            Text("₡\(NSDecimalNumber(decimal: rental.totalPrice).intValue)")
                .font(.subheadline.bold())
                .foregroundStyle(Color.encoreText)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.encoreTextSecondary)
        }
        .padding()
        .background(Color.encoreBackground)
        .cornerRadius(16)
        .memphisCard(cornerRadius: 16, offset: 3, lineWidth: 1.5)
    }

    private func statusBadge(_ status: RentalStatus) -> some View {
        Text(statusLabel(status))
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor(status))
            .cornerRadius(6)
    }

    private func statusLabel(_ status: RentalStatus) -> String {
        switch status {
        case .pending:   return language.sp ? "Pendiente"  : "Pending"
        case .confirmed: return language.sp ? "Confirmado" : "Confirmed"
        case .active:    return language.sp ? "Activo"     : "Active"
        case .completed: return language.sp ? "Completado" : "Completed"
        case .cancelled: return language.sp ? "Cancelado"  : "Cancelled"
        }
    }

    private func statusColor(_ status: RentalStatus) -> Color {
        switch status {
        case .pending:   return Color.encoreOrange
        case .confirmed: return .blue
        case .active:    return .green
        case .completed: return Color.encoreTextSecondary
        case .cancelled: return .red
        }
    }
}
