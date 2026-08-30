//
//  AppBackground.swift
//  fokusai
//
//  The app's ambient room: deep background with an accent-tinted aura wash.
//  Reads the equipped appAccent from AppState so accents apply live.
//

import SwiftUI

struct AppBackground: View {
    @Environment(AppState.self) private var appState: AppState?

    /// Override for previews / tutorial (which run without full state).
    var themeKey: String?

    private var accent: AppAccent {
        AppAccent.named(themeKey ?? appState?.profile.selectedAppAccent ?? "midnight")
    }

    var body: some View {
        ZStack {
            Color.bgDeep.ignoresSafeArea()
            LinearGradient(
                stops: [
                    .init(color: accent.aura.opacity(0.14), location: 0),
                    .init(color: accent.aura.opacity(0.04), location: 0.35),
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
    AppBackground(themeKey: "violet")
}
