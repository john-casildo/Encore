//
//  HostBookingsView.swift
//  Encore
//

import SwiftUI

struct HostBookingsView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var language: LanguageManager
    @State private var rentals: [Rental] = []
    @State private var isLoading = true
    @State private var selectedTab = 0
    @State private var reviewedRenterRentalIds: Set<UUID> = []
    @State private var toast: Toast?

    private var pending: [Rental] { rentals.filter { $0.status == .pending } }
    private var active: [Rental] { rentals.filter { [.confirmed, .active].contains($0.status) } }
    private var past: [Rental] { rentals.filter { [.completed, .cancelled].contains($0.status) } }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                tabBtn(0, Strings.pending(language.sp))
                tabBtn(1, Strings.active(language.sp))
                tabBtn(2, Strings.past(language.sp))
            }
            .padding(4)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.top, 8)

            if isLoading {
                ProgressView(Strings.loading(language.sp))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let list = selectedTab == 0 ? pending : (selectedTab == 1 ? active : past)
                if list.isEmpty {
                    switch selectedTab {
                    case 0:
                        MemphisEmptyView(
                            icon: "tray.fill",
                            circleColor: Color.encoreGreen,
                            accentColor: Color.encoreAccent,
                            secondAccent: Color.encorePrimary,
                            title: language.sp ? "Sin solicitudes pendientes" : "No pending requests",
                            subtitle: language.sp
                                ? "Las nuevas solicitudes de reserva aparecerán aquí."
                                : "New booking requests will show up here."
                        )
                    case 1:
                        MemphisEmptyView(
                            icon: "checkmark.circle.fill",
                            circleColor: Color.encoreBlue,
                            accentColor: Color.encoreAccent,
                            secondAccent: Color.encorePink,
                            title: language.sp ? "Sin reservas activas" : "No active bookings",
                            subtitle: language.sp
                                ? "Las reservas confirmadas aparecerán aquí."
                                : "Confirmed bookings will appear here."
                        )
                    default:
                        MemphisEmptyView(
                            icon: "clock.fill",
                            circleColor: Color.encoreOrange,
                            accentColor: Color.encoreAccent,
                            secondAccent: Color.encorePrimary,
                            title: language.sp ? "Sin historial aún" : "No history yet",
                            subtitle: language.sp
                                ? "Las reservas completadas aparecerán aquí."
                                : "Completed bookings will appear here."
                        )
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(list) { rental in
                                NavigationLink(destination: HostBookingDetailView(
                                    rental: rental,
                                    isRenterReviewed: reviewedRenterRentalIds.contains(rental.id),
                                    onRenterReviewed: { reviewedRenterRentalIds.insert(rental.id) },
                                    onStatusChanged: { newStatus in
                                        if let idx = rentals.firstIndex(where: { $0.id == rental.id }) {
                                            rentals[idx].status = newStatus
                                        }
                                    }
                                )
                                .environmentObject(auth)
                                .environmentObject(language)
                                ) {
                                    HostBookingCard(
                                        rental: rental,
                                        language: language,
                                        onApprove: selectedTab == 0 ? { approve(rental) } : nil,
                                        onDecline: selectedTab == 0 ? { decline(rental) } : nil,
                                        isRenterReviewed: reviewedRenterRentalIds.contains(rental.id),
                                        onRenterReviewed: { reviewedRenterRentalIds.insert(rental.id) }
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle(Strings.reservations(language.sp))
        .onAppear {
            loadBookings()
            loadReviewedIds()
        }
        .toast($toast)
    }

    private func tabBtn(_ tag: Int, _ title: String) -> some View {
        let isSelected = selectedTab == tag
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { selectedTab = tag }
        } label: {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? .white : Color.encoreText.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? Color.encorePrimary : Color(.systemBackground))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? Color.encorePrimaryDark : Color.clear, lineWidth: 1.5))
                .shadow(color: isSelected ? Color.encorePrimaryDark.opacity(0.6) : .clear, radius: 0, x: 2, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func loadBookings() {
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
                print("[HostBookingsView] load failed: \(error)")
                await MainActor.run {
                    rentals = []
                    isLoading = false
                }
            }
        }
    }

    private func loadReviewedIds() {
        Task {
            guard let uid = auth.session?.userId else { return }
            do {
                let list: [UserReview] = try await SupabaseClient.shared.fetch(
                    table: "user_reviews",
                    query: [
                        URLQueryItem(name: "reviewer_id", value: "eq.\(uid.uuidString)"),
                        URLQueryItem(name: "reviewer_role", value: "eq.host")
                    ]
                )
                await MainActor.run {
                    reviewedRenterRentalIds = Set(list.map(\.rentalId))
                }
            } catch {
                print("[HostBookingsView] loadReviewedIds failed: \(error)")
            }
        }
    }

    private func approve(_ rental: Rental) {
        updateStatus(rental, to: .confirmed, successMessage: language.sp ? "Reserva aprobada" : "Booking approved")
    }

    private func decline(_ rental: Rental) {
        updateStatus(rental, to: .cancelled, successMessage: language.sp ? "Reserva rechazada" : "Booking declined")
    }

    private func updateStatus(_ rental: Rental, to status: RentalStatus, successMessage: String) {
        guard let idx = rentals.firstIndex(where: { $0.id == rental.id }) else { return }
        let previous = rentals[idx].status
        rentals[idx].status = status
        Task {
            do {
                try await SupabaseClient.shared.update(
                    table: "rentals",
                    id: rental.id,
                    body: ["status": status.rawValue]
                )
                await MainActor.run { toast = Toast(message: successMessage) }
            } catch {
                print("[HostBookingsView] update status failed: \(error)")
                await MainActor.run { rentals[idx].status = previous }
            }
        }
    }
}

// MARK: - Host booking card

struct HostBookingCard: View {
    let rental: Rental
    let language: LanguageManager
    var onApprove: (() -> Void)?
    var onDecline: (() -> Void)?
    var isRenterReviewed: Bool = false
    var onRenterReviewed: (() -> Void)?

    @State private var showRenterReviewSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
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
                    HStack(alignment: .top) {
                        Text(rental.instrumentName ?? "—")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color.encoreText)
                            .lineLimit(1)
                        Spacer()
                        if rental.status == .pending {
                            Text("NEW")
                                .font(.caption2.weight(.black))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.encoreAccent)
                                .cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.primary, lineWidth: 1.5))
                                .memphisShadow(x: 1, y: 1)
                        } else {
                            statusBadge(rental.status)
                        }
                    }
                    Text(formattedDateRange)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.encoreTextSecondary)
                    HStack(spacing: 6) {
                        Text("₡\(NSDecimalNumber(decimal: rental.totalPrice).intValue)")
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(Color.encorePrimary)
                        if let ago = requestedAgo {
                            Text("·")
                                .foregroundStyle(Color.encoreTextSecondary)
                            Text(ago)
                                .font(.caption)
                                .foregroundStyle(Color.encoreTextSecondary)
                        }
                    }
                }
            }

            if rental.status == .pending, let approve = onApprove, let decline = onDecline {
                HStack(spacing: 10) {
                    Button { decline() } label: {
                        Text(Strings.decline(language.sp))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color(hex: "EF4444"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "EF4444"), lineWidth: 2))
                            .shadow(color: Color(hex: "EF4444"), radius: 0, x: 2, y: 2)
                    }
                    Button { approve() } label: {
                        Text(Strings.approve(language.sp))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.encorePrimary)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary, lineWidth: 1.5))
                            .memphisShadow(x: 2, y: 2)
                    }
                }
            }

            if rental.status == .completed && !isRenterReviewed {
                Button { showRenterReviewSheet = true } label: {
                    Label(
                        language.sp ? "Reseñar arrendatario" : "Review Renter",
                        systemImage: "person.crop.circle.badge.checkmark"
                    )
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.encorePrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.encoreLightPurple)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.encorePrimary, lineWidth: 1.5))
                    .memphisShadow(x: 2, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .memphisCard(cornerRadius: 16, offset: 4, lineWidth: 1.5)
        .sheet(isPresented: $showRenterReviewSheet) {
            UserReviewFormView(
                rental: rental,
                revieweeId: rental.renterId,
                revieweeName: language.sp ? "Arrendatario" : "Renter",
                reviewerRole: "host",
                onSubmitted: { onRenterReviewed?() }
            )
            .environmentObject(AuthManager.shared)
            .environmentObject(LanguageManager.shared)
        }
    }

    private var formattedDateRange: String {
        String.formattedRange(start: rental.startDate, end: rental.endDate)
    }

    private var requestedAgo: String? {
        guard let raw = rental.createdAt else { return nil }
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = fmt.date(from: raw) else { return nil }
        let diff = Int(Date().timeIntervalSince(date))
        if diff < 3600 {
            let m = max(1, diff / 60)
            return language.sp ? "hace \(m) min" : "\(m)m ago"
        } else if diff < 86400 {
            let h = diff / 3600
            return language.sp ? "hace \(h)h" : "\(h)h ago"
        } else {
            let d = diff / 86400
            return language.sp ? "hace \(d)d" : "\(d)d ago"
        }
    }

    private func statusBadge(_ status: RentalStatus) -> some View {
        let label: String = {
            switch status {
            case .pending:   return language.sp ? "Pendiente"  : "Pending"
            case .confirmed: return language.sp ? "Confirmado" : "Confirmed"
            case .active:    return language.sp ? "Activo"     : "Active"
            case .completed: return language.sp ? "Completado" : "Completed"
            case .cancelled: return language.sp ? "Cancelado"  : "Cancelled"
            }
        }()
        return Text(label)
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor(status))
            .cornerRadius(6)
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

// MARK: - Host Booking Detail View

struct HostBookingDetailView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var language: LanguageManager
    @Environment(\.dismiss) private var dismiss

    let rental: Rental
    var isRenterReviewed: Bool
    var onRenterReviewed: (() -> Void)?
    var onStatusChanged: ((RentalStatus) -> Void)?

    @State private var currentRental: Rental
    @State private var isUpdating = false
    @State private var toast: Toast?
    @State private var showRenterReviewSheet = false
    @State private var fetchedImageUrls: [String] = []

    init(rental: Rental, isRenterReviewed: Bool,
         onRenterReviewed: (() -> Void)? = nil,
         onStatusChanged: ((RentalStatus) -> Void)? = nil) {
        self.rental = rental
        self.isRenterReviewed = isRenterReviewed
        self.onRenterReviewed = onRenterReviewed
        self.onStatusChanged = onStatusChanged
        _currentRental = State(initialValue: rental)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {

                // Hero: photo + name + status
                ZStack(alignment: .bottomLeading) {
                    RemoteImage(
                        url: currentRental.instrumentImageUrl ?? fetchedImageUrls.first,
                        emojiFallback: currentRental.instrumentEmoji ?? "🎸",
                        storageBucket: nil
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()

                    // Gradient scrim
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.65)],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 200)

                    VStack(alignment: .leading, spacing: 6) {
                        statusPill(currentRental.status)
                        Text(currentRental.instrumentName ?? "—")
                            .font(.title2.weight(.black))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                    }
                    .padding(16)
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .memphisCard(cornerRadius: 20, offset: 4, lineWidth: 2)

                // Date banner
                HStack(spacing: 10) {
                    Image(systemName: "calendar")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.encorePrimary)
                    Text(String.formattedRange(start: currentRental.startDate, end: currentRental.endDate))
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(Color.encoreText)
                    Spacer()
                    let days = max(1, Calendar.current.dateComponents(
                        [.day],
                        from: {
                            let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
                            return f.date(from: currentRental.startDate) ?? Date()
                        }(),
                        to: {
                            let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
                            return f.date(from: currentRental.endDate) ?? Date()
                        }()
                    ).day ?? 1)
                    Text("\(days) \(language.sp ? "días" : "days")")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.encoreAccent)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary, lineWidth: 1.5))
                        .memphisShadow(x: 1, y: 1)
                }
                .padding(14)
                .background(Color(.systemBackground))
                .cornerRadius(14)
                .memphisCard(cornerRadius: 14, offset: 3, lineWidth: 1.5)

                // Details card
                VStack(spacing: 0) {
                    detailRow(icon: "coloncurrencysign.circle.fill",
                              label: language.sp ? "Total" : "Total",
                              value: "₡\(NSDecimalNumber(decimal: currentRental.totalPrice).intValue)",
                              valueColor: Color.encorePrimary)
                    Divider().padding(.horizontal)
                    detailRow(icon: "lock.shield.fill",
                              label: language.sp ? "Depósito" : "Deposit",
                              value: "₡\(NSDecimalNumber(decimal: currentRental.depositAmount).intValue)")
                    Divider().padding(.horizontal)
                    detailRow(icon: "arrow.triangle.swap",
                              label: language.sp ? "Entrega" : "Pickup",
                              value: pickupLabel(currentRental.pickupMethod))
                }
                .background(Color(.systemBackground))
                .cornerRadius(14)
                .memphisCard(cornerRadius: 14, offset: 3, lineWidth: 1.5)

                // Pending: decline + approve
                if currentRental.status == .pending {
                    HStack(spacing: 12) {
                        Button {
                            updateStatus(.cancelled, message: language.sp ? "Reserva rechazada" : "Booking declined")
                        } label: {
                            Text(language.sp ? "Rechazar" : "Decline")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color(hex: "EF4444"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "EF4444"), lineWidth: 2))
                                .shadow(color: Color(hex: "EF4444"), radius: 0, x: 2, y: 2)
                        }
                        .buttonStyle(.plain)
                        .disabled(isUpdating)

                        Button {
                            updateStatus(.confirmed, message: language.sp ? "Reserva aprobada" : "Booking approved")
                        } label: {
                            HStack(spacing: 6) {
                                if isUpdating { ProgressView().tint(.white) }
                                Image(systemName: "checkmark")
                                    .font(.subheadline.weight(.bold))
                                Text(language.sp ? "Aprobar" : "Approve")
                                    .font(.subheadline.weight(.bold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.encorePrimary)
                            .cornerRadius(12)
                            .memphisCard(cornerRadius: 12, offset: 3, lineWidth: 1.5)
                        }
                        .buttonStyle(.plain)
                        .disabled(isUpdating)
                    }
                }

                // Confirmed/active: mark completed
                if currentRental.status == .confirmed || currentRental.status == .active {
                    Button {
                        updateStatus(.completed, message: language.sp ? "Marcado como completado" : "Marked as completed")
                    } label: {
                        HStack(spacing: 8) {
                            if isUpdating { ProgressView().tint(.white) }
                            Image(systemName: "checkmark.seal.fill")
                            Text(language.sp ? "Marcar como completado" : "Mark as completed")
                                .font(.subheadline.weight(.bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.encoreGreen)
                        .cornerRadius(12)
                        .memphisCard(cornerRadius: 12, offset: 3, lineWidth: 1.5)
                    }
                    .buttonStyle(.plain)
                    .disabled(isUpdating)
                }

                // Completed: review renter
                if currentRental.status == .completed && !isRenterReviewed {
                    Button { showRenterReviewSheet = true } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                            Text(language.sp ? "Reseñar arrendatario" : "Review Renter")
                                .font(.subheadline.weight(.bold))
                        }
                        .foregroundStyle(Color.encorePrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.encoreLightPurple)
                        .cornerRadius(12)
                        .memphisCard(cornerRadius: 12, offset: 3, lineWidth: 1.5)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .padding(.bottom, 20)
        }
        .background(Color.encoreFrame.ignoresSafeArea())
        .navigationTitle(language.sp ? "Reserva" : "Booking")
        .navigationBarTitleDisplayMode(.inline)
        .toast($toast)
        .task {
            guard currentRental.instrumentImageUrl == nil else { return }
            if let urls: [String] = try? await {
                struct Img: Decodable { let imageUrls: [String]; enum CodingKeys: String, CodingKey { case imageUrls = "image_urls" } }
                let rows: [Img] = try await SupabaseClient.shared.fetch(
                    table: "instruments",
                    query: [URLQueryItem(name: "id", value: "eq.\(currentRental.instrumentId.uuidString)")]
                )
                return rows.first?.imageUrls
            }() {
                fetchedImageUrls = urls
            }
        }
        .sheet(isPresented: $showRenterReviewSheet) {
            UserReviewFormView(
                rental: currentRental,
                revieweeId: currentRental.renterId,
                revieweeName: language.sp ? "Arrendatario" : "Renter",
                reviewerRole: "host",
                onSubmitted: { onRenterReviewed?() }
            )
            .environmentObject(AuthManager.shared)
            .environmentObject(LanguageManager.shared)
        }
    }

    private func detailRow(icon: String, label: String, value: String, valueColor: Color = Color.encoreText) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.encoreLightPurple)
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.encorePrimary)
            }
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.encoreTextSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
    }

    private func statusPill(_ status: RentalStatus) -> some View {
        let (label, color): (String, Color) = {
            switch status {
            case .pending:   return (language.sp ? "Pendiente"  : "Pending",   Color.encoreOrange)
            case .confirmed: return (language.sp ? "Confirmado" : "Confirmed", Color.encoreBlue)
            case .active:    return (language.sp ? "Activo"     : "Active",    Color.encoreGreen)
            case .completed: return (language.sp ? "Completado" : "Completed", Color.encoreTextSecondary)
            case .cancelled: return (language.sp ? "Cancelado"  : "Cancelled", Color.encoreCoral)
            }
        }()
        return Text(label)
            .font(.caption.weight(.black))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.3), lineWidth: 1))
    }

    private func pickupLabel(_ method: PickupMethod) -> String {
        switch method {
        case .meet_up:      return language.sp ? "Encuentro" : "Meet Up"
        case .host_address: return language.sp ? "Dirección del anfitrión" : "Host's Address"
        case .shipping:     return language.sp ? "Envío" : "Shipping"
        }
    }

    private func updateStatus(_ status: RentalStatus, message: String) {
        isUpdating = true
        Task {
            do {
                try await SupabaseClient.shared.update(
                    table: "rentals",
                    id: currentRental.id,
                    body: ["status": status.rawValue]
                )
                await MainActor.run {
                    currentRental.status = status
                    onStatusChanged?(status)
                    isUpdating = false
                    toast = Toast(message: message)
                }
            } catch {
                await MainActor.run {
                    isUpdating = false
                    toast = Toast(message: error.localizedDescription)
                }
            }
        }
    }
}
