//
//  EditInstrumentView.swift
//  Encore
//

import SwiftUI
import PhotosUI

struct EditInstrumentView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var language: LanguageManager
    @Environment(\.dismiss) private var dismiss

    let instrument: Instrument
    var onSaved: ((Instrument) -> Void)?

    @State private var name: String
    @State private var category: String
    @State private var pricePerDay: String
    @State private var depositAmount: String
    @State private var location: String
    @State private var condition: String
    @State private var descriptionText: String
    @State private var requiresId: Bool
    @State private var isAvailable: Bool
    @State private var maxRentalDays: Int
    @State private var blockedDates: Set<String>

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var newImageData: [Data] = []

    @State private var isSaving = false
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var errorMessage: String?
    @State private var toast: Toast?

    private let categoryKeys = ["string", "percussion", "keys", "brass", "other"]

    init(instrument: Instrument, onSaved: ((Instrument) -> Void)? = nil) {
        self.instrument = instrument
        self.onSaved = onSaved
        _name         = State(initialValue: instrument.name)
        _category     = State(initialValue: instrument.category)
        _pricePerDay  = State(initialValue: NSDecimalNumber(decimal: instrument.pricePerDay).stringValue)
        _depositAmount = State(initialValue: NSDecimalNumber(decimal: instrument.depositAmount).stringValue)
        _location     = State(initialValue: instrument.location ?? "")
        _condition    = State(initialValue: instrument.condition ?? "Good")
        _descriptionText = State(initialValue: instrument.description ?? "")
        _requiresId      = State(initialValue: instrument.requiresId)
        _isAvailable     = State(initialValue: instrument.isAvailable)
        _maxRentalDays   = State(initialValue: instrument.maxRentalDays)
        _blockedDates    = State(initialValue: Set(instrument.blockedDates))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                availabilityToggle
                field(language.sp ? "Nombre" : "Name", text: $name,
                      prompt: language.sp ? "Ej. Guitarra acústica" : "e.g. Acoustic guitar")
                categoryField
                field(language.sp ? "Precio por día (₡)" : "Price per day (₡)",
                      text: $pricePerDay, prompt: "10000")
                    .keyboardType(.numberPad)
                field(language.sp ? "Depósito (₡)" : "Deposit (₡)",
                      text: $depositAmount, prompt: "20000")
                    .keyboardType(.numberPad)
                field(language.sp ? "Ubicación" : "Location",
                      text: $location, prompt: language.sp ? "Ciudad o dirección" : "City or address")
                conditionField
                VStack(alignment: .leading, spacing: 8) {
                    Text(Strings.description(language.sp))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.encoreText)
                    TextField(language.sp ? "Descripción del instrumento…" : "Instrument description…",
                              text: $descriptionText, axis: .vertical)
                        .lineLimit(4...8)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .memphisCard(cornerRadius: 12, offset: 3, lineWidth: 1.5)
                }
                HStack {
                    Text(language.sp ? "Requiere ID" : "Requires ID")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.encoreText)
                    Spacer()
                    Toggle("", isOn: $requiresId)
                        .labelsHidden()
                        .tint(Color.encorePrimary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .memphisCard(cornerRadius: 12, offset: 3, lineWidth: 1.5)
                maxRentalDaysField
                blockedDatesSection
                photoSection
                reviewsSection
                if let err = errorMessage {
                    Text(err).font(.caption).foregroundStyle(.red)
                }
                deleteButton
            }
            .padding()
            .padding(.bottom, 40)
        }
        .navigationTitle(language.sp ? "Editar anuncio" : "Edit listing")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationLink(destination: InstrumentDetailView(instrument: instrument)) {
                    Image(systemName: "eye")
                        .foregroundStyle(Color.encorePrimary)
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(Strings.saveChanges(language.sp)) { saveInstrument() }
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                    .disabled(isSaving || name.isEmpty || pricePerDay.isEmpty)
            }
        }
        .onChange(of: selectedItems) { _ in loadSelectedImages() }
        .toast($toast)
        .confirmationDialog(
            language.sp ? "¿Eliminar este anuncio?" : "Delete this listing?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(language.sp ? "Eliminar" : "Delete", role: .destructive) { deleteInstrument() }
            Button(Strings.cancel(language.sp), role: .cancel) {}
        } message: {
            Text(language.sp
                 ? "Esta acción no se puede deshacer."
                 : "This action cannot be undone.")
        }
    }

    // MARK: - Availability toggle

    private var availabilityToggle: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(language.sp ? "Disponible para alquilar" : "Available for rent")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.encoreText)
                HStack(spacing: 4) {
                    Circle()
                        .fill(isAvailable ? Color.encoreGreen : Color.encoreTextSecondary)
                        .frame(width: 7, height: 7)
                    Text(isAvailable
                         ? (language.sp ? "Visible en búsquedas" : "Visible in search")
                         : (language.sp ? "Oculto de búsquedas" : "Hidden from search"))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(isAvailable ? Color.encoreGreen : Color.encoreTextSecondary)
                }
            }
            Spacer()
            Toggle("", isOn: $isAvailable)
                .labelsHidden()
                .tint(Color.encorePrimary)
        }
        .padding()
        .background(isAvailable ? Color.encoreGreen.opacity(0.08) : Color(.systemBackground))
        .cornerRadius(12)
        .memphisCard(cornerRadius: 12, offset: 3, lineWidth: 1.5)
    }

    // MARK: - Delete button

    private var deleteButton: some View {
        Button {
            showDeleteConfirm = true
        } label: {
            HStack(spacing: 8) {
                if isDeleting {
                    ProgressView().scaleEffect(0.8)
                } else {
                    ZStack {
                        Circle()
                            .fill(Color.encoreCoral.opacity(0.15))
                            .frame(width: 28, height: 28)
                            .overlay(Circle().stroke(Color.encoreCoral, lineWidth: 1.5))
                        Image(systemName: "trash")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.encoreCoral)
                    }
                    Text(language.sp ? "Eliminar anuncio" : "Delete listing")
                }
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(Color.encoreCoral)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.encoreCoral, lineWidth: 1.5))
            .shadow(color: Color.encoreCoral, radius: 0, x: 3, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(isDeleting || isSaving)
    }

    // MARK: - Reusable field

    private func field(_ label: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.subheadline.weight(.semibold)).foregroundStyle(Color.encoreText)
            TextField(prompt, text: text)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .memphisCard(cornerRadius: 12, offset: 3, lineWidth: 1.5)
        }
    }

    private static let conditionKeys = ["Excellent", "Good", "Fair"]

    private var categoryField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Strings.categories(language.sp))
                .font(.subheadline.weight(.semibold)).foregroundStyle(Color.encoreText)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categoryKeys, id: \.self) { key in
                        let isSelected = category == key
                        Button { category = key } label: {
                            HStack(spacing: 4) {
                                Text(emojiForCategory(key))
                                Text(categoryLabel(key))
                                    .font(.caption.weight(.semibold))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(isSelected ? Color.encorePrimary : Color(.systemBackground))
                            .foregroundStyle(isSelected ? .white : Color.encoreText)
                            .cornerRadius(20)
                            .overlay(Capsule().stroke(Color.primary, lineWidth: 1.5))
                            .memphisShadow(x: isSelected ? 2 : 0, y: isSelected ? 2 : 0)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var conditionField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(language.sp ? "Condición" : "Condition")
                .font(.subheadline.weight(.semibold)).foregroundStyle(Color.encoreText)
            HStack(spacing: 8) {
                ForEach(Self.conditionKeys, id: \.self) { key in
                    let isSelected = condition == key
                    let label: String = {
                        switch key {
                        case "Excellent": return language.sp ? "Excelente" : "Excellent"
                        case "Good":      return language.sp ? "Bueno" : "Good"
                        default:          return language.sp ? "Regular" : "Fair"
                        }
                    }()
                    let color: Color = key == "Excellent" ? Color.encoreGreen : (key == "Good" ? Color.encoreBlue : Color.encoreOrange)
                    Button { condition = key } label: {
                        Text(label)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(isSelected ? color : Color(.systemBackground))
                            .foregroundStyle(isSelected ? .white : Color.encoreText)
                            .cornerRadius(20)
                            .overlay(Capsule().stroke(Color.primary, lineWidth: 1.5))
                            .memphisShadow(x: isSelected ? 2 : 0, y: isSelected ? 2 : 0)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func emojiForCategory(_ key: String) -> String {
        switch key {
        case "string":     return "🎸"
        case "percussion": return "🥁"
        case "keys":       return "🎹"
        case "brass":      return "🎺"
        default:           return "🎶"
        }
    }

    private func categoryLabel(_ key: String) -> String {
        switch key {
        case "string":     return Strings.string(language.sp)
        case "percussion": return Strings.percussion(language.sp)
        case "keys":       return Strings.keys(language.sp)
        case "brass":      return Strings.brass(language.sp)
        default:           return Strings.other(language.sp)
        }
    }

    // MARK: - Max rental days

    private var maxRentalDaysField: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.encoreBlue.opacity(0.15))
                    .frame(width: 36, height: 36)
                    .overlay(Circle().stroke(Color.primary, lineWidth: 1.5))
                Image(systemName: "clock.badge.checkmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.encoreBlue)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(language.sp ? "Máximo de días" : "Max rental days")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.encoreText)
                Text(language.sp ? "Duración máxima por reserva" : "Maximum duration per booking")
                    .font(.caption)
                    .foregroundStyle(Color.encoreTextSecondary)
            }
            Spacer()
            HStack(spacing: 10) {
                Button {
                    if maxRentalDays > 1 { maxRentalDays -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(maxRentalDays > 1 ? Color.encorePrimary : Color(.systemGray4))
                }
                .buttonStyle(.plain)
                .disabled(maxRentalDays <= 1)

                Text("\(maxRentalDays)")
                    .font(.headline.weight(.black))
                    .foregroundStyle(Color.encoreText)
                    .frame(minWidth: 28)

                Button {
                    if maxRentalDays < 30 { maxRentalDays += 1 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(maxRentalDays < 30 ? Color.encorePrimary : Color(.systemGray4))
                }
                .buttonStyle(.plain)
                .disabled(maxRentalDays >= 30)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .memphisCard(cornerRadius: 12, offset: 3, lineWidth: 1.5)
    }

    // MARK: - Blocked dates calendar

    private var blockedDatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.encoreCoral.opacity(0.15))
                        .frame(width: 36, height: 36)
                        .overlay(Circle().stroke(Color.primary, lineWidth: 1.5))
                    Image(systemName: "calendar.badge.minus")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.encoreCoral)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(language.sp ? "Días no disponibles" : "Unavailable days")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.encoreText)
                    Text(language.sp ? "Toca un día para bloquearlo / desbloquearlo" : "Tap a day to block / unblock it")
                        .font(.caption)
                        .foregroundStyle(Color.encoreTextSecondary)
                }
            }

            BlockedDatesCalendar(blockedDates: $blockedDates)

            if !blockedDates.isEmpty {
                Text(language.sp
                     ? "\(blockedDates.count) día(s) bloqueado(s)"
                     : "\(blockedDates.count) day(s) blocked")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.encoreCoral)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .memphisCard(cornerRadius: 12, offset: 3, lineWidth: 1.5)
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(language.sp ? "Añadir fotos (máx. 5)" : "Add photos (max 5)")
                .font(.subheadline.weight(.semibold)).foregroundStyle(Color.encoreText)
            if !instrument.imageUrls.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(instrument.imageUrls, id: \.self) { url in
                            RemoteImage(url: url, emojiFallback: instrument.imageEmoji ?? "🎸")
                                .frame(width: 72, height: 72)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary, lineWidth: 1.5))
                                .memphisShadow(x: 2, y: 2)
                        }
                    }
                }
            }
            PhotosPicker(selection: $selectedItems, maxSelectionCount: 5, matching: .images) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.encoreAccent)
                            .frame(width: 32, height: 32)
                            .overlay(Circle().stroke(Color.primary, lineWidth: 1.5))
                        Image(systemName: "photo.badge.plus")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.black)
                    }
                    Text(language.sp ? "Reemplazar fotos" : "Replace photos")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.encoreText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .memphisCard(cornerRadius: 12, offset: 3, lineWidth: 1.5)
            }
        }
    }

    // MARK: - Reviews

    private var reviewsSection: some View {
        NavigationLink(destination: ReviewsListView(instrument: instrument)) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.encoreAccent.opacity(0.2))
                        .frame(width: 36, height: 36)
                        .overlay(Circle().stroke(Color.primary, lineWidth: 1.5))
                    Image(systemName: "star.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.encoreAccent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(language.sp ? "Reseñas del instrumento" : "Instrument reviews")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.encoreText)
                    Text(language.sp ? "Ver y responder reseñas" : "View and reply to reviews")
                        .font(.caption)
                        .foregroundStyle(Color.encoreTextSecondary)
                }
                Spacer()
                if (instrument.reviewCount ?? 0) > 0 {
                    Text("\(instrument.reviewCount ?? 0)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.encorePrimary)
                }
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.encoreTextSecondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .memphisCard(cornerRadius: 12, offset: 3, lineWidth: 1.5)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Data

    private func loadSelectedImages() {
        Task {
            var data: [Data] = []
            for item in selectedItems {
                if let d = try? await item.loadTransferable(type: Data.self) { data.append(d) }
            }
            await MainActor.run { newImageData = data }
        }
    }

    private func saveInstrument() {
        guard let price = Decimal(string: pricePerDay), price > 0 else {
            errorMessage = language.sp ? "Precio inválido" : "Invalid price"
            return
        }
        let deposit = Decimal(string: depositAmount) ?? 0
        errorMessage = nil
        isSaving = true

        Task {
            do {
                var body: [String: Any] = [
                    "name":            name.trimmingCharacters(in: .whitespacesAndNewlines),
                    "category":        category,
                    "description":     descriptionText.isEmpty ? NSNull() : descriptionText,
                    "price_per_day":   NSDecimalNumber(decimal: price).doubleValue,
                    "deposit_amount":  NSDecimalNumber(decimal: deposit).doubleValue,
                    "location":        location.isEmpty ? NSNull() : location,
                    "condition":       condition,
                    "requires_id":     requiresId,
                    "is_available":    isAvailable,
                    "max_rental_days": maxRentalDays,
                    "blocked_dates":   Array(blockedDates).sorted()
                ]

                // Upload new photos if selected
                if !newImageData.isEmpty {
                    StorageService.shared.accessToken = auth.session?.accessToken
                    var urls: [String] = []
                    for (i, imgData) in newImageData.enumerated() {
                        let path = "\(instrument.id.uuidString)/\(i).jpg"
                        let url = try await StorageService.shared.upload(
                            bucket: .instruments, path: path,
                            data: imgData, contentType: "image/jpeg"
                        )
                        urls.append(url)
                    }
                    body["image_urls"] = urls
                }

                try await SupabaseClient.shared.update(table: "instruments", id: instrument.id, body: body)
                ListingsCache.invalidate()
                await MainActor.run {
                    isSaving = false
                    onSaved?(instrument)
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

    private func isoDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f.string(from: date)
    }

    private func deleteInstrument() {
        isDeleting = true
        Task {
            do {
                try await SupabaseClient.shared.delete(table: "instruments", id: instrument.id)
                ListingsCache.invalidate()
                await MainActor.run {
                    isDeleting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Blocked Dates Calendar

struct BlockedDatesCalendar: View {
    @Binding var blockedDates: Set<String>

    init(blockedDates: Binding<Set<String>>) {
        _blockedDates = blockedDates
    }

    @State private var displayMonth: Date = {
        let c = Calendar.current
        return c.date(from: c.dateComponents([.year, .month], from: Date())) ?? Date()
    }()

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let dayHeaders = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    private var isoFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
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
            HStack(spacing: 4) {
                ForEach(dayHeaders, id: \.self) { d in
                    Text(d)
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(Color.encoreTextSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day grid
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0..<leadingBlanks, id: \.self) { _ in Color.clear.frame(height: 36) }
                ForEach(daysInMonth, id: \.self) { date in
                    let iso = isoFmt.string(from: date)
                    let isBlocked = blockedDates.contains(iso)
                    let isPast = date < Calendar.current.startOfDay(for: Date())
                    let isToday = Calendar.current.isDateInToday(date)

                    Button {
                        if !isPast {
                            if isBlocked { blockedDates.remove(iso) }
                            else { blockedDates.insert(iso) }
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    isBlocked ? Color.encoreCoral :
                                    isPast    ? Color(.systemGray6) :
                                    isToday   ? Color.encoreLightPurple :
                                    Color(.systemGray6).opacity(0.5)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            isBlocked ? Color.encoreCoral :
                                            isToday   ? Color.encorePrimary : Color.clear,
                                            lineWidth: 1.5
                                        )
                                )
                            if isBlocked {
                                Image(systemName: "xmark")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundStyle(.white)
                            } else {
                                Text("\(calendar.component(.day, from: date))")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(isPast ? Color(.systemGray3) : Color.encoreText)
                            }
                        }
                        .frame(height: 36)
                        .shadow(color: isBlocked ? Color.encoreCoral.opacity(0.5) : .clear, radius: 0, x: 1, y: 1)
                    }
                    .buttonStyle(.plain)
                    .disabled(isPast)
                }
            }
        }
    }

    private var monthLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: displayMonth)
    }

    private var leadingBlanks: Int {
        let comps = calendar.dateComponents([.year, .month], from: displayMonth)
        guard let first = calendar.date(from: comps) else { return 0 }
        return calendar.component(.weekday, from: first) - 1
    }

    private var daysInMonth: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: displayMonth),
              let first = calendar.date(from: calendar.dateComponents([.year, .month], from: displayMonth))
        else { return [] }
        return range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: first) }
    }

    private func shiftMonth(_ delta: Int) {
        if let next = calendar.date(byAdding: .month, value: delta, to: displayMonth) {
            displayMonth = next
        }
    }
}
