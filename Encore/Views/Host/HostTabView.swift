//
//  HostTabView.swift
//  Encore
//

import SwiftUI

struct HostTabView: View {
    @EnvironmentObject var language: LanguageManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HostDashboardView()
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text(Strings.dashboard(language.sp))
            }
            .tag(0)
            HostListingsView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text(Strings.yourListings(language.sp))
                }
                .tag(1)
            NavigationStack {
                HostBookingsView()
            }
            .tabItem {
                Image(systemName: "calendar")
                Text(Strings.reservations(language.sp))
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
            HostProfileView()
                .tabItem {
                    Image(systemName: "line.3.horizontal")
                    Text(Strings.menu(language.sp))
                }
                .tag(4)
        }
        .tint(Color.encorePrimary)
    }
}
