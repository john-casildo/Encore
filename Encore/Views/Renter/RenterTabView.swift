//
//  RenterTabView.swift
//  Encore
//

import SwiftUI

struct RenterTabView: View {
    @EnvironmentObject var language: LanguageManager
    @EnvironmentObject var favorites: FavoritesStore
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            BrowseView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text(Strings.home(language.sp))
                }
                .tag(0)
            NavigationStack {
                FavoritesView()
            }
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text(Strings.saved(language.sp))
                }
                .tag(1)
            MyRentalsView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text(Strings.myRentals(language.sp))
                }
                .tag(2)
            NavigationStack {
                MessagesView()
            }
                .tabItem {
                    Image(systemName: "message.fill")
                    Text(Strings.messages(language.sp))
                }
                .tag(3)
            RenterProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text(Strings.profile(language.sp))
                }
                .tag(4)
        }
        .tint(Color.encorePrimary)
        .onChange(of: selectedTab) { newTab in
            if newTab == 0 { favorites.load() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .encoreGoHome)) { _ in
            selectedTab = 0
        }
    }
}
