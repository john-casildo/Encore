//
//  HostDashboardView.swift
//  Encore
//

import SwiftUI

struct HostDashboardView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var language: LanguageManager
    @State private var rentals: [Rental] = []
    @State private var isLoading = true

    private var totalEarnings: Decimal {
        rentals.filter { $0.status == .completed }.map(\.totalPrice).reduce(0, +)
    }

    private var pendingCount: Int {
        rentals.filter { $0.status == .pending }.count
    }

    private var recentRentals: [Rental] {
        Array(rentals.prefix(5))
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView(Strings.loading(language.sp))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        earningsCard
                        pendingCard
                        recentSection
                        payoutButton
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(Strings.dashboard(language.sp))
        .onAppear { loadRentals() }
    }

    private var earningsCard: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.encorePrimary)

            // Memphis decorative shapes
            GeometryReader { geo in
                ZStack {
                    Circle()
                        .fill(Color.encoreAccent.opacity(0.55))
                        .frame(width: 80, height: 80)
                        .position(x: geo.size.width - 30, y: 32)
                    Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 46, height: 46)
                        .position(x: geo.size.width - 90, y: geo.size.height - 14)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.encorePink.opacity(0.4))
                        .frame(width: 22, height: 22)
                        .rotationEffect(.degrees(18))
                        .position(x: geo.size.width - 130, y: 20)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))

            VStack(alignment: .leading, spacing: 6) {
                Text(language.sp ? "Este mes" : "This Month")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.75))
                Text("₡\(NSDecimalNumber(decimal: totalEarnings).intValue)")
                    .font(.system(size: 40, weight: .black))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(Strings.earnings(language.sp))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .frame(height: 140)
        .memphisCard(cornerRadius: 20, offset: 4, lineWidth: 2)
    }

    private var pendingCard: some View {
        NavigationLink(destination: HostBookingsView()) {
            HStack {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(pendingCount > 0 ? Color.encoreAccent : Color(.systemGray5))
                            .frame(width: 48, height: 48)
                            .overlay(Circle().stroke(Color.primary, lineWidth: 2))
                        Text("\(pendingCount)")
                            .font(.title3.bold())
                            .foregroundStyle(pendingCount > 0 ? .black : Color.encoreTextSecondary)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Strings.pending(language.sp))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.encoreText)
                        Text(language.sp ? "Reservas por revisar" : "Bookings to review")
                            .font(.caption)
                            .foregroundStyle(Color.encoreTextSecondary)
                    }
                }
                Spacer()
                if pendingCount > 0 {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.encorePrimary)
                }
            }
            .padding(16)
            .background(Color.encoreLightPurple)
            .cornerRadius(16)
            .memphisCard(cornerRadius: 16, offset: 3, lineWidth: 1.5)
        }
        .buttonStyle(.plain)
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(language.sp ? "Actividad reciente" : "Recent activity")
                .font(.title3.bold())
                .foregroundStyle(Color.encoreText)
            if recentRentals.isEmpty {
                Text(language.sp ? "Sin reservas aún." : "No bookings yet.")
                    .font(.subheadline)
                    .foregroundStyle(Color.encoreTextSecondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(recentRentals) { rental in
                    HStack(spacing: 12) {
                        RemoteImage(
                            url: rental.instrumentImageUrl,
                            emojiFallback: rental.instrumentEmoji ?? "🎸",
                            storageBucket: nil
                        )
                        .frame(width: 38, height: 38)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.primary, lineWidth: 1.5))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(rental.instrumentName ?? "—")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.encoreText)
                            Text(statusLabel(rental.status))
                                .font(.caption)
                                .foregroundStyle(Color.encoreTextSecondary)
                        }
                        Spacer()
                        Text("₡\(NSDecimalNumber(decimal: rental.totalPrice).intValue)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.encorePrimary)
                    }
                    .padding(.vertical, 4)
                    if rental.id != recentRentals.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .memphisCard(cornerRadius: 16, offset: 3, lineWidth: 1.5)
    }

    private var payoutButton: some View {
        Button(action: {}) {
            HStack {
                Text(language.sp ? "Solicitar pago" : "Request Payout")
                    .font(.headline.bold())
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.headline.bold())
            }
            .foregroundStyle(.white)
            .padding(18)
            .background(Color.encorePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .memphisCard(cornerRadius: 16, offset: 4, lineWidth: 2)
        }
        .buttonStyle(.plain)
    }

    private func statusLabel(_ status: RentalStatus) -> String {
        switch status {
        case .pending: return language.sp ? "Pend." : "Pending"
        case .confirmed: return language.sp ? "Conf." : "Confirmed"
        case .active: return language.sp ? "Activo" : "Active"
        case .completed: return language.sp ? "Hecho" : "Done"
        case .cancelled: return language.sp ? "Cancel." : "Cancelled"
        }
    }

    private func loadRentals() {
        guard let hostId = auth.session?.userId else {
            rentals = []
            isLoading = false
            return
        }
        isLoading = true
        Task {
            do {
                let list: [Rental] = try await SupabaseClient.shared.fetch(
                    table: "rentals",
                    query: [
                        URLQueryItem(name: "host_id", value: "eq.\(hostId.uuidString)"),
                        URLQueryItem(name: "select", value: "*,instruments(image_urls)")
                    ]
                )
                await MainActor.run {
                    rentals = list.sorted { ($0.createdAt ?? "") > ($1.createdAt ?? "") }
                    isLoading = false
                }
            } catch {
                print("[HostDashboardView] load failed: \(error)")
                await MainActor.run {
                    rentals = []
                    isLoading = false
                }
            }
        }
    }
}
