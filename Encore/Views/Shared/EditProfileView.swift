//
//  EditProfileView.swift
//  Encore
//

import SwiftUI
import PhotosUI
import CoreLocation

struct EditProfileView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var language: LanguageManager
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var locationManager = LocationManager.shared

    // Account
    @State private var newEmail: String = ""

    // Personal
    @State private var name: String = ""
    @State private var lastName: String = ""
    @State private var bio: String = ""

    // Location
    @State private var city: String = ""
    @State private var address: String = ""
    @State private var detectedLocation: CLLocation?
    @State private var selectedLocationCountry: CountryDialCode = CountryDialCode.fromLocale()
    @State private var showLocationCountryPicker = false

    // Contact
    @State private var phoneNumber: String = ""
    @State private var selectedPhoneCountry: CountryDialCode = CountryDialCode.fromLocale()
    @State private var showPhoneCountryPicker = false

    // Photo
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?

    // State
    @State private var isSaving = false
    @State private var toast: Toast?
    @State private var isDetectingLocation = false
    @State private var showEmailConfirmationAlert = false
    @State private var errorMessage: String?
    @State private var alertErrorMessage = ""
    @State private var showErrorAlert = false

    private var fullPhone: String {
        let digits = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !digits.isEmpty else { return "" }
        return "\(selectedPhoneCountry.dialCode) \(digits)"
    }

    private var emailChanged: Bool {
        newEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() !=
        (auth.currentUser?.email ?? "").lowercased()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                avatarSection
                sectionCard(header: language.sp ? "Cuenta" : "Account") {
                    accountFields
                }
                sectionCard(header: language.sp ? "Información personal" : "Personal info") {
                    personalFields
                }
                sectionCard(header: language.sp ? "Ubicación" : "Location") {
                    locationFields
                }
                sectionCard(header: language.sp ? "Contacto" : "Contact") {
                    contactFields
                }
                if let err = errorMessage {
                    Text(err).font(.caption).foregroundStyle(.red)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .background(Color.encoreFrame.ignoresSafeArea())
        .navigationTitle(Strings.editProfile(language.sp))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(Strings.saveChanges(language.sp)) { saveProfile() }
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                    .disabled(isSaving)
            }
        }
        .onAppear { loadCurrentValues() }
        .sheet(isPresented: $showPhoneCountryPicker) {
            CountryCodePickerView(selected: $selectedPhoneCountry)
        }
        .sheet(isPresented: $showLocationCountryPicker) {
            CountryCodePickerView(selected: $selectedLocationCountry)
        }
        .alert(
            language.sp ? "Confirma tu nuevo correo" : "Confirm your new email",
            isPresented: $showEmailConfirmationAlert
        ) {
            Button(Strings.done(language.sp)) { dismiss() }
        } message: {
            Text(language.sp
                 ? "Te enviamos un enlace de confirmación a \(newEmail). El cambio se aplicará después de confirmar."
                 : "We sent a confirmation link to \(newEmail). The change takes effect after you confirm.")
        }
        .alert(Strings.error(language.sp), isPresented: $showErrorAlert) {
            Button(Strings.done(language.sp)) { showErrorAlert = false }
        } message: {
            Text(alertErrorMessage)
        }
        .toast($toast)
    }

    // MARK: - Avatar

    private var avatarSection: some View {
        HStack(spacing: 20) {
            ZStack(alignment: .bottomTrailing) {
                if let data = selectedImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable().scaledToFill()
                        .frame(width: 88, height: 88)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.primary, lineWidth: 2))
                        .memphisShadow(x: 3, y: 3)
                } else {
                    ProfileAvatarView(url: auth.currentUser?.avatarUrl, size: 88)
                        .overlay(Circle().stroke(Color.primary, lineWidth: 2))
                        .memphisShadow(x: 3, y: 3)
                }
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    ZStack {
                        Circle()
                            .fill(Color.encoreAccent)
                            .frame(width: 28, height: 28)
                            .overlay(Circle().stroke(Color.primary, lineWidth: 1.5))
                        Image(systemName: "camera")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(.black)
                    }
                }
                .onChange(of: selectedItem) { _ in
                    Task {
                        if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
                            await MainActor.run { selectedImageData = data }
                        }
                    }
                }
                .offset(x: 2, y: 2)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(auth.currentUser?.displayName ?? "—")
                    .font(.headline.weight(.black))
                    .foregroundStyle(Color.encoreText)
                Text(Strings.changePhoto(language.sp))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.encorePrimary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .memphisCard(cornerRadius: 16, offset: 4, lineWidth: 1.5)
    }

    // MARK: - Account fields

    private var accountFields: some View {
        VStack(spacing: 12) {
            fieldRow(icon: "envelope", iconColor: Color.encoreBlue) {
                TextField(Strings.email(language.sp), text: $newEmail)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            if emailChanged {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.encoreBlue)
                    Text(language.sp
                         ? "Se enviará un enlace de confirmación al guardar."
                         : "A confirmation link will be sent on save.")
                        .font(.caption)
                        .foregroundStyle(Color.encoreTextSecondary)
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Personal fields

    private var personalFields: some View {
        VStack(spacing: 12) {
            fieldRow(icon: "person", iconColor: Color.encorePrimary) {
                TextField(Strings.firstName(language.sp), text: $name)
            }
            fieldRow(icon: "person", iconColor: Color.encorePrimary) {
                TextField(Strings.lastName(language.sp), text: $lastName)
            }
            fieldRow(icon: "text.quote", iconColor: Color.encoreTeal) {
                TextField(Strings.bio(language.sp), text: $bio, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
    }

    // MARK: - Location fields

    private var locationFields: some View {
        VStack(spacing: 12) {
            Button { showLocationCountryPicker = true } label: {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.encoreOrange.opacity(0.18))
                            .frame(width: 32, height: 32)
                            .overlay(Circle().stroke(Color.primary, lineWidth: 1))
                        Image(systemName: "flag")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.encoreOrange)
                    }
                    Text(selectedLocationCountry.flag + " " + selectedLocationCountry.name)
                        .font(.subheadline)
                        .foregroundStyle(Color.encoreText)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(Color.encoreTextSecondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .memphisCard(cornerRadius: 12, offset: 3, lineWidth: 1.5)
            }
            .buttonStyle(.plain)

            HStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(Color.encoreGreen.opacity(0.18))
                        .frame(width: 32, height: 32)
                        .overlay(Circle().stroke(Color.primary, lineWidth: 1))
                    Image(systemName: "mappin")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.encoreGreen)
                }
                .padding(.leading)
                TextField(Strings.city(language.sp), text: $city)
                    .padding()
                Button {
                    detectLocation()
                } label: {
                    if isDetectingLocation {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        Image(systemName: "location.fill")
                            .foregroundStyle(Color.encorePrimary)
                    }
                }
                .buttonStyle(.plain)
                .disabled(isDetectingLocation)
                .padding(.trailing)
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .memphisCard(cornerRadius: 12, offset: 3, lineWidth: 1.5)

            fieldRow(icon: "house", iconColor: Color.encoreCoral) {
                TextField(language.sp ? "Dirección residencial" : "Residential address", text: $address)
            }
        }
    }

    // MARK: - Contact fields

    private var contactFields: some View {
        HStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color.encorePink.opacity(0.18))
                    .frame(width: 32, height: 32)
                    .overlay(Circle().stroke(Color.primary, lineWidth: 1))
                Image(systemName: "phone")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.encorePink)
            }
            .padding(.leading)

            Button { showPhoneCountryPicker = true } label: {
                HStack(spacing: 4) {
                    Text(selectedPhoneCountry.flag).font(.body)
                    Text(selectedPhoneCountry.dialCode)
                        .font(.body).foregroundStyle(Color.encoreText)
                    Image(systemName: "chevron.down")
                        .font(.caption2).foregroundStyle(Color.encoreTextSecondary)
                }
                .padding(.horizontal, 10)
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(Color(.separator))
                .frame(width: 1, height: 24)

            TextField(language.sp ? "Número" : "Number", text: $phoneNumber)
                .keyboardType(.numberPad)
                .padding()
                .onChange(of: phoneNumber) { newValue in
                    let digits = newValue.filter { $0.isNumber }
                    if digits.count > 15 {
                        phoneNumber = String(digits.prefix(15))
                    } else if newValue != digits {
                        phoneNumber = digits
                    }
                }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .memphisCard(cornerRadius: 12, offset: 3, lineWidth: 1.5)
    }

    // MARK: - Helpers

    private func sectionCard<Content: View>(header: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(header)
                .font(.caption.weight(.black))
                .foregroundStyle(Color.encoreTextSecondary)
                .textCase(.uppercase)
                .padding(.horizontal, 4)
            content()
        }
    }

    private func fieldRow<Content: View>(icon: String, iconColor: Color, @ViewBuilder field: () -> Content) -> some View {
        HStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.18))
                    .frame(width: 32, height: 32)
                    .overlay(Circle().stroke(Color.primary, lineWidth: 1))
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(iconColor)
            }
            .padding(.leading)
            field()
                .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .memphisCard(cornerRadius: 12, offset: 3, lineWidth: 1.5)
    }

    // MARK: - Location detection

    private func detectLocation() {
        isDetectingLocation = true
        locationManager.requestLocation { location in
            guard let location else {
                DispatchQueue.main.async { self.isDetectingLocation = false }
                return
            }
            // Store location so it's used when saving (avoids race with other screens)
            detectedLocation = location
            Task {
                let result = await LocationManager.shared.reverseGeocode(location)
                await MainActor.run {
                    if let detectedCity = result.city { city = detectedCity }
                    if let iso = result.countryCode,
                       let match = CountryDialCode.all.first(where: { $0.isoCode == iso }) {
                        selectedLocationCountry = match
                        selectedPhoneCountry = match
                    }
                    isDetectingLocation = false
                }
            }
        }
    }

    // MARK: - Load values

    private func loadCurrentValues() {
        newEmail   = auth.currentUser?.email    ?? ""
        name       = auth.currentUser?.name     ?? ""
        lastName   = auth.currentUser?.lastName ?? ""
        city       = auth.currentUser?.city     ?? ""
        address    = auth.currentUser?.address  ?? ""
        bio        = auth.currentUser?.bio      ?? ""

        if let saved = auth.currentUser?.phone, !saved.isEmpty {
            let parts = saved.split(separator: " ", maxSplits: 1)
            if parts.count == 2,
               let dialPart = parts.first.map(String.init),
               let match = CountryDialCode.all.first(where: { $0.dialCode == dialPart }) {
                selectedPhoneCountry = match
                phoneNumber = String(parts[1])
            } else {
                phoneNumber = saved
            }
        }

        if phoneNumber.isEmpty {
            selectedPhoneCountry = CountryDialCode.fromLocale()
        }
        if let iso = auth.currentUser?.countryIso,
           let match = CountryDialCode.all.first(where: { $0.isoCode == iso }) {
            selectedLocationCountry = match
        } else {
            selectedLocationCountry = CountryDialCode.fromLocale()
        }
    }

    // MARK: - Save

    private func saveProfile() {
        guard let uid = auth.session?.userId else {
            alertErrorMessage = language.sp ? "No hay sesión activa." : "No active session."
            showErrorAlert = true
            return
        }
        errorMessage = nil
        isSaving = true
        Task {
            do {
                let trimmedEmail = newEmail.trimmingCharacters(in: .whitespacesAndNewlines)
                if emailChanged && !trimmedEmail.isEmpty {
                    try await auth.updateEmail(trimmedEmail)
                }

                var body: [String: Any] = [
                    "name":        name.trimmingCharacters(in: .whitespacesAndNewlines),
                    "last_name":   lastName.trimmingCharacters(in: .whitespacesAndNewlines),
                    "city":        city.trimmingCharacters(in: .whitespacesAndNewlines),
                    "country_iso": selectedLocationCountry.isoCode,
                    "address":     address.trimmingCharacters(in: .whitespacesAndNewlines),
                    "phone":       fullPhone,
                    "bio":         bio.trimmingCharacters(in: .whitespacesAndNewlines)
                ]
                if let loc = detectedLocation ?? LocationManager.shared.currentLocation {
                    body["latitude"]  = loc.coordinate.latitude
                    body["longitude"] = loc.coordinate.longitude
                }
                if let data = selectedImageData {
                    let uploadData: Data
                    if let uiImage = UIImage(data: data),
                       let thumb = uiImage.preparingThumbnail(of: CGSize(width: 800, height: 800)),
                       let compressed = thumb.jpegData(compressionQuality: 0.75) {
                        uploadData = compressed
                    } else {
                        uploadData = data
                    }
                    StorageService.shared.accessToken = auth.session?.accessToken
                    let url = try await StorageService.shared.upload(
                        bucket: .avatars,
                        path: "\(uid.uuidString).jpg",
                        data: uploadData,
                        contentType: "image/jpeg"
                    )
                    body["avatar_url"] = "\(url)?v=\(Int(Date().timeIntervalSince1970))"
                }
                try await auth.updateProfile(body)

                await MainActor.run {
                    isSaving = false
                    if emailChanged {
                        showEmailConfirmationAlert = true
                    } else {
                        toast = Toast(message: language.sp ? "Perfil guardado" : "Profile saved")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
                    }
                }
            } catch {
                print("[EditProfileView] save failed: \(error)")
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    alertErrorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        EditProfileView()
            .environmentObject(AuthManager.shared)
            .environmentObject(LanguageManager.shared)
    }
}
