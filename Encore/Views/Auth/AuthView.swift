//
//  AuthView.swift
//  Encore
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var language: LanguageManager
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    // Sign-up extra fields
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var address = ""
    @State private var city = ""
    @State private var phoneNumber = ""
    @State private var selectedCountry: CountryDialCode = CountryDialCode.fromLocale()
    @State private var showCountryPicker = false
    @State private var selectedLocationCountry: CountryDialCode = CountryDialCode.fromLocale()
    @State private var showLocationCountryPicker = false

    @State private var isLoading = false
    @State private var showForgotPasswordSheet = false
    @State private var passwordMismatch = false

    private var fullPhone: String {
        let d = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !d.isEmpty else { return "" }
        return "\(selectedCountry.dialCode) \(d)"
    }

    private var canSubmit: Bool {
        let baseOK = !email.isEmpty && !password.isEmpty
        if isSignUp {
            return baseOK && !firstName.isEmpty && (!isSignUp || password == confirmPassword)
        }
        return baseOK
    }

    var body: some View {
        ZStack {
            Color.encoreFrame.ignoresSafeArea()

            // Memphis background decorations
            GeometryReader { geo in
                ZStack {
                    Circle()
                        .fill(Color.encorePrimary.opacity(0.12))
                        .frame(width: 210, height: 210)
                        .position(x: geo.size.width - 20, y: 90)
                    Circle()
                        .fill(Color.encoreAccent.opacity(0.22))
                        .frame(width: 130, height: 130)
                        .position(x: 10, y: geo.size.height - 140)
                    Circle()
                        .fill(Color.encorePink.opacity(0.14))
                        .frame(width: 80, height: 80)
                        .position(x: geo.size.width * 0.75, y: geo.size.height * 0.62)
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.encorePrimary.opacity(0.08))
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(28))
                        .position(x: 55, y: 220)
                    Circle()
                        .fill(Color.encoreTeal.opacity(0.15))
                        .frame(width: 48, height: 48)
                        .position(x: geo.size.width - 60, y: geo.size.height - 200)
                }
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    // Logo
                    VStack(spacing: 10) {
                        Image("EncoreLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90, height: 90)
                        Text(Strings.welcomeTitle(language.sp))
                            .font(.title.bold())
                            .foregroundStyle(Color.encoreText)
                        Text(Strings.welcomeSubtitle(language.sp))
                            .font(.subheadline)
                            .foregroundStyle(Color.encoreTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Card
                    VStack(alignment: .leading, spacing: 20) {
                        Text(isSignUp
                             ? (language.sp ? "Crear cuenta" : "Create account")
                             : (language.sp ? "Iniciar sesión" : "Sign in"))
                            .font(.title2.bold())
                            .foregroundStyle(Color.encoreText)

                        if isSignUp {
                            signUpFields
                        } else {
                            signInFields
                        }

                        if passwordMismatch {
                            Text(language.sp ? "Las contraseñas no coinciden." : "Passwords don't match.")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        if let err = auth.errorMessage {
                            Text(err).font(.caption).foregroundStyle(.red)
                        }

                        Button {
                            submit()
                        } label: {
                            Group {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(Strings.continue(language.sp))
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(canSubmit ? Color.encorePrimary : Color.encorePrimary.opacity(0.4))
                            .cornerRadius(12)
                            .contentShape(Rectangle())
                            .memphisCard(cornerRadius: 12, offset: canSubmit ? 3 : 0, lineWidth: canSubmit ? 2 : 0)
                        }
                        .buttonStyle(.plain)
                        .disabled(!canSubmit || isLoading)

                        HStack {
                            Spacer()
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isSignUp.toggle()
                                    auth.errorMessage = nil
                                    passwordMismatch = false
                                }
                            } label: {
                                Text(isSignUp
                                     ? (language.sp ? "¿Ya tienes cuenta? Inicia sesión" : "Already have an account? Sign in")
                                     : (language.sp ? "¿No tienes cuenta? Regístrate" : "Don't have an account? Sign up"))
                                    .font(.subheadline)
                                    .foregroundStyle(Color.encoreTextSecondary)
                            }
                            Spacer()
                        }
                    }
                    .padding(24)
                    .background(Color.encoreBackground)
                    .cornerRadius(20)
                    .memphisCard(cornerRadius: 20, offset: 4, lineWidth: 2)
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 40)
            }
            if isLoading {
                Color.black.opacity(0.25).ignoresSafeArea()
                ProgressView().tint(.white).scaleEffect(1.3)
            }
        }
        .onAppear { auth.errorMessage = nil }
        .sheet(isPresented: $showForgotPasswordSheet) {
            ForgotPasswordSheet(
                prefilledEmail: email,
                language: language,
                auth: auth,
                onDismiss: { showForgotPasswordSheet = false }
            )
        }
        .sheet(isPresented: $showCountryPicker) {
            CountryCodePickerView(selected: $selectedCountry)
        }
        .sheet(isPresented: $showLocationCountryPicker) {
            CountryCodePickerView(selected: $selectedLocationCountry)
        }
    }

    // MARK: - Sign-in fields

    private var signInFields: some View {
        VStack(alignment: .leading, spacing: 14) {
            StyledTextField(
                placeholder: Strings.email(language.sp),
                text: $email,
                keyboardType: .emailAddress,
                autocapitalization: .never
            )
            StyledTextField(
                placeholder: Strings.password(language.sp),
                text: $password,
                isSecure: true
            )
            Button(Strings.forgotPassword(language.sp)) {
                showForgotPasswordSheet = true
            }
            .font(.caption)
            .foregroundStyle(Color.encoreTextSecondary)
        }
    }

    // MARK: - Sign-up fields

    private var signUpFields: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Account credentials
            sectionLabel(language.sp ? "Cuenta" : "Account")
            StyledTextField(
                placeholder: Strings.email(language.sp),
                text: $email,
                keyboardType: .emailAddress,
                autocapitalization: .never
            )
            StyledTextField(
                placeholder: Strings.password(language.sp),
                text: $password,
                isSecure: true
            )
            StyledTextField(
                placeholder: language.sp ? "Confirmar contraseña" : "Confirm password",
                text: $confirmPassword,
                isSecure: true
            )

            // Personal info
            sectionLabel(language.sp ? "Información personal" : "Personal info")
            HStack(spacing: 10) {
                StyledTextField(
                    placeholder: Strings.firstName(language.sp),
                    text: $firstName
                )
                StyledTextField(
                    placeholder: Strings.lastName(language.sp),
                    text: $lastName
                )
            }

            // Location (country, city, address)
            sectionLabel(language.sp ? "Ubicación" : "Location")
            Button {
                showLocationCountryPicker = true
            } label: {
                HStack {
                    Text(selectedLocationCountry.flag + " " + selectedLocationCountry.name)
                        .foregroundStyle(Color.encoreText)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(Color.encoreTextSecondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            StyledTextField(
                placeholder: Strings.city(language.sp),
                text: $city
            )
            StyledTextField(
                placeholder: language.sp ? "Dirección residencial" : "Residential address",
                text: $address
            )

            // Phone with country code
            sectionLabel(language.sp ? "Contacto" : "Contact")
            phoneRow
        }
    }

    private var phoneRow: some View {
        HStack(spacing: 0) {
            Button {
                showCountryPicker = true
            } label: {
                HStack(spacing: 4) {
                    Text(selectedCountry.flag).font(.body)
                    Text(selectedCountry.dialCode)
                        .font(.body)
                        .foregroundStyle(Color.encoreText)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(Color.encoreTextSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 14)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)

            Spacer().frame(width: 8)

            StyledTextField(
                placeholder: language.sp ? "Teléfono" : "Phone number",
                text: $phoneNumber,
                keyboardType: .numberPad
            )
            .onChange(of: phoneNumber) { newValue in
                let digits = newValue.filter { $0.isNumber }
                if digits.count > 15 {
                    phoneNumber = String(digits.prefix(15))
                } else if newValue != digits {
                    phoneNumber = digits
                }
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.encoreTextSecondary)
            .textCase(.uppercase)
            .tracking(0.5)
    }

    // MARK: - Submit

    private func submit() {
        passwordMismatch = false
        if isSignUp && password != confirmPassword {
            passwordMismatch = true
            return
        }
        isLoading = true
        auth.errorMessage = nil
        Task { @MainActor in
            if isSignUp {
                let trimAddr = address.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimCity = city.trimmingCharacters(in: .whitespacesAndNewlines)
                await auth.signUp(
                    email: email,
                    password: password,
                    role: .renter,
                    name: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                    lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
                    phone: fullPhone.isEmpty ? nil : fullPhone,
                    address: trimAddr.isEmpty ? nil : trimAddr,
                    city: trimCity.isEmpty ? nil : trimCity
                )
            } else {
                await auth.signIn(email: email, password: password)
                if auth.isAuthenticated && auth.currentUser == nil {
                    await auth.ensureProfile(role: .renter)
                }
            }
            isLoading = false
        }
    }
}

// MARK: - Forgot password sheet

struct ForgotPasswordSheet: View {
    let prefilledEmail: String
    let language: LanguageManager
    let auth: AuthManager
    let onDismiss: () -> Void

    @State private var email: String = ""
    @State private var isLoading = false
    @State private var successSent = false

    var body: some View {
        NavigationStack {
            Group {
                if successSent {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(Strings.checkYourEmailReset(language.sp))
                            .font(.body)
                            .foregroundStyle(Color.encoreText)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        StyledTextField(
                            placeholder: Strings.email(language.sp),
                            text: $email,
                            keyboardType: .emailAddress,
                            autocapitalization: .never
                        )
                        if let err = auth.errorMessage {
                            Text(err).font(.caption).foregroundStyle(.red)
                        }
                        Button {
                            sendReset()
                        } label: {
                            Text(Strings.sendResetLink(language.sp))
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.encorePrimary)
                                .cornerRadius(12)
                                .memphisCard(cornerRadius: 12, offset: 3, lineWidth: 2)
                        }
                        .buttonStyle(.plain)
                        .disabled(isLoading || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(24)
                }
            }
            .navigationTitle(Strings.forgotPassword(language.sp))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(successSent ? Strings.done(language.sp) : Strings.cancel(language.sp)) {
                        onDismiss()
                    }
                }
            }
            .onAppear {
                if !prefilledEmail.isEmpty { email = prefilledEmail }
            }
        }
    }

    private func sendReset() {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isLoading = true
        auth.errorMessage = nil
        Task { @MainActor in
            await auth.requestPasswordReset(email: trimmed)
            if auth.errorMessage == nil { successSent = true }
            isLoading = false
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthManager.shared)
        .environmentObject(LanguageManager.shared)
}
