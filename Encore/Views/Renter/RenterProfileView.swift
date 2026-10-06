//
//  RenterProfileView.swift
//  Encore
//

import SwiftUI

struct RenterProfileView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var language: LanguageManager
    @EnvironmentObject var theme: ThemeManager
    @State private var showSignOutAlert = false
    @State private var isSwitchingToHost = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    profileHeader
                    linksSection
                    settingsSection
                    signOutSection
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .background(Color.encoreFrame.ignoresSafeArea())
            .navigationTitle(Strings.profile(language.sp))
            .onAppear { auth.errorMessage = nil }
            .task { await auth.refreshUser() }
        }
    }

    // MARK: - Profile header card

    private var profileHeader: some View {
        NavigationLink(destination: ProfileDetailView()) {
            HStack(spacing: 16) {
                ProfileAvatarView(url: auth.currentUser?.avatarUrl, size: 72)
                    .overlay(Circle().stroke(Color.primary, lineWidth: 2))
                VStack(alignment: .leading, spacing: 4) {
                    Text(auth.currentUser?.displayName ?? "—")
                        .font(.title3.weight(.black))
                        .foregroundStyle(Color.encoreText)
                    locationDisplay
                    Text(language.sp ? "Ver mi perfil" : "View my profile")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.encorePrimary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.encoreTextSecondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .memphisCard(cornerRadius: 16, offset: 4, lineWidth: 1.5)
            .id("\(auth.currentUser?.displayName ?? "")-\(auth.currentUser?.avatarUrl ?? "")")
        }
        .buttonStyle(.plain)
    }

    private var locationDisplay: some View {
        LocationChipView(
            city: auth.currentUser?.city?.trimmingCharacters(in: .whitespacesAndNewlines),
            country: CountryDialCode.forIso(auth.currentUser?.countryIso)
        )
    }

    // MARK: - Nav links section

    private var linksSection: some View {
        VStack(spacing: 0) {
            navRow(icon: "heart.fill", iconColor: Color.encorePink, label: Strings.saved(language.sp)) {
                AnyView(FavoritesView())
            }
            Divider().padding(.horizontal)
            navRow(icon: "person.crop.circle", iconColor: Color.encorePrimary, label: Strings.editProfile(language.sp)) {
                AnyView(EditProfileView())
            }
            if let user = auth.currentUser {
                Divider().padding(.horizontal)
                NavigationLink(destination: UserReviewsListView(userId: user.id, userName: user.displayName)) {
                    HStack(spacing: 12) {
                        iconCircle("star.bubble", color: Color.encoreAccent)
                        Text(language.sp ? "Mis reseñas" : "My Reviews")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.encoreText)
                        Spacer()
                        if (user.reviewCount ?? 0) > 0 {
                            Text("\(user.reviewCount ?? 0)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.encoreAccent)
                                .clipShape(Capsule())
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.encoreTextSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
            }
            Divider().padding(.horizontal)
            Divider().padding(.horizontal)
            navRow(icon: "creditcard.fill", iconColor: Color.encorePrimary, label: language.sp ? "Métodos de pago" : "Payment Methods") {
                AnyView(PaymentMethodsView())
            }
            navRow(icon: "questionmark.circle", iconColor: Color.encoreTeal, label: Strings.getHelp(language.sp)) {
                AnyView(HelpView())
            }
            Divider().padding(.horizontal)
            navRow(icon: "lock.shield", iconColor: Color.encoreBlue, label: Strings.privacy(language.sp)) {
                AnyView(PrivacySettingsView())
            }
            Divider().padding(.horizontal)
            navRow(icon: "doc.text", iconColor: Color.encoreOrange, label: Strings.legal(language.sp)) {
                AnyView(LegalView())
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .memphisCard(cornerRadius: 16, offset: 4, lineWidth: 1.5)
    }

    // MARK: - Settings section

    private var settingsSection: some View {
        VStack(spacing: 0) {
            // Language
            HStack(spacing: 12) {
                iconCircle("globe", color: Color.encoreGreen)
                Text(Strings.language(language.sp))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.encoreText)
                Spacer()
                Picker("", selection: $language.language) {
                    Text("English").tag(AppLanguage.english)
                    Text("Español").tag(AppLanguage.spanish)
                }
                .pickerStyle(.menu)
                .tint(Color.encorePrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider().padding(.horizontal)

            // Appearance
            HStack(spacing: 12) {
                iconCircle("moon.circle.fill", color: Color.encorePrimaryDark)
                Text(language.sp ? "Apariencia" : "Appearance")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.encoreText)
                Spacer()
                Picker("", selection: $theme.theme) {
                    Text(language.sp ? "Sistema" : "System").tag(AppTheme.system)
                    Text(language.sp ? "Claro" : "Light").tag(AppTheme.light)
                    Text(language.sp ? "Oscuro" : "Dark").tag(AppTheme.dark)
                }
                .pickerStyle(.menu)
                .tint(Color.encorePrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider().padding(.horizontal)

            // Switch to host
            Button {
                auth.errorMessage = nil
                isSwitchingToHost = true
                Task {
                    await auth.setRole(.host)
                    await MainActor.run { isSwitchingToHost = false }
                }
            } label: {
                HStack(spacing: 12) {
                    iconCircle("house.fill", color: Color.encoreOrange)
                    Text(Strings.switchToHostMode(language.sp))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.encoreText)
                    Spacer()
                    if isSwitchingToHost {
                        ProgressView().scaleEffect(0.9)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.encoreTextSecondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .disabled(isSwitchingToHost)

            if let err = auth.errorMessage {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .memphisCard(cornerRadius: 16, offset: 4, lineWidth: 1.5)
    }

    // MARK: - Sign out

    private var signOutSection: some View {
        Button {
            showSignOutAlert = true
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.encoreCoral.opacity(0.15))
                        .frame(width: 32, height: 32)
                        .overlay(Circle().stroke(Color.encoreCoral, lineWidth: 1.5))
                    Image(systemName: "arrow.right.square")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.encoreCoral)
                }
                Text(Strings.signOut(language.sp))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.encoreCoral)
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.encoreCoral, lineWidth: 1.5))
            .shadow(color: Color.encoreCoral, radius: 0, x: 3, y: 3)
        }
        .buttonStyle(.plain)
        .confirmationDialog(Strings.signOutConfirmTitle(language.sp), isPresented: $showSignOutAlert, titleVisibility: .visible) {
            Button(Strings.signOut(language.sp), role: .destructive) { auth.signOut() }
            Button(Strings.cancel(language.sp), role: .cancel) { }
        } message: {
            Text(Strings.signOutConfirmMessage(language.sp))
        }
    }

    // MARK: - Helpers

    private func iconCircle(_ icon: String, color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.18))
                .frame(width: 32, height: 32)
                .overlay(Circle().stroke(Color.primary.opacity(0.5), lineWidth: 1))
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
        }
    }

    private func navRow(icon: String, iconColor: Color, label: String, dest: @escaping () -> AnyView) -> some View {
        NavigationLink(destination: dest()) {
            HStack(spacing: 12) {
                iconCircle(icon, color: iconColor)
                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.encoreText)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.encoreTextSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Profile detail view (shared by renter + host)

struct ProfileDetailView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var language: LanguageManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                avatarCard
                if hasAnyInfo { infoCard }
                editButton
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .background(Color.encoreFrame.ignoresSafeArea())
        .navigationTitle(language.sp ? "Mi perfil" : "My Profile")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Avatar card

    private var avatarCard: some View {
        VStack(spacing: 14) {
            ProfileAvatarView(url: auth.currentUser?.avatarUrl, size: 100)
                .overlay(Circle().stroke(Color.primary, lineWidth: 2.5))
                .shadow(color: Color.primary.opacity(0.5), radius: 0, x: 4, y: 4)

            VStack(spacing: 6) {
                Text(auth.currentUser?.displayName ?? "—")
                    .font(.title2.weight(.black))
                    .foregroundStyle(Color.encoreText)

                if let rating = auth.currentUser?.rating,
                   let count = auth.currentUser?.reviewCount, count > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(Color.encoreAccent)
                        Text(String(format: "%.2f", rating))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.encoreText)
                        Text("(\(count))")
                            .font(.caption)
                            .foregroundStyle(Color.encoreTextSecondary)
                    }
                }

                if auth.currentUser?.isVerified == true {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(Color.encorePrimary)
                        Text(language.sp ? "Verificado" : "Verified")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.encorePrimary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.encoreLightPurple)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.encorePrimary, lineWidth: 1.5))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .memphisCard(cornerRadius: 16, offset: 4, lineWidth: 1.5)
    }

    // MARK: - Info card

    private var hasAnyInfo: Bool {
        let u = auth.currentUser
        return !(u?.bio ?? "").isEmpty ||
               !(u?.city ?? "").isEmpty ||
               !(u?.countryIso ?? "").isEmpty ||
               !(u?.phone ?? "").isEmpty ||
               !(u?.email ?? "").isEmpty
    }

    private var infoCard: some View {
        VStack(spacing: 0) {
            let u = auth.currentUser
            let country = CountryDialCode.forIso(u?.countryIso)
            let hasLocation = !(u?.city ?? "").isEmpty || country != nil

            let hasPhone = !(u?.phone ?? "").isEmpty
            let hasEmail = !(u?.email ?? "").isEmpty

            // Bio
            if let bio = u?.bio, !bio.isEmpty {
                infoRow(icon: "text.quote", label: language.sp ? "Bio" : "Bio", color: Color.encoreTeal) {
                    Text(bio)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.encoreText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if hasLocation || hasPhone || hasEmail { Divider().padding(.horizontal) }
            }

            // Location (city, country)
            if hasLocation {
                let city = u?.city?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let countryName = country?.name ?? ""
                let locValue = [city, countryName].filter { !$0.isEmpty }.joined(separator: ", ")
                infoRow(icon: "mappin.circle.fill", label: language.sp ? "Ubicación" : "Location", color: Color.encoreGreen) {
                    Text(locValue)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.encoreText)
                }
                if hasPhone || hasEmail { Divider().padding(.horizontal) }
            }

            // Phone
            if hasPhone, let phone = u?.phone {
                infoRow(icon: "phone.fill", label: language.sp ? "Teléfono" : "Phone", color: Color.encorePink) {
                    Text(phone)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.encoreText)
                }
                if hasEmail { Divider().padding(.horizontal) }
            }

            // Email
            if hasEmail, let email = u?.email {
                infoRow(icon: "envelope.fill", label: language.sp ? "Correo" : "Email", color: Color.encoreBlue) {
                    Text(email)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.encoreText)
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .memphisCard(cornerRadius: 16, offset: 4, lineWidth: 1.5)
    }

    private func infoRow<Content: View>(icon: String, label: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.18))
                    .frame(width: 32, height: 32)
                    .overlay(Circle().stroke(Color.primary.opacity(0.3), lineWidth: 1))
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.encoreTextSecondary)
                content()
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Edit button

    private var editButton: some View {
        VStack(spacing: 12) {
            NavigationLink(destination: EditProfileView()) {
                HStack(spacing: 10) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.body.weight(.bold))
                    Text(language.sp ? "Editar perfil" : "Edit Profile")
                        .font(.headline.weight(.black))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.encorePrimary)
                .cornerRadius(14)
                .memphisCard(cornerRadius: 14, offset: 4, lineWidth: 2)
            }
            .buttonStyle(.plain)

            NavigationLink(destination: PaymentMethodsView()) {
                HStack(spacing: 10) {
                    Image(systemName: "creditcard.fill")
                        .font(.body.weight(.bold))
                    Text(language.sp ? "Métodos de pago" : "Payment Methods")
                        .font(.headline.weight(.black))
                }
                .foregroundStyle(Color.encoreText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
                .cornerRadius(14)
                .memphisCard(cornerRadius: 14, offset: 4, lineWidth: 1.5)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Payment Methods View

struct PaymentMethodsView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var language: LanguageManager

    @State private var cards: [PaymentMethodRow] = []
    @State private var isLoading = true
    @State private var showAddCard = false
    @State private var toast: Toast?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 120)
                } else if cards.isEmpty {
                    MemphisEmptyView(
                        icon: "creditcard.fill",
                        circleColor: Color.encorePrimary,
                        accentColor: Color.encoreAccent,
                        secondAccent: Color.encorePink,
                        title: language.sp ? "Sin tarjetas guardadas" : "No saved cards",
                        subtitle: language.sp ? "Agrega una tarjeta para pagar más rápido." : "Add a card to check out faster."
                    )
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(cards.enumerated()), id: \.element.id) { idx, card in
                            cardRow(card)
                            if idx < cards.count - 1 { Divider().padding(.horizontal) }
                        }
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .memphisCard(cornerRadius: 16, offset: 4, lineWidth: 1.5)
                }

                // Add card button
                Button { showAddCard = true } label: {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.encorePrimary.opacity(0.15))
                                .frame(width: 28, height: 28)
                                .overlay(Circle().stroke(Color.encorePrimary, lineWidth: 1.5))
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(Color.encorePrimary)
                        }
                        Text(language.sp ? "Agregar tarjeta" : "Add card")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.encorePrimary)
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(14)
                    .memphisCard(cornerRadius: 14, offset: 3, lineWidth: 1.5)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .background(Color.encoreFrame.ignoresSafeArea())
        .navigationTitle(language.sp ? "Métodos de pago" : "Payment Methods")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showAddCard, onDismiss: { Task { await loadCards() } }) {
            AddCardSheet()
                .environmentObject(AuthManager.shared)
                .environmentObject(LanguageManager.shared)
        }
        .toast($toast)
        .task { await loadCards() }
    }

    private func cardRow(_ card: PaymentMethodRow) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(cardColor(card.brand ?? "").opacity(0.15))
                    .frame(width: 44, height: 32)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary, lineWidth: 1))
                Image(systemName: cardIcon(card.brand ?? ""))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(cardColor(card.brand ?? ""))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(card.brand?.capitalized ?? "Card") •••• \(card.last4 ?? "——")")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.encoreText)
                Text(language.sp ? "Exp. \(card.expiryMonth ?? 0)/\(card.expiryYear ?? 0)" : "Expires \(card.expiryMonth ?? 0)/\(card.expiryYear ?? 0)")
                    .font(.caption)
                    .foregroundStyle(Color.encoreTextSecondary)
            }
            Spacer()
            Button {
                Task { await deleteCard(card) }
            } label: {
                Image(systemName: "trash")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.encoreCoral)
                    .padding(8)
                    .background(Color.encoreCoral.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func cardColor(_ brand: String) -> Color {
        switch brand.lowercased() {
        case "visa":       return Color.encoreBlue
        case "mastercard": return Color.encoreOrange
        case "amex":       return Color.encoreGreen
        default:           return Color.encorePrimary
        }
    }

    private func cardIcon(_ brand: String) -> String {
        switch brand.lowercased() {
        case "visa":       return "creditcard"
        case "mastercard": return "creditcard.fill"
        case "amex":       return "creditcard.and.123"
        default:           return "creditcard"
        }
    }

    private func loadCards() async {
        guard let uid = auth.session?.userId else {
            await MainActor.run { isLoading = false }
            return
        }
        do {
            let query = [URLQueryItem(name: "user_id", value: "eq.\(uid.uuidString)"),
                         URLQueryItem(name: "order", value: "created_at.desc")]
            let rows: [PaymentMethodRow] = try await SupabaseClient.shared.fetch(table: "payment_methods", query: query)
            await MainActor.run { cards = rows; isLoading = false }
        } catch {
            print("[PaymentMethodsView] load failed: \(error)")
            await MainActor.run { isLoading = false }
        }
    }

    private func deleteCard(_ card: PaymentMethodRow) async {
        let url = URL(string: "\(SupabaseConfig.restURL)/payment_methods?id=eq.\(card.id.uuidString)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        if let token = SupabaseClient.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        _ = try? await URLSession.shared.data(for: request)
        await MainActor.run { cards.removeAll { $0.id == card.id } }
        toast = Toast(message: language.sp ? "Tarjeta eliminada" : "Card removed")
    }
}

// MARK: - Add Card Sheet

private struct AddCardSheet: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var language: LanguageManager
    @Environment(\.dismiss) private var dismiss

    @State private var cardNumber = ""
    @State private var cardHolder = ""
    @State private var cardExpiry = ""
    @State private var cardCVV = ""
    @State private var cardError: String?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Card preview
                    ZStack(alignment: .bottomLeading) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.encorePrimary)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary, lineWidth: 2))
                            .memphisShadow(x: 4, y: 4)
                            .frame(height: 140)
                        VStack(alignment: .leading, spacing: 8) {
                            Image(systemName: "creditcard.fill")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.white.opacity(0.8))
                            Spacer()
                            Text(formattedDisplay)
                                .font(.system(size: 18, weight: .black, design: .monospaced))
                                .foregroundStyle(.white)
                            Text(cardHolder.isEmpty ? (language.sp ? "NOMBRE TITULAR" : "CARDHOLDER NAME") : cardHolder.uppercased())
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(20)
                    }
                    .padding(.horizontal)

                    // Fields
                    VStack(spacing: 1) {
                        addCardField(placeholder: language.sp ? "Número de tarjeta" : "Card number",
                                     text: $cardNumber, keyboardType: .numberPad, icon: "creditcard", formatter: formatCardNumber)
                        Divider().padding(.leading, 50)
                        addCardField(placeholder: language.sp ? "Nombre del titular" : "Cardholder name",
                                     text: $cardHolder, keyboardType: .default, icon: "person")
                        Divider().padding(.leading, 50)
                        HStack(spacing: 0) {
                            addCardField(placeholder: "MM / YY", text: $cardExpiry,
                                         keyboardType: .numberPad, icon: "calendar", formatter: formatExpiry)
                            Divider().frame(height: 44)
                            addCardField(placeholder: "CVV", text: $cardCVV,
                                         keyboardType: .numberPad, icon: "lock", isSecure: true)
                                .onChange(of: cardCVV) { _ in
                                    let digits = cardCVV.filter { $0.isNumber }
                                    let capped = String(digits.prefix(3))
                                    if cardCVV != capped { cardCVV = capped }
                                }
                        }
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(14)
                    .memphisCard(cornerRadius: 14, offset: 3, lineWidth: 1.5)
                    .padding(.horizontal)

                    if let err = cardError {
                        Text(err).font(.caption).foregroundStyle(.red).padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color.encoreFrame.ignoresSafeArea())
            .navigationTitle(language.sp ? "Nueva tarjeta" : "New Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language.sp ? "Cancelar" : "Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(language.sp ? "Guardar" : "Save") {
                        Task { await saveCard() }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    private var formattedDisplay: String {
        let digits = cardNumber.filter { $0.isNumber }.prefix(16)
        if digits.isEmpty { return language.sp ? "•••• •••• •••• ••••" : "•••• •••• •••• ••••" }
        var result = ""
        for (i, ch) in digits.enumerated() {
            if i > 0 && i % 4 == 0 { result += " " }
            result.append(ch)
        }
        let remaining = 16 - digits.count
        if remaining > 0 {
            for i in 0..<remaining {
                if (digits.count + i) % 4 == 0 && digits.count + i > 0 { result += " " }
                result += "•"
            }
        }
        return result
    }

    private func addCardField(placeholder: String, text: Binding<String>,
                               keyboardType: UIKeyboardType, icon: String,
                               formatter: ((String) -> String)? = nil, isSecure: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).frame(width: 20).foregroundStyle(Color.encorePrimary)
            if isSecure {
                SecureField(placeholder, text: text).keyboardType(keyboardType)
            } else {
                TextField(placeholder, text: text)
                    .keyboardType(keyboardType)
                    .onChange(of: text.wrappedValue) { _ in
                        if let fmt = formatter {
                            let f = fmt(text.wrappedValue)
                            if f != text.wrappedValue { text.wrappedValue = f }
                        }
                    }
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 50)
    }

    private func formatCardNumber(_ raw: String) -> String {
        let digits = raw.filter { $0.isNumber }.prefix(16)
        var result = ""
        for (i, ch) in digits.enumerated() {
            if i > 0 && i % 4 == 0 { result += " " }
            result.append(ch)
        }
        return result
    }

    private func formatExpiry(_ raw: String) -> String {
        let digits = raw.filter { $0.isNumber }.prefix(4)
        if digits.count <= 2 { return String(digits) }
        return "\(digits.prefix(2)) / \(digits.dropFirst(2))"
    }

    private func cardBrand(from number: String) -> String {
        let d = number.filter { $0.isNumber }
        if d.hasPrefix("4") { return "visa" }
        if d.hasPrefix("5") || d.hasPrefix("2") { return "mastercard" }
        if d.hasPrefix("34") || d.hasPrefix("37") { return "amex" }
        return "card"
    }

    private func saveCard() async {
        let digits = cardNumber.filter { $0.isNumber }
        let expiryDigits = cardExpiry.filter { $0.isNumber }
        guard digits.count >= 13 else {
            cardError = language.sp ? "Número de tarjeta inválido." : "Invalid card number."; return
        }
        guard cardHolder.trimmingCharacters(in: .whitespaces).count >= 2 else {
            cardError = language.sp ? "Ingresa el nombre del titular." : "Enter cardholder name."; return
        }
        guard expiryDigits.count == 4,
              let month = Int(expiryDigits.prefix(2)), month >= 1, month <= 12,
              let year = Int(expiryDigits.suffix(2)) else {
            cardError = language.sp ? "Fecha de expiración inválida." : "Invalid expiry date."; return
        }
        guard cardCVV.filter({ $0.isNumber }).count >= 3 else {
            cardError = language.sp ? "CVV inválido." : "Invalid CVV."; return
        }
        guard let uid = auth.session?.userId else { return }

        cardError = nil
        isSaving = true

        let fullYear = 2000 + year
        do {
            // Unset existing default first to avoid unique constraint violation
            let unsetUrl = URL(string: "\(SupabaseConfig.restURL)/payment_methods?user_id=eq.\(uid.uuidString)&is_default=eq.true")!
            var unsetReq = URLRequest(url: unsetUrl)
            unsetReq.httpMethod = "PATCH"
            unsetReq.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
            unsetReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if let token = SupabaseClient.shared.accessToken {
                unsetReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            unsetReq.httpBody = try? JSONSerialization.data(withJSONObject: ["is_default": false])
            _ = try? await URLSession.shared.data(for: unsetReq)

            let body: [String: Any] = [
                "user_id": uid.uuidString,
                "stripe_pm_id": "manual_\(UUID().uuidString)",
                "brand": cardBrand(from: cardNumber),
                "last4": String(digits.suffix(4)),
                "expiry_month": month,
                "expiry_year": fullYear,
                "is_default": true
            ]
            _ = try await SupabaseClient.shared.insert(table: "payment_methods", body: body)
            await MainActor.run { isSaving = false; dismiss() }
        } catch {
            await MainActor.run { isSaving = false; cardError = error.localizedDescription }
        }
    }
}
