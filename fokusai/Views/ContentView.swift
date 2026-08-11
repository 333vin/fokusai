//
//  ContentView.swift
//  fokusai
//
//  Root flow: splash → interactive tutorial (first run) → Home.
//  Auth is out of scope for the frontend rework; the tutorial replaces it.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var showingSplash = true

    var body: some View {
        ZStack {
            if showingSplash {
                SplashView {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showingSplash = false
                    }
                }
                .transition(.opacity)
            } else if !appState.hasCompletedTutorial {
                TutorialView()
                    .transition(.opacity)
            } else {
                HomeView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: appState.hasCompletedTutorial)
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
