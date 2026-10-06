//
//  EditRentalView.swift
//  Encore
//

import SwiftUI

struct EditRentalView: View {
    @EnvironmentObject var language: LanguageManager
    @Environment(\.dismiss) private var dismiss

    let rental: Rental
    let pricePerDay: Decimal
    var onSaved: (() -> Void)?

    @State private var startDate: Date
    @State private var endDate: Date
    @State private var pickupMethod: PickupMethod

    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var toast: Toast?
    @State private var selectingStart = true

    private var numberOfDays: Int {
        max(1, Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1)
    }
    private var rentalTotal: Decimal { pricePerDay * Decimal(numberOfDays) }

    init(rental: Rental, pricePerDay: Decimal, onSaved: (() -> Void)? = nil) {
        self.rental = rental
        self.pricePerDay = pricePerDay
        self.onSaved = onSaved

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = TimeZone(identifier: "UTC")
        let s = fmt.date(from: rental.startDate) ?? Date()
        let e = fmt.date(from: rental.endDate) ?? Date()
        _startDate = State(initialValue: s)
        _endDate   = State(initialValue: e)
        _pickupMethod = State(initialValue: rental.pickupMethod)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Instrument header
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.encoreLightPurple)
                            .frame(width: 56, height: 56)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary, lineWidth: 1.5))
                        Text(rental.instrumentEmoji ?? "🎸").font(.title2)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(rental.instrumentName ?? "—")
                            .font(.headline.weight(.black))
                            .foregroundStyle(Color.encoreText)
                        Text("₡\(NSDecimalNumber(decimal: pricePerDay).intValue) / \(language.sp ? "día" : "day")")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.encoreTextSecondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(14)
                .memphisCard(cornerRadius: 14, offset: 3, lineWidth: 1.5)

                // Date selector chips + single calendar
                HStack(spacing: 12) {
                    dateChip(label: language.sp ? "INICIO" : "START", date: startDate, isActive: selectingStart) {
                        withAnimation(.easeInOut(duration: 0.15)) { selectingStart = true }
                    }
                    Image(systemName: "arrow.right")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color.encoreTextSecondary)
                    dateChip(label: language.sp ? "FIN" : "END", date: endDate, isActive: !selectingStart) {
                        withAnimation(.easeInOut(duration: 0.15)) { selectingStart = false }
                    }
                    Spacer()
                }

                DatePicker(
                    "",
                    selection: selectingStart ? $startDate : $endDate,
                    in: selectingStart
                        ? Date()...
                        : (Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate)...,
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.graphical)
                .tint(Color.encorePrimary)
                .onChange(of: startDate) { _ in
                    if endDate <= startDate {
                        endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate
                    }
                    withAnimation(.easeInOut(duration: 0.15)) { selectingStart = false }
                }
                .onChange(of: endDate) { _ in
                    withAnimation(.easeInOut(duration: 0.15)) { selectingStart = true }
                }
                .padding(.top, -8)

                // Price summary
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(numberOfDays) \(language.sp ? "noches" : "nights")")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color.encoreText)
                        Text("₡\(NSDecimalNumber(decimal: rentalTotal).intValue) \(language.sp ? "total sin depósito" : "before deposit")")
                            .font(.caption).foregroundStyle(Color.encoreTextSecondary)
                    }
                    Spacer()
                    Text("₡\(NSDecimalNumber(decimal: rentalTotal).intValue)")
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.encoreAccent)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary, lineWidth: 1.5))
                        .memphisShadow(x: 2, y: 2)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .memphisCard(cornerRadius: 12, offset: 3, lineWidth: 1.5)

                // Pickup method
                VStack(alignment: .leading, spacing: 10) {
                    Text(language.sp ? "Método de entrega" : "Pickup method")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(Color.encoreText)
                    ForEach(PickupMethod.allCases, id: \.self) { method in
                        let isSelected = pickupMethod == method
                        Button { pickupMethod = method } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(isSelected ? Color.encorePrimary : Color.encoreLightPurple)
                                        .frame(width: 36, height: 36)
                                        .overlay(Circle().stroke(Color.primary, lineWidth: 1.5))
                                    Image(systemName: pickupIcon(method))
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(isSelected ? .white : Color.encorePrimary)
                                }
                                Text(pickupLabel(method))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.encoreText)
                                Spacer()
                                if isSelected {
                                    ZStack {
                                        Circle().fill(Color.encoreAccent).frame(width: 22, height: 22)
                                            .overlay(Circle().stroke(Color.primary, lineWidth: 1.5))
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .black))
                                            .foregroundStyle(.black)
                                    }
                                }
                            }
                            .padding()
                            .background(isSelected ? Color.encoreLightPurple : Color(.systemBackground))
                            .cornerRadius(12)
                            .memphisCard(cornerRadius: 12,
                                         offset: isSelected ? 3 : 0,
                                         lineWidth: isSelected ? 2 : 1.5)
                        }
                        .buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.15), value: isSelected)
                    }
                }

                if let err = errorMessage {
                    Text(err).font(.caption).foregroundStyle(.red)
                }
            }
            .padding()
            .padding(.bottom, 40)
        }
        .navigationTitle(language.sp ? "Editar reserva" : "Edit booking")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(Strings.saveChanges(language.sp)) { saveRental() }
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                    .disabled(isSaving)
            }
        }
        .toast($toast)
    }

    // MARK: - Helpers

    private func dateChip(label: String, date: Date, isActive: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(isActive ? Color.encorePrimary : Color.encoreTextSecondary)
                Text(shortDate(date))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isActive ? Color.encoreText : Color.encoreTextSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isActive ? Color.encoreLightPurple : Color(.systemBackground))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(isActive ? Color.encorePrimary : Color(.systemGray4), lineWidth: isActive ? 1.5 : 1))
            .shadow(color: isActive ? .black : .clear, radius: 0, x: 2, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }

    private func pickupLabel(_ method: PickupMethod) -> String {
        switch method {
        case .meet_up:      return language.sp ? "Encuentro" : "Meet Up"
        case .host_address: return language.sp ? "Dirección del anfitrión" : "Host's Address"
        case .shipping:     return language.sp ? "Envío" : "Shipping"
        }
    }

    private func pickupIcon(_ method: PickupMethod) -> String {
        switch method {
        case .meet_up:      return "person.2.fill"
        case .host_address: return "house.fill"
        case .shipping:     return "shippingbox.fill"
        }
    }

    private func isoDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f.string(from: date)
    }

    // MARK: - Save

    private func saveRental() {
        isSaving = true
        errorMessage = nil
        let body: [String: Any] = [
            "start_date":    isoDate(startDate),
            "end_date":      isoDate(endDate),
            "total_price":   NSDecimalNumber(decimal: rentalTotal + rental.depositAmount).doubleValue,
            "pickup_method": pickupMethod.rawValue
        ]
        Task {
            do {
                try await SupabaseClient.shared.update(table: "rentals", id: rental.id, body: body)
                await MainActor.run {
                    isSaving = false
                    onSaved?()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
