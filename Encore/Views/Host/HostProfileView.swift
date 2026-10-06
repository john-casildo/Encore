//
//  HostProfileView.swift
//  Encore
//

import SwiftUI

struct HostProfileView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var language: LanguageManager
    @EnvironmentObject var theme: ThemeManager
    @State private var showSignOutConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    profileHeader
                    hostLinksSection
                    generalLinksSection
                    settingsSection
                    signOutSection
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .background(Color.encoreFrame.ignoresSafeArea())
            .navigationTitle(Strings.menu(language.sp))
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

    // MARK: - Host-specific links

    private var hostLinksSection: some View {
        VStack(spacing: 0) {
            navRow(icon: "calendar", iconColor: Color.encorePrimary, label: Strings.reservations(language.sp)) {
                AnyView(HostBookingsView())
            }
            Divider().padding(.horizontal)
            navRow(icon: "dollarsign.circle", iconColor: Color.encoreGreen, label: Strings.earnings(language.sp)) {
                AnyView(HostDashboardView())
            }
            Divider().padding(.horizontal)
            navRow(icon: "chart.bar", iconColor: Color.encoreBlue, label: Strings.insights(language.sp)) {
                AnyView(HostInsightsPlaceholderView())
            }
            Divider().padding(.horizontal)
            navRow(icon: "plus.circle", iconColor: Color.encoreAccent, label: Strings.createNewListing(language.sp)) {
                AnyView(AddInstrumentView())
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .memphisCard(cornerRadius: 16, offset: 4, lineWidth: 1.5)
    }

    // MARK: - General links

    private var generalLinksSection: some View {
        VStack(spacing: 0) {
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

            Button {
                Task { @MainActor in await auth.setRole(.renter) }
            } label: {
                HStack(spacing: 12) {
                    iconCircle("person.fill", color: Color.encorePink)
                    Text(Strings.switchToRenterMode(language.sp))
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
            showSignOutConfirm = true
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
        .confirmationDialog(Strings.signOutConfirmTitle(language.sp), isPresented: $showSignOutConfirm, titleVisibility: .visible) {
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
