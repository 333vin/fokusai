//
//  MainTabView.swift
//  fokusai
//
//  Primary tabs: Home, Achievements, Profile.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            NavigationStack {
                AchievementsView()
            }
            .tabItem {
                Label("Achievements", systemImage: "trophy.fill")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
        }
        .tint(.brand)
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
}
