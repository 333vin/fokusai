//
//  AppBackground.swift
//  fokusai
//
//  The app's ambient room: deep background with a theme-tinted aura wash.
//  Reads the active theme from AppState so theme upgrades apply live.
//

import SwiftUI

struct AppBackground: View {
    @Environment(AppState.self) private var appState: AppState?

    /// Override for previews / tutorial (which run without full state).
    var themeKey: String?

    private var theme: AppTheme {
        AppTheme.named(themeKey ?? appState?.profile.selectedTheme ?? "deep_focus")
    }

    var body: some View {
        ZStack {
            Color.bgDeep.ignoresSafeArea()
            LinearGradient(
                stops: [
                    .init(color: theme.aura.opacity(0.14), location: 0),
                    .init(color: theme.aura.opacity(0.04), location: 0.35),
                    .init(color: .clear, location: 0.7),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}

#Preview {
    AppBackground(themeKey: "violet_night")
}
