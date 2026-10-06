//
//  CheckoutView.swift
//  Encore
//

import SwiftUI
import AudioToolbox

// MARK: - Go-home notification
extension Notification.Name {
    static let encoreGoHome = Notification.Name("EncoreGoHome")
}

// MARK: - Checkout (4-step flow)

struct CheckoutView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var language: LanguageManager
    @Environment(\.dismiss) private var dismiss
    let instrument: Instrument

    // Step state
    @State private var step: Int = 1

    // Step 1 — Dates
    @State private var startDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var endDate   = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
    @State private var selectingStart = true

    // Step 2 — Pickup
    @State private var pickupMethod: PickupMethod = .meet_up

    // Step 3 — Payment
    @State private var savedCards: [PaymentMethodRow] = []
    @State private var selectedCard: PaymentMethodRow?
    @State private var useSavedCard = true
    @State private var cardNumber = ""
    @State private var cardHolder = ""
    @State private var cardExpiry = ""
    @State private var cardCVV = ""
    @State private var cardError: String?
    @State private var isSavingCard = false

    // Step 4 — Confirm
    @State private var isConfirming = false
    @State private var confirmError: String?
    @State private var bookingConfirmed = false

    // Booked dates from existing rentals
    @State private var rentedDates: Set<String> = []

    // Computed
    private var numberOfDays: Int {
        max(1, Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1)
    }
    private var rentalTotal: Decimal { instrument.pricePerDay * Decimal(numberOfDays) }
    private var grandTotal: Decimal  { rentalTotal + instrument.depositAmount }

    var body: some View {
        VStack(spacing: 0) {
            progressBar
            stepContent
                .animation(.easeInOut(duration: 0.25), value: step)
        }
        .navigationTitle(stepTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(step > 1)
        .toolbar {
            if step > 1 {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation { step -= 1 }
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(Color.encorePrimary)
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 28, height: 28)
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(Color(.systemGray))
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .fullScreenCover(isPresented: $bookingConfirmed) {
            BookingConfirmedView(
                instrument: instrument,
                startDate: startDate,
                endDate: endDate,
                totalPrice: grandTotal
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .encoreGoHome)) { _ in
            dismiss()
        }
        .task {
            await loadSavedCards()
            await loadRentedDates()
        }
        .onChange(of: step) { newStep in
            if newStep == 3 { Task { await loadSavedCards() } }
        }
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        HStack(spacing: 8) {
            ForEach(1...4, id: \.self) { i in
                ZStack {
                    Circle()
                        .fill(i <= step ? Color.encorePrimary : Color(.systemGray5))
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(Color.primary, lineWidth: i <= step ? 2 : 1.5))
                        .shadow(color: i <= step ? .black : .clear, radius: 0, x: 2, y: 2)
                    Text("\(i)")
                        .font(.caption.weight(.black))
                        .foregroundStyle(i <= step ? .white : Color.encoreTextSecondary)
                }
                if i < 4 {
                    Rectangle()
                        .fill(i < step ? Color.encorePrimary : Color(.systemGray5))
                        .frame(height: 2.5)
                        .overlay(Rectangle().stroke(.black.opacity(i < step ? 0.6 : 0.2), lineWidth: 1))
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    private var stepTitle: String {
        switch step {
        case 1: return language.sp ? "Fechas" : "Dates"
        case 2: return language.sp ? "Entrega" : "Pickup"
        case 3: return language.sp ? "Pago" : "Payment"
        case 4: return language.sp ? "Confirmar" : "Review"
        default: return ""
        }
    }

    // MARK: - Step routing

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 1: step1Dates
        case 2: step2Pickup
        case 3: step3Payment
        case 4: step4Review
        default: EmptyView()
        }
    }

    // MARK: - Step 1: Dates

    private var step1Dates: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Instrument card
                    HStack(spacing: 12) {
                        RemoteImage(url: instrument.imageUrls.first, emojiFallback: instrument.imageEmoji ?? "🎸", category: instrument.category)
                            .frame(width: 56, height: 56)
                            .background(Color.encorePrimary)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary, lineWidth: 1.5))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(instrument.name).font(.subheadline.weight(.black))
                            Text("₡\(NSDecimalNumber(decimal: instrument.pricePerDay).intValue) / \(language.sp ? "día" : "day")")
                                .font(.caption).foregroundStyle(Color.encoreTextSecondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.encoreBackground)
                    .cornerRadius(14)
                    .memphisCard(cornerRadius: 14, offset: 3, lineWidth: 2)

                    // Date range summary + clear
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.encorePrimary)
                        let fmt: DateFormatter = {
                            let f = DateFormatter(); f.dateFormat = "MMM d"; return f
                        }()
                        Text("\(fmt.string(from: startDate))  →  \(fmt.string(from: endDate))")
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(Color.encoreText)
                        Spacer()
                        Text("\(numberOfDays) \(language.sp ? "días" : "days")")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.encorePrimary)
                            .clipShape(Capsule())
                        Button {
                            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                            startDate = tomorrow
                            endDate = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? tomorrow
                            selectingStart = true
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.body)
                                .foregroundStyle(Color.encoreTextSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.encoreLightPurple)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.encorePrimary, lineWidth: 1.5))

                    // Max days info pill
                    HStack(spacing: 6) {
                        Image(systemName: "clock.badge.checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.encoreBlue)
                        Text(language.sp
                             ? "Máximo \(instrument.maxRentalDays) días por reserva"
                             : "Max \(instrument.maxRentalDays) days per booking")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.encoreBlue)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.encoreBlue.opacity(0.08))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.encoreBlue.opacity(0.4), lineWidth: 1))

                    // Range calendar
                    let allUnavailableForCal = Set(instrument.blockedDates).union(rentedDates)
                    RangeCalendarView(
                        startDate: $startDate,
                        endDate: $endDate,
                        selectingStart: $selectingStart,
                        unavailableDates: allUnavailableForCal,
                        maxRentalDays: instrument.maxRentalDays
                    )

                    // Unavailable dates warning (host-blocked + already rented)
                    let rangeUnavailable = allUnavailableForCal.filter { iso in
                        guard let d = isoToDate(iso) else { return false }
                        return d > startDate && d <= endDate
                    }
                    if !rangeUnavailable.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color.encoreOrange)
                            Text(language.sp
                                 ? "Hay \(rangeUnavailable.count) día(s) no disponible(s) en este rango."
                                 : "\(rangeUnavailable.count) day(s) in this range are unavailable.")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.encoreOrange)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.encoreOrange.opacity(0.08))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.encoreOrange.opacity(0.4), lineWidth: 1))
                    }

                    // Summary pill
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(numberOfDays) \(language.sp ? "días" : "days")")
                                .font(.subheadline.weight(.black))
                            Text("₡\(NSDecimalNumber(decimal: rentalTotal).intValue) \(language.sp ? "sin depósito" : "before deposit")")
                                .font(.caption).foregroundStyle(Color.encoreTextSecondary)
                        }
                        Spacer()
                        Text("₡\(NSDecimalNumber(decimal: instrument.pricePerDay).intValue)/\(language.sp ? "día" : "day")")
                            .font(.caption.weight(.black))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.encoreAccent)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.primary, lineWidth: 1.5))
                    }
                    .padding()
                    .background(Color.encoreLightYellow)
                    .cornerRadius(12)
                    .memphisCard(cornerRadius: 12, offset: 3, lineWidth: 2)
                }
                .padding()
                .padding(.bottom, 80)
            }
            let blockedInRange = Set(instrument.blockedDates).union(rentedDates).contains { iso in
                guard let d = isoToDate(iso) else { return false }
                let day = Calendar.current.startOfDay(for: d)
                let s   = Calendar.current.startOfDay(for: startDate)
                let e   = Calendar.current.startOfDay(for: endDate)
                return day >= s && day <= e
            }
            nextButton(label: language.sp ? "Siguiente" : "Next") {
                withAnimation { step = 2 }
            }
            .disabled(blockedInRange)
            .opacity(blockedInRange ? 0.4 : 1)
        }
    }

    private func dateChip(label: String, date: Date, isActive: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(isActive ? Color.encorePrimary : Color.encoreTextSecondary)
                Text(dateString(date))
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

    // MARK: - Step 2: Pickup

    private var step2Pickup: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(language.sp ? "¿Cómo recoges el instrumento?" : "How will you get the instrument?")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(PickupMethod.allCases, id: \.self) { method in
                        PickupCard(
                            method: method,
                            isSelected: pickupMethod == method,
                            language: language,
                            onSelect: { pickupMethod = method }
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .padding(.bottom, 80)
            }
            nextButton(label: language.sp ? "Siguiente" : "Next") {
                withAnimation { step = 3 }
            }
        }
    }

    // MARK: - Step 3: Payment

    private var step3Payment: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Saved cards
                    if !savedCards.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(language.sp ? "Tarjetas guardadas" : "Saved cards")
                                .font(.subheadline).fontWeight(.semibold).foregroundStyle(Color.encoreTextSecondary)
                            ForEach(savedCards) { card in
                                Button {
                                    withAnimation {
                                        selectedCard = card
                                        useSavedCard = true
                                    }
                                } label: {
                                    HStack(spacing: 14) {
                                        Image(systemName: cardIcon(for: card.brand ?? ""))
                                            .font(.title2)
                                            .foregroundStyle(Color.encorePrimary)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("\(card.brand?.capitalized ?? "Card") •••• \(card.last4 ?? "")")
                                                .font(.subheadline).fontWeight(.medium).foregroundStyle(.primary)
                                            Text(language.sp ? "Exp. \(card.expiryMonth ?? 0)/\(card.expiryYear ?? 0)" : "Expires \(card.expiryMonth ?? 0)/\(card.expiryYear ?? 0)")
                                                .font(.caption).foregroundStyle(Color.encoreTextSecondary)
                                        }
                                        Spacer()
                                        Image(systemName: selectedCard?.id == card.id && useSavedCard ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(selectedCard?.id == card.id && useSavedCard ? Color.encorePrimary : Color(.systemGray3))
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(selectedCard?.id == card.id && useSavedCard ? Color.encorePrimary : Color.clear, lineWidth: 2)
                                    )
                                }
                                .buttonStyle(.plain)
                            }

                            Button {
                                withAnimation { useSavedCard = false }
                            } label: {
                                Text(language.sp ? "Usar otra tarjeta" : "Use a different card")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.encorePrimary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)
                    }

                    // New card form
                    if savedCards.isEmpty || !useSavedCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(language.sp ? "Nueva tarjeta" : "Card details")
                                .font(.subheadline).fontWeight(.semibold).foregroundStyle(Color.encoreTextSecondary)
                                .padding(.horizontal)

                            VStack(spacing: 1) {
                                cardField(
                                    placeholder: language.sp ? "Número de tarjeta" : "Card number",
                                    text: $cardNumber,
                                    keyboardType: .numberPad,
                                    leadingIcon: cardIcon(for: CheckoutHelpers.cardBrand(from: cardNumber)),
                                    formatter: CheckoutHelpers.formatCardNumber
                                )
                                Divider().padding(.leading, 50)
                                cardField(
                                    placeholder: language.sp ? "Nombre del titular" : "Cardholder name",
                                    text: $cardHolder,
                                    keyboardType: .default,
                                    leadingIcon: "person"
                                )
                                Divider().padding(.leading, 50)
                                HStack(spacing: 0) {
                                    cardField(
                                        placeholder: "MM / YY",
                                        text: $cardExpiry,
                                        keyboardType: .numberPad,
                                        leadingIcon: "calendar",
                                        formatter: CheckoutHelpers.formatExpiry
                                    )
                                    Divider().frame(height: 44)
                                    cardField(
                                        placeholder: "CVV",
                                        text: $cardCVV,
                                        keyboardType: .numberPad,
                                        leadingIcon: "lock",
                                        isSecure: true
                                    )
                                }
                            }
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(14)
                            .padding(.horizontal)

                            if let err = cardError {
                                Text(err).font(.caption).foregroundStyle(.red).padding(.horizontal)
                            }

                            Label(
                                language.sp ? "Tus datos están encriptados y seguros." : "Your payment info is encrypted and secure.",
                                systemImage: "lock.shield"
                            )
                            .font(.caption)
                            .foregroundStyle(Color.encoreTextSecondary)
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
                .padding(.bottom, 100)
            }

            nextButton(
                label: language.sp ? "Revisar reserva" : "Review booking",
                isLoading: isSavingCard
            ) {
                Task { await handlePaymentStep() }
            }
        }
    }

    // MARK: - Step 4: Review & Confirm

    private var step4Review: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Instrument
                    HStack(spacing: 12) {
                        RemoteImage(url: instrument.imageUrls.first, emojiFallback: instrument.imageEmoji ?? "🎸", category: instrument.category)
                            .frame(width: 72, height: 72)
                            .background(Color.encorePrimary)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary, lineWidth: 1.5))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(instrument.name).font(.headline.weight(.black))
                            if let r = instrument.rating {
                                Label("★\(NSDecimalNumber(decimal: r).doubleValue, specifier: "%.2f")", systemImage: "star.fill")
                                    .font(.caption).foregroundStyle(.orange)
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.encoreBackground)
                    .cornerRadius(14)
                    .memphisCard(cornerRadius: 14, offset: 3, lineWidth: 2)

                    // Dates
                    reviewRow(
                        icon: "calendar",
                        title: language.sp ? "Fechas" : "Dates",
                        value: "\(dateString(startDate)) – \(dateString(endDate)) · \(numberOfDays) \(language.sp ? "días" : "days")"
                    )

                    // Pickup
                    reviewRow(
                        icon: "mappin.circle",
                        title: language.sp ? "Entrega" : "Pickup",
                        value: pickupMethodLabel(pickupMethod, sp: language.sp)
                    )

                    // Payment
                    if useSavedCard, let card = selectedCard {
                        reviewRow(
                            icon: cardIcon(for: card.brand ?? ""),
                            title: language.sp ? "Pago" : "Payment",
                            value: "\(card.brand?.capitalized ?? "Card") •••• \(card.last4 ?? "")"
                        )
                    } else if !cardNumber.isEmpty {
                        reviewRow(
                            icon: cardIcon(for: CheckoutHelpers.cardBrand(from: cardNumber)),
                            title: language.sp ? "Pago" : "Payment",
                            value: "\(CheckoutHelpers.cardBrand(from: cardNumber).capitalized) •••• \(String(cardNumber.filter { $0.isNumber }.suffix(4)))"
                        )
                    }

                    // Price breakdown
                    VStack(alignment: .leading, spacing: 10) {
                        Text(language.sp ? "Desglose de precio" : "Price breakdown")
                            .font(.headline.weight(.black))

                        HStack {
                            Text("₡\(NSDecimalNumber(decimal: instrument.pricePerDay).intValue) × \(numberOfDays) \(language.sp ? "días" : "days")")
                                .foregroundStyle(Color.encoreTextSecondary)
                            Spacer()
                            Text("₡\(NSDecimalNumber(decimal: rentalTotal).intValue)")
                        }
                        .font(.subheadline)

                        HStack {
                            Text(language.sp ? "Depósito reembolsable" : "Refundable deposit")
                                .foregroundStyle(Color.encoreTextSecondary)
                            Spacer()
                            Text("₡\(NSDecimalNumber(decimal: instrument.depositAmount).intValue)")
                        }
                        .font(.subheadline)

                        Divider()

                        HStack {
                            Text(language.sp ? "Total pagado" : "Total paid")
                                .font(.headline.weight(.black))
                            Spacer()
                            Text("₡\(NSDecimalNumber(decimal: grandTotal).intValue)")
                                .font(.headline.weight(.black))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.encoreAccent)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.primary, lineWidth: 1.5))
                        }
                    }
                    .padding()
                    .background(Color.encoreBackground)
                    .cornerRadius(14)
                    .memphisCard(cornerRadius: 14, offset: 3, lineWidth: 2)

                    if let err = confirmError {
                        Text(err).font(.caption).foregroundStyle(.red)
                    }

                    Text(language.sp
                         ? "Al confirmar aceptas las condiciones del anfitrión. El pago se procesará cuando el anfitrión apruebe tu solicitud."
                         : "By confirming you agree to the host's terms. Payment will be processed when the host approves your request.")
                        .font(.caption)
                        .foregroundStyle(Color.encoreTextSecondary)
                }
                .padding()
                .padding(.bottom, 100)
            }

            nextButton(
                label: language.sp ? "Confirmar y pagar" : "Confirm & Pay",
                isLoading: isConfirming
            ) {
                Task { await confirmBooking() }
            }
        }
    }

    // MARK: - Helpers

    private func reviewRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.encoreLightPurple)
                    .frame(width: 36, height: 36)
                    .overlay(Circle().stroke(Color.primary, lineWidth: 1.5))
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.encorePrimary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundStyle(Color.encoreTextSecondary)
                Text(value).font(.subheadline).fontWeight(.semibold)
            }
            Spacer()
        }
        .padding()
        .background(Color.encoreBackground)
        .cornerRadius(14)
        .memphisCard(cornerRadius: 14, offset: 3, lineWidth: 1.5)
    }

    private func cardField(
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType,
        leadingIcon: String,
        formatter: ((String) -> String)? = nil,
        isSecure: Bool = false
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: leadingIcon)
                .frame(width: 20)
                .foregroundStyle(Color.encorePrimary)
            if isSecure {
                SecureField(placeholder, text: text)
                    .keyboardType(keyboardType)
            } else {
                TextField(placeholder, text: text)
                    .keyboardType(keyboardType)
                    .onChange(of: text.wrappedValue) { _ in
                        if let fmt = formatter {
                            let formatted = fmt(text.wrappedValue)
                            if formatted != text.wrappedValue { text.wrappedValue = formatted }
                        }
                    }
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 50)
    }

    private func nextButton(label: String, isLoading: Bool = false, action: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            Divider()
            Button(action: action) {
                Group {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(label).font(.headline.weight(.black)).foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.encorePrimary)
                .cornerRadius(12)
                .memphisCard(cornerRadius: 12, offset: 3, lineWidth: 2)
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.encoreBackground)
        }
    }

    // MARK: - Date helpers

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }

    private func isoDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f.string(from: date)
    }

    private func isoToDate(_ iso: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f.date(from: iso)
    }

    // MARK: - Card helpers

    private func cardIcon(for brand: String) -> String {
        switch brand.lowercased() {
        case "visa":       return "creditcard"
        case "mastercard": return "creditcard.fill"
        case "amex":       return "creditcard.and.123"
        default:           return "creditcard"
        }
    }

    private func pickupMethodLabel(_ method: PickupMethod, sp: Bool) -> String {
        switch method {
        case .meet_up:      return sp ? "Encuentro" : "Meet Up"
        case .host_address: return sp ? "Dirección del anfitrión" : "Host's Address"
        case .shipping:     return sp ? "Envío" : "Shipping"
        }
    }

    // MARK: - Network

    private func loadSavedCards() async {
        guard let uid = auth.session?.userId else { return }
        do {
            let query = [
                URLQueryItem(name: "user_id", value: "eq.\(uid.uuidString)"),
                URLQueryItem(name: "order", value: "created_at.desc")
            ]
            let rows: [PaymentMethodRow] = try await SupabaseClient.shared.fetch(table: "payment_methods", query: query)
            await MainActor.run {
                savedCards = rows
                let currentId = selectedCard?.id
                if selectedCard == nil || !rows.contains(where: { $0.id == currentId }) {
                    selectedCard = rows.first { $0.isDefault == true } ?? rows.first
                    useSavedCard = !rows.isEmpty
                }
            }
        } catch {
            print("[CheckoutView] loadSavedCards failed: \(error)")
        }
    }

    private func loadRentedDates() async {
        do {
            let query = [
                URLQueryItem(name: "instrument_id", value: "eq.\(instrument.id.uuidString)"),
                URLQueryItem(name: "status", value: "in.(pending,confirmed,active)")
            ]
            let rentals: [Rental] = try await SupabaseClient.shared.fetch(table: "rentals", query: query)
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd"
            fmt.timeZone = TimeZone(identifier: "UTC")
            var dates = Set<String>()
            for rental in rentals {
                guard let start = fmt.date(from: rental.startDate),
                      let end = fmt.date(from: rental.endDate) else { continue }
                var cur = start
                while cur <= end {
                    dates.insert(fmt.string(from: cur))
                    cur = Calendar.current.date(byAdding: .day, value: 1, to: cur) ?? cur
                }
            }
            await MainActor.run { rentedDates = dates }
        } catch {
            print("[CheckoutView] loadRentedDates failed: \(error)")
        }
    }

    private func handlePaymentStep() async {
        if useSavedCard && selectedCard != nil {
            await MainActor.run { withAnimation { step = 4 } }
            return
        }
        // Validate new card
        let digits = cardNumber.filter { $0.isNumber }
        let expiryParts = cardExpiry.filter { $0.isNumber }
        let cvvDigits = cardCVV.filter { $0.isNumber }

        guard digits.count >= 13 else {
            await MainActor.run { cardError = language.sp ? "Número de tarjeta inválido." : "Invalid card number." }
            return
        }
        guard cardHolder.trimmingCharacters(in: .whitespaces).count >= 2 else {
            await MainActor.run { cardError = language.sp ? "Ingresa el nombre del titular." : "Enter cardholder name." }
            return
        }
        guard expiryParts.count == 4,
              let month = Int(expiryParts.prefix(2)), month >= 1, month <= 12,
              let year = Int(expiryParts.suffix(2)) else {
            await MainActor.run { cardError = language.sp ? "Fecha de expiración inválida." : "Invalid expiry date." }
            return
        }
        let fullYear = 2000 + year
        let now = Calendar.current.dateComponents([.month, .year], from: Date())
        let nowYear = now.year ?? Calendar.current.component(.year, from: Date())
        let nowMonth = now.month ?? Calendar.current.component(.month, from: Date())
        if fullYear < nowYear || (fullYear == nowYear && month < nowMonth) {
            await MainActor.run { cardError = language.sp ? "Tarjeta expirada." : "Card has expired." }
            return
        }
        guard cvvDigits.count >= 3 else {
            await MainActor.run { cardError = language.sp ? "CVV inválido." : "Invalid CVV." }
            return
        }

        await MainActor.run { cardError = nil; isSavingCard = true }

        guard let uid = auth.session?.userId else {
            await MainActor.run { isSavingCard = false }
            return
        }

        let body: [String: Any] = [
            "user_id": uid.uuidString,
            "stripe_pm_id": "manual_\(UUID().uuidString)",
            "brand": CheckoutHelpers.cardBrand(from: cardNumber),
            "last4": String(digits.suffix(4)),
            "expiry_month": month,
            "expiry_year": fullYear,
            "is_default": true
        ]

        do {
            let data = try await SupabaseClient.shared.insert(table: "payment_methods", body: body)
            struct InsertedPM: Decodable { let id: UUID }
            let inserted = try? JSONDecoder.supabase.decode([InsertedPM].self, from: data)
            await MainActor.run {
                let newCard = PaymentMethodRow(
                    id: inserted?.first?.id ?? UUID(),
                    userId: uid,
                    brand: CheckoutHelpers.cardBrand(from: cardNumber),
                    last4: String(digits.suffix(4)),
                    expiryMonth: month,
                    expiryYear: fullYear,
                    isDefault: true
                )
                savedCards.insert(newCard, at: 0)
                selectedCard = newCard
                useSavedCard = true
                isSavingCard = false
                withAnimation { step = 4 }
            }
        } catch {
            await MainActor.run {
                cardError = error.localizedDescription
                isSavingCard = false
            }
        }
    }

    private func confirmBooking() async {
        guard let renterId = auth.session?.userId else { return }

        // Final check: ensure no unavailable dates in the range
        let allUnavailable = Set(instrument.blockedDates).union(rentedDates)
        let conflict = allUnavailable.contains { iso in
            guard let d = isoToDate(iso) else { return false }
            return d > startDate && d <= endDate
        }
        if conflict {
            await MainActor.run {
                confirmError = language.sp
                    ? "Las fechas seleccionadas incluyen días no disponibles. Por favor elige otras fechas."
                    : "Your selected dates include unavailable days. Please choose different dates."
            }
            return
        }

        await MainActor.run { confirmError = nil; isConfirming = true }

        let body: [String: Any] = [
            "instrument_id":   instrument.id.uuidString,
            "renter_id":       renterId.uuidString,
            "host_id":         instrument.hostId.uuidString,
            "start_date":      isoDate(startDate),
            "end_date":        isoDate(endDate),
            "total_price":     NSDecimalNumber(decimal: grandTotal).doubleValue,
            "deposit_amount":  NSDecimalNumber(decimal: instrument.depositAmount).doubleValue,
            "deposit_returned": false,
            "status":          "pending",
            "instrument_name":      instrument.name,
            "instrument_emoji":     instrument.imageEmoji ?? "",
            "instrument_image_url": instrument.imageUrls.first ?? NSNull(),
            "pickup_method":        pickupMethod.rawValue,
            "has_been_reviewed":    false
        ]

        do {
            _ = try await SupabaseClient.shared.insert(table: "rentals", body: body)
            await MainActor.run {
                isConfirming = false
                bookingConfirmed = true
            }
        } catch {
            await MainActor.run {
                confirmError = error.localizedDescription
                isConfirming = false
            }
        }
    }
}

// MARK: - Pickup card

private struct PickupCard: View {
    let method: PickupMethod
    let isSelected: Bool
    let language: LanguageManager
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.encorePrimary : Color(.systemGray5))
                        .frame(width: 44, height: 44)
                        .overlay(Circle().stroke(Color.primary, lineWidth: isSelected ? 2 : 1.5))
                    Image(systemName: icon)
                        .font(.body.weight(.bold))
                        .foregroundStyle(isSelected ? .white : Color.encoreTextSecondary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.subheadline.weight(.bold)).foregroundStyle(Color.encoreText)
                    Text(subtitle).font(.caption).foregroundStyle(Color.encoreTextSecondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white)
                        .padding(5)
                        .background(Color.encorePrimary)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.primary, lineWidth: 1.5))
                }
            }
            .padding()
            .background(isSelected ? Color.encoreLightPurple : Color.encoreBackground)
            .cornerRadius(14)
            .memphisCard(cornerRadius: 14, offset: isSelected ? 3 : 0, lineWidth: isSelected ? 2 : 1.5)
        }
        .buttonStyle(.plain)
    }

    private var icon: String {
        switch method {
        case .meet_up:      return "person.2.fill"
        case .host_address: return "house.fill"
        case .shipping:     return "shippingbox.fill"
        }
    }
    private var title: String {
        switch method {
        case .meet_up:      return language.sp ? "Encuentro" : "Meet Up"
        case .host_address: return language.sp ? "Dirección del anfitrión" : "Host's Address"
        case .shipping:     return language.sp ? "Envío" : "Shipping"
        }
    }
    private var subtitle: String {
        switch method {
        case .meet_up:      return language.sp ? "Coordina un punto de encuentro con el anfitrión." : "Coordinate a meeting spot with the host."
        case .host_address: return language.sp ? "Recoge el instrumento en casa del anfitrión." : "Pick up the instrument at the host's place."
        case .shipping:     return language.sp ? "El anfitrión lo envía a tu dirección." : "The host ships it to your address."
        }
    }
}

// MARK: - PaymentMethodRow (local model for display)

struct PaymentMethodRow: Codable, Identifiable {
    var id: UUID
    var userId: UUID?
    var brand: String?
    var last4: String?
    var expiryMonth: Int?
    var expiryYear: Int?
    var isDefault: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case brand
        case last4 = "last4"
        case expiryMonth = "expiry_month"
        case expiryYear = "expiry_year"
        case isDefault = "is_default"
    }
}

// MARK: - Booking Confirmed

struct BookingConfirmedView: View {
    @EnvironmentObject var language: LanguageManager
    @Environment(\.dismiss) private var dismiss
    let instrument: Instrument
    let startDate: Date
    let endDate: Date
    let totalPrice: Decimal

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.encoreFrame.ignoresSafeArea()

            // Memphis background decorations
            GeometryReader { geo in
                ZStack {
                    Circle()
                        .fill(Color.encoreAccent.opacity(0.3))
                        .frame(width: 160, height: 160)
                        .position(x: geo.size.width - 20, y: 80)
                    Circle()
                        .fill(Color.encorePink.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .position(x: 10, y: geo.size.height - 180)
                    Circle()
                        .fill(Color.encorePrimary.opacity(0.12))
                        .frame(width: 70, height: 70)
                        .position(x: geo.size.width * 0.15, y: 200)
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                // Memphis celebration icon
                ZStack {
                    // Hard shadow
                    Circle()
                        .fill(.black)
                        .frame(width: 110, height: 110)
                        .offset(x: 5, y: 5)
                    // Main circle
                    Circle()
                        .fill(Color.encorePrimary)
                        .overlay(Circle().stroke(Color.primary, lineWidth: 3))
                        .frame(width: 110, height: 110)
                    // Checkmark
                    Image(systemName: "checkmark")
                        .font(.system(size: 46, weight: .black))
                        .foregroundStyle(.white)
                    // Accent dots
                    Circle()
                        .fill(Color.encoreAccent)
                        .overlay(Circle().stroke(Color.primary, lineWidth: 2))
                        .frame(width: 22, height: 22)
                        .offset(x: -64, y: -36)
                    Circle()
                        .fill(Color.encorePink)
                        .overlay(Circle().stroke(Color.primary, lineWidth: 1.5))
                        .frame(width: 14, height: 14)
                        .offset(x: 66, y: -28)
                    Circle()
                        .fill(.black)
                        .frame(width: 8, height: 8)
                        .offset(x: 54, y: 46)
                }
                .scaleEffect(scale)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
                        scale = 1
                        opacity = 1
                    }
                    // Success haptic + completion sound
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        AudioServicesPlaySystemSound(SystemSoundID(1322))
                    }
                }

                VStack(spacing: 8) {
                    Text(language.sp ? "¡Solicitud enviada!" : "Booking Requested!")
                        .font(.title2.weight(.black))
                        .foregroundStyle(Color.encoreText)
                    Text(language.sp
                         ? "Espera la confirmación del anfitrión. Te notificaremos cuando acepte."
                         : "Waiting for the host to confirm. We'll let you know when they accept.")
                        .font(.subheadline)
                        .foregroundStyle(Color.encoreTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Summary card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        RemoteImage(url: instrument.imageUrls.first, emojiFallback: instrument.imageEmoji ?? "🎸", category: instrument.category)
                            .frame(width: 52, height: 52)
                            .background(Color.encorePrimary)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary, lineWidth: 1.5))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(instrument.name).font(.headline.weight(.bold))
                            Text(dateRangeString).font(.caption).foregroundStyle(Color.encoreTextSecondary)
                        }
                        Spacer()
                    }
                    Divider()
                    HStack {
                        Text(language.sp ? "Total pagado" : "Total paid")
                            .font(.subheadline)
                            .foregroundStyle(Color.encoreTextSecondary)
                        Spacer()
                        Text("₡\(NSDecimalNumber(decimal: totalPrice).intValue)")
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Color.encoreAccent)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.primary, lineWidth: 1.5))
                    }
                }
                .padding()
                .background(Color.encoreBackground)
                .cornerRadius(16)
                .memphisCard(cornerRadius: 16, offset: 4, lineWidth: 2)
                .padding(.horizontal, 24)

                Spacer()

                Button {
                    NotificationCenter.default.post(name: .encoreGoHome, object: nil)
                    dismiss()
                } label: {
                    Text(language.sp ? "Ir al inicio" : "Back to Home")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.encorePrimary)
                        .cornerRadius(12)
                        .memphisCard(cornerRadius: 12, offset: 4, lineWidth: 2)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private var dateRangeString: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return "\(f.string(from: startDate)) – \(f.string(from: endDate))"
    }
}

// MARK: - Range Calendar

struct RangeCalendarView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var selectingStart: Bool
    let unavailableDates: Set<String>
    let maxRentalDays: Int
    var onStartChanged: (() -> Void)?
    var onEndChanged: (() -> Void)?

    init(startDate: Binding<Date>, endDate: Binding<Date>, selectingStart: Binding<Bool>,
         unavailableDates: Set<String>, maxRentalDays: Int,
         onStartChanged: (() -> Void)? = nil, onEndChanged: (() -> Void)? = nil) {
        _startDate = startDate
        _endDate = endDate
        _selectingStart = selectingStart
        self.unavailableDates = unavailableDates
        self.maxRentalDays = maxRentalDays
        self.onStartChanged = onStartChanged
        self.onEndChanged = onEndChanged
        let c = Calendar.current
        _displayMonth = State(initialValue: c.date(from: c.dateComponents([.year, .month], from: Date())) ?? Date())
    }

    @State private var displayMonth: Date

    private let cal = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let dayHeaders = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    private let isoFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    var body: some View {
        VStack(spacing: 10) {
            // Month navigation
            HStack {
                Button { shiftMonth(-1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color.encorePrimary)
                        .padding(8)
                        .background(Color.encoreLightPurple)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                Spacer()
                Text(monthLabel)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(Color.encoreText)
                Spacer()
                Button { shiftMonth(1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color.encorePrimary)
                        .padding(8)
                        .background(Color.encoreLightPurple)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            // Weekday headers
            HStack(spacing: 0) {
                ForEach(dayHeaders, id: \.self) { d in
                    Text(d)
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(Color.encoreTextSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day grid
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(0..<leadingBlanks, id: \.self) { _ in Color.clear.frame(height: 40) }
                ForEach(daysInMonth, id: \.self) { date in
                    dayCell(date)
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .memphisCard(cornerRadius: 16, offset: 3, lineWidth: 1.5)
    }

    // MARK: - Day cell

    @ViewBuilder
    private func dayCell(_ date: Date) -> some View {
        let today     = cal.startOfDay(for: Date())
        let dayStart  = cal.startOfDay(for: date)
        let sStart    = cal.startOfDay(for: startDate)
        let eStart    = cal.startOfDay(for: endDate)
        let iso       = isoFmt.string(from: date)

        let isPast        = dayStart < today
        let isUnavailable = unavailableDates.contains(iso)
        let isStart       = cal.isDate(dayStart, inSameDayAs: sStart)
        let isEnd         = cal.isDate(dayStart, inSameDayAs: eStart)
        let isInRange     = dayStart > sStart && dayStart < eStart
        let isSelected    = isStart || isEnd || isInRange
        let isToday       = cal.isDateInToday(date)

        // When picking end: block past max days or crossing a blocked date
        let maxEnd    = cal.date(byAdding: .day, value: maxRentalDays, to: startDate) ?? startDate
        let wall      = firstUnavailableAfterStart()
        let tooFar    = !selectingStart && dayStart > cal.startOfDay(for: maxEnd)
        let beyondWall = !selectingStart && wall != nil && dayStart >= cal.startOfDay(for: wall!)
        let disabled  = isPast || isUnavailable || tooFar || beyondWall

        let isFirstOfRow  = (dayPosition(date) % 7 == 1)
        let isLastOfRow   = (dayPosition(date) % 7 == 0)
        let showLeftBand  = isInRange || isEnd
        let showRightBand = isInRange || isStart

        Button {
            handleTap(date: date, dayStart: dayStart, sStart: sStart)
        } label: {
            ZStack {
                // Range band strip
                GeometryReader { geo in
                    if showLeftBand && !isFirstOfRow {
                        Rectangle()
                            .fill(Color.encorePrimary.opacity(0.18))
                            .frame(width: geo.size.width / 2, height: geo.size.height)
                    }
                    if showRightBand && !isLastOfRow {
                        Rectangle()
                            .fill(Color.encorePrimary.opacity(0.18))
                            .frame(width: geo.size.width / 2, height: geo.size.height)
                            .offset(x: geo.size.width / 2)
                    }
                }

                // Day circle / unavailable background
                if isUnavailable && !isPast {
                    Circle()
                        .fill(Color.encoreOrange.opacity(0.12))
                        .overlay(Circle().stroke(Color.encoreOrange.opacity(0.5), lineWidth: 1))
                        .padding(2)
                } else {
                    Circle()
                        .fill(
                            isStart || isEnd ? Color.encorePrimary :
                            isInRange        ? Color.encorePrimary.opacity(0.18) :
                            isToday          ? Color.encoreLightPurple :
                            Color.clear
                        )
                        .overlay(
                            Circle().stroke(
                                isToday && !isSelected ? Color.encorePrimary : Color.clear,
                                lineWidth: 1.5
                            )
                        )
                        .padding(2)
                }

                // Label
                if isUnavailable {
                    VStack(spacing: 0) {
                        Text("\(cal.component(.day, from: date))")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(isPast ? Color(.systemGray4) : Color.encoreOrange)
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(isPast ? Color(.systemGray4) : Color.encoreOrange)
                    }
                } else {
                    Text("\(cal.component(.day, from: date))")
                        .font(.system(size: 13, weight: isSelected ? .black : .medium))
                        .foregroundStyle(
                            isStart || isEnd              ? .white :
                            isPast || tooFar || beyondWall ? Color(.systemGray3) :
                            isInRange                      ? Color.encorePrimary :
                            Color.encoreText
                        )
                }
            }
            .frame(height: 40)
            .opacity(isPast ? 0.4 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    // MARK: - Tap logic

    private func handleTap(date: Date, dayStart: Date, sStart: Date) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if selectingStart {
            // First tap — set start, switch to end-picking mode
            startDate = date
            endDate = cal.date(byAdding: .day, value: 1, to: date) ?? date
            selectingStart = false
        } else {
            if dayStart < sStart {
                // Tapped before start → becomes new start, keep picking end
                startDate = date
                endDate = cal.date(byAdding: .day, value: 1, to: date) ?? date
            } else if dayStart > sStart {
                // Tapped after start → update end date, stay in end-picking mode
                endDate = date
            }
            // Tapping exactly on start does nothing
        }
    }

    private func firstUnavailableAfterStart() -> Date? {
        guard !selectingStart else { return nil }
        let sStart = cal.startOfDay(for: startDate)
        let maxEnd = cal.date(byAdding: .day, value: maxRentalDays, to: startDate) ?? startDate
        var cursor = cal.date(byAdding: .day, value: 1, to: sStart) ?? sStart
        while cursor <= maxEnd {
            if unavailableDates.contains(isoFmt.string(from: cursor)) { return cursor }
            cursor = cal.date(byAdding: .day, value: 1, to: cursor) ?? cursor
        }
        return nil
    }

    // MARK: - Helpers

    private var monthLabel: String {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"
        return f.string(from: displayMonth)
    }

    private var leadingBlanks: Int {
        let comps = cal.dateComponents([.year, .month], from: displayMonth)
        guard let first = cal.date(from: comps) else { return 0 }
        return cal.component(.weekday, from: first) - 1
    }

    private var daysInMonth: [Date] {
        guard let range = cal.range(of: .day, in: .month, for: displayMonth),
              let first = cal.date(from: cal.dateComponents([.year, .month], from: displayMonth))
        else { return [] }
        return range.compactMap { cal.date(byAdding: .day, value: $0 - 1, to: first) }
    }

    private func dayPosition(_ date: Date) -> Int {
        leadingBlanks + cal.component(.day, from: date)
    }

    private func shiftMonth(_ delta: Int) {
        if let next = cal.date(byAdding: .month, value: delta, to: displayMonth) {
            displayMonth = next
        }
    }
}
