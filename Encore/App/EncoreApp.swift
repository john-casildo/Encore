//
//  EncoreApp.swift
//  Encore
//

import SwiftUI

@main
struct EncoreApp: App {
    @StateObject private var auth = AuthManager.shared
    @StateObject private var language = LanguageManager.shared
    @StateObject private var favorites = FavoritesStore.shared
    @StateObject private var theme = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(language)
                .environmentObject(favorites)
                .environmentObject(theme)
                .preferredColorScheme(theme.colorScheme)
        }
    }
}

// MARK: - Root (auth vs main)

struct RootView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var favorites: FavoritesStore

    var body: some View {
        Group {
            if auth.shouldShowMainApp {
                MainTabRootView()
            } else if auth.isAuthenticated && !auth.hasFinishedRestoreValidation {
                SplashView()
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut, value: auth.shouldShowMainApp)
        .task { await auth.validateSessionIfNeeded() }
        .onChange(of: auth.isAuthenticated) { isLoggedIn in
            if isLoggedIn { favorites.load() }
            else { favorites.clear() }
        }
    }
}

// MARK: - Splash / loading screen

struct SplashView: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "4C1D95"), Color(hex: "7C3AED")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Image("EncoreLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulse ? 1.08 : 1.0)
                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)

                Text("Encore")
                    .font(.largeTitle.weight(.black))
                    .foregroundStyle(.white)
                    .tracking(2)

                ProgressView()
                    .tint(.white)
                    .padding(.top, 8)
            }
        }
        .onAppear { pulse = true }
    }
}

// MARK: - Role-based tab root (placeholder until Renter/Host views exist)

struct MainTabRootView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var favorites: FavoritesStore

    var body: some View {
        Group {
            switch auth.role {
            case .renter:
                RenterTabView()
            case .host:
                HostTabView()
            }
        }
        .background(Color(.systemBackground))
        .animation(nil, value: auth.role)
        .onAppear {
            if auth.isAuthenticated { favorites.load() }
        }
    }
}
