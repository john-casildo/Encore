//
//  RentalDetailView.swift
//  Encore
//

import SwiftUI

struct RentalDetailView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var language: LanguageManager
    let rental: Rental
    var isHostReviewed: Bool = false
    var onHostReviewed: (() -> Void)?
    var onBookingEdited: (() -> Void)?

    @State private var showHostReviewSheet = false
    @State private var showEditRental = false
    @State private var showCancelConfirm = false
    @State private var isCancelling = false
    @State private var hostUser: AppUser?
    @State private var toast: Toast?
    @Environment(\.dismiss) private var dismiss

    private var numberOfDays: Int {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = TimeZone(identifier: "UTC")
        guard let s = fmt.date(from: rental.startDate),
              let e = fmt.date(from: rental.endDate) else { return 1 }
        return max(1, Calendar.current.dateComponents([.day], from: s, to: e).day ?? 1)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Instrument header
                HStack(spacing: 16) {
                    RemoteImage(url: rental.instrumentImageUrl, emojiFallback: rental.instrumentEmoji ?? "🎸", storageBucket: .instruments)
                        .frame(width: 72, height: 72)
                        .cornerRadius(12)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(rental.instrumentName ?? "—")
                            .font(.title3.weight(.black))
                            .foregroundStyle(Color.encoreText)
                        statusBadge(rental.status)
                    }
                    Spacer()
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .memphisCard(cornerRadius: 16, offset: 3, lineWidth: 1.5)

                // Dates
                detailRow(icon: "calendar", title: language.sp ? "Fechas" : "Dates", value: "\(String.formattedRange(start: rental.startDate, end: rental.endDate)) · \(numberOfDays) \(language.sp ? "días" : "days")")

                // Pickup
                detailRow(icon: pickupIcon, title: language.sp ? "Entrega" : "Pickup", value: pickupLabel)

                // Host (if loaded)
                if let host = hostUser {
                    detailRow(icon: "person.crop.circle", title: language.sp ? "Anfitrión" : "Host", value: host.displayName)
                }

                // Price breakdown
                VStack(alignment: .leading, spacing: 12) {
                    Text(language.sp ? "Desglose" : "Breakdown")
                        .font(.headline.weight(.black))
                        .foregroundStyle(Color.encoreText)
                    HStack {
                        Text("\(numberOfDays) \(language.sp ? "días" : "days") × \(language.sp ? "precio" : "price")")
                            .foregroundStyle(Color.encoreTextSecondary)
                        Spacer()
                        Text("₡\(NSDecimalNumber(decimal: rental.totalPrice - rental.depositAmount).intValue)")
                            .foregroundStyle(Color.encoreText)
                    }
                    .font(.subheadline)
                    HStack {
                        Text(language.sp ? "Depósito reembolsable" : "Refundable deposit")
                            .foregroundStyle(Color.encoreTextSecondary)
                        Spacer()
                        Text("₡\(NSDecimalNumber(decimal: rental.depositAmount).intValue)")
                            .foregroundStyle(Color.encoreText)
                    }
                    .font(.subheadline)
                    Divider()
                    HStack {
                        Text(language.sp ? "Total" : "Total")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color.encoreText)
                        Spacer()
                        Text("₡\(NSDecimalNumber(decimal: rental.totalPrice).intValue)")
                            .font(.headline.weight(.black))
                            .foregroundStyle(Color.encorePrimary)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .memphisCard(cornerRadius: 16, offset: 3, lineWidth: 1.5)

                // Actions
                if rental.status == .pending {
                    Button { showEditRental = true } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil.circle.fill")
                            Text(language.sp ? "Editar reserva" : "Edit booking")
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.encorePrimary)
                        .cornerRadius(12)
                        .memphisCard(cornerRadius: 12, offset: 3, lineWidth: 1.5)
                    }
                    .buttonStyle(.plain)
                }

                if rental.status == .pending || rental.status == .confirmed {
                    Button { showCancelConfirm = true } label: {
                        HStack(spacing: 8) {
                            if isCancelling {
                                ProgressView().tint(Color.encoreCoral)
                            } else {
                                Image(systemName: "xmark.circle.fill")
                            }
                            Text(language.sp ? "Cancelar reserva" : "Cancel booking")
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(Color.encoreCoral)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.encoreCoral, lineWidth: 2))
                        .memphisShadow(x: 2, y: 2)
                    }
                    .buttonStyle(.plain)
                    .disabled(isCancelling)
                }

                if rental.status == .completed {
                    HStack(spacing: 12) {
                        if !rental.hasBeenReviewed {
                            NavigationLink(destination: RatingsView(rental: rental)) {
                                Label(Strings.rate(language.sp), systemImage: "guitar")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.encorePrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.encoreLightPurple)
                                    .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                        if !isHostReviewed {
                            Button {
                                showHostReviewSheet = true
                            } label: {
                                Label(
                                    language.sp ? "Reseñar anfitrión" : "Review Host",
                                    systemImage: "person.crop.circle.badge.checkmark"
                                )
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.encorePrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.encoreLightPurple)
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(rental.instrumentName ?? "Rental")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadHost() }
        .toast($toast)
        .confirmationDialog(
            language.sp ? "¿Cancelar esta reserva?" : "Cancel this booking?",
            isPresented: $showCancelConfirm,
            titleVisibility: .visible
        ) {
            Button(language.sp ? "Sí, cancelar" : "Yes, cancel", role: .destructive) { cancelBooking() }
            Button(language.sp ? "No, mantener" : "Keep booking", role: .cancel) {}
        } message: {
            Text(rental.status == .confirmed
                 ? (language.sp
                    ? "La reserva ya fue aprobada. El anfitrión será notificado de la cancelación."
                    : "This booking was already approved. The host will be notified of the cancellation.")
                 : (language.sp
                    ? "Se cancelará tu solicitud de reserva."
                    : "Your booking request will be cancelled."))
        }
        .sheet(isPresented: $showEditRental) {
            let fmt = DateFormatter()
            let _ = { fmt.dateFormat = "yyyy-MM-dd"; fmt.timeZone = TimeZone(identifier: "UTC") }()
            let s = fmt.date(from: rental.startDate) ?? Date()
            let e = fmt.date(from: rental.endDate) ?? Date()
            let days = max(1, Calendar.current.dateComponents([.day], from: s, to: e).day ?? 1)
            let base = rental.totalPrice - rental.depositAmount
            let perDay = days > 0 ? base / Decimal(days) : base
            NavigationStack {
                EditRentalView(rental: rental, pricePerDay: perDay, onSaved: { onBookingEdited?() })
            }
            .environmentObject(LanguageManager.shared)
        }
        .sheet(isPresented: $showHostReviewSheet) {
            UserReviewFormView(
                rental: rental,
                revieweeId: rental.hostId,
                revieweeName: language.sp ? "Anfitrión" : "Host",
                reviewerRole: "renter",
                onSubmitted: { onHostReviewed?() }
            )
            .environmentObject(AuthManager.shared)
            .environmentObject(LanguageManager.shared)
        }
    }

    private var pickupIcon: String {
        switch rental.pickupMethod {
        case .meet_up: return "person.2.fill"
        case .host_address: return "house.fill"
        case .shipping: return "shippingbox.fill"
        }
    }

    private var pickupLabel: String {
        switch rental.pickupMethod {
        case .meet_up: return language.sp ? "Encuentro" : "Meet Up"
        case .host_address: return language.sp ? "Dirección del anfitrión" : "Host's Address"
        case .shipping: return language.sp ? "Envío" : "Shipping"
        }
    }

    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Color.encorePrimary)
                .frame(width: 24, alignment: .center)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Color.encoreTextSecondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.encoreText)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .memphisCard(cornerRadius: 12, offset: 2, lineWidth: 1)
    }

    private func statusBadge(_ status: RentalStatus) -> some View {
        Text(statusLabel(status))
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(statusColor(status))
            .cornerRadius(8)
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

    private func cancelBooking() {
        isCancelling = true
        Task {
            do {
                try await SupabaseClient.shared.update(
                    table: "rentals",
                    id: rental.id,
                    body: ["status": RentalStatus.cancelled.rawValue]
                )
                await MainActor.run {
                    isCancelling = false
                    toast = Toast(message: language.sp ? "Reserva cancelada" : "Booking cancelled")
                    onBookingEdited?()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
                }
            } catch {
                await MainActor.run {
                    isCancelling = false
                    toast = Toast(message: language.sp ? "No se pudo cancelar. Inténtalo de nuevo." : "Could not cancel. Please try again.", style: .error)
                }
            }
        }
    }

    private func loadHost() {
        Task {
            do {
                let users: [AppUser] = try await SupabaseClient.shared.fetch(
                    table: "users",
                    query: [URLQueryItem(name: "id", value: "eq.\(rental.hostId.uuidString)")]
                )
                await MainActor.run { hostUser = users.first }
            } catch {
                print("[RentalDetailView] loadHost failed: \(error)")
            }
        }
    }
}
