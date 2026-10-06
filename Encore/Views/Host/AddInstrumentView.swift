//
//  AddInstrumentView.swift
//  Encore
//

import SwiftUI
import PhotosUI

struct AddInstrumentView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var language: LanguageManager
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category = "string"
    @State private var pricePerDay = ""
    @State private var depositAmount = ""
    @State private var location = ""
    @State private var condition = "Good"
    @State private var descriptionText = ""
    @State private var requiresId = false
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var imageData: [Data] = []
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var toast: Toast?

    private let categoryKeys = ["string", "percussion", "keys", "brass", "other"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                field(language.sp ? "Nombre" : "Name", text: $name, prompt: language.sp ? "Ej. Guitarra acústica" : "e.g. Acoustic guitar")
                categoryField
                field(language.sp ? "Precio por día (₡)" : "Price per day (₡)", text: $pricePerDay, prompt: "10000")
                    .keyboardType(.numberPad)
                field(language.sp ? "Depósito (₡)" : "Deposit (₡)", text: $depositAmount, prompt: "20000")
                    .keyboardType(.numberPad)
                field(Strings.rentalLocation(language.sp), text: $location, prompt: language.sp ? "Ciudad o dirección" : "City or address")
                conditionField
                VStack(alignment: .leading, spacing: 8) {
                    Text(Strings.description(language.sp))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.encoreText)
                    TextField(language.sp ? "Descripción del instrumento…" : "Instrument description…", text: $descriptionText, axis: .vertical)
                        .lineLimit(4...8)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .foregroundStyle(Color.encoreText)
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
                photoSection
                if let err = errorMessage {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding()
            .padding(.bottom, 40)
        }
        .navigationTitle(language.sp ? "Nuevo anuncio" : "New listing")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(language.sp ? "Guardar" : "Save") {
                    saveInstrument()
                }
                .contentShape(Rectangle())
                .buttonStyle(.plain)
                .disabled(isSaving || name.isEmpty || pricePerDay.isEmpty)
            }
        }
        .onChange(of: selectedItems) { _ in loadSelectedImages() }
        .toast($toast)
    }

    private func field(_ label: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.encoreText)
            TextField(prompt, text: text)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .foregroundStyle(Color.encoreText)
                .memphisCard(cornerRadius: 12, offset: 3, lineWidth: 1.5)
        }
    }

    private var categoryField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Strings.categories(language.sp))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.encoreText)
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

    private static let conditionKeys = ["Excellent", "Good", "Fair"]

    private var conditionField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(language.sp ? "Condición" : "Condition")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.encoreText)
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
        case "string": return Strings.string(language.sp)
        case "percussion": return Strings.percussion(language.sp)
        case "keys": return Strings.keys(language.sp)
        case "brass": return Strings.brass(language.sp)
        default: return Strings.other(language.sp)
        }
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(language.sp ? "Fotos (máx. 5)" : "Photos (max 5)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.encoreText)
            if !imageData.isEmpty {
                HStack(spacing: 8) {
                    ForEach(imageData.indices, id: \.self) { i in
                        if let uiImg = UIImage(data: imageData[i]) {
                            Image(uiImage: uiImg)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 72, height: 72)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary, lineWidth: 1.5))
                                .memphisShadow(x: 2, y: 2)
                        }
                    }
                }
            }
            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: 5,
                matching: .images
            ) {
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
                    Text(language.sp ? "Seleccionar fotos" : "Select photos")
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

    private func loadSelectedImages() {
        Task {
            var data: [Data] = []
            for item in selectedItems {
                if let d = try? await item.loadTransferable(type: Data.self) {
                    data.append(d)
                }
            }
            await MainActor.run { imageData = data }
        }
    }

    private func saveInstrument() {
        guard let hostId = auth.session?.userId else { return }
        guard let price = Decimal(string: pricePerDay), price > 0 else {
            errorMessage = language.sp ? "Precio inválido" : "Invalid price"
            return
        }
        let deposit = Decimal(string: depositAmount) ?? 0
        errorMessage = nil
        isSaving = true
        let body: [String: Any] = [
            "host_id": hostId.uuidString,
            "name": name,
            "category": category,
            "description": descriptionText.isEmpty ? NSNull() : descriptionText,
            "price_per_day": NSDecimalNumber(decimal: price).doubleValue,
            "deposit_amount": NSDecimalNumber(decimal: deposit).doubleValue,
            "image_emoji": emojiForCategory(category),
            "image_urls": [] as [String],
            "location": location.isEmpty ? NSNull() : location,
            "is_available":    true,
            "condition":       condition,
            "requires_id":     requiresId,
            "max_rental_days": 7,
            "blocked_dates":   [] as [String]
        ]
        Task {
            do {
                let data = try await SupabaseClient.shared.insert(table: "instruments", body: body)
                struct InsertedId: Decodable { let id: UUID }
                var instrumentId: UUID?
                if let decoded = try? JSONDecoder.supabase.decode([InsertedId].self, from: data), let first = decoded.first {
                    instrumentId = first.id
                } else if let single = try? JSONDecoder.supabase.decode(InsertedId.self, from: data) {
                    instrumentId = single.id
                }
                guard let instrumentId else {
                    await MainActor.run {
                        isSaving = false
                        errorMessage = language.sp ? "Anuncio creado pero no se pudo leer el id. Recarga tus anuncios." : "Listing created but couldn’t read id. Refresh your listings."
                    }
                    return
                }
                var urls: [String] = []
                if !imageData.isEmpty {
                    StorageService.shared.accessToken = auth.session?.accessToken
                }
                for (i, imgData) in imageData.enumerated() {
                    let path = "\(instrumentId.uuidString)/\(i).jpg"
                    let url = try await StorageService.shared.upload(
                        bucket: .instruments,
                        path: path,
                        data: imgData,
                        contentType: "image/jpeg"
                    )
                    urls.append(url)
                }
                if !urls.isEmpty {
                    try await SupabaseClient.shared.update(
                        table: "instruments",
                        id: instrumentId,
                        body: ["image_urls": urls]
                    )
                }
                ListingsCache.invalidate()
                await MainActor.run {
                    isSaving = false
                    toast = Toast(message: language.sp ? "Anuncio creado" : "Listing created")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
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