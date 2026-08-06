//
//  ContentView.swift
//  fokusai
//
//  Created by Navneet Sharma on 2026-07-13.
//

import SwiftUI

struct ContentView: View {
    @State private var showingSplash = true
    @State private var isAuthenticated = SupabaseService.shared.isAuthenticated
    
    var body: some View {
        ZStack {
            if showingSplash {
                SplashView {
                    showingSplash = false
                }
                .transition(.opacity)
            } else {
                if isAuthenticated {
                    HomeView()
                        .transition(.opacity)
                } else {
                    AuthView {
                        withAnimation(.fokusSpring) {
                            isAuthenticated = true
                        }
                    }
                    .transition(.opacity)
                }
            }
        }
        .onAppear {
            // Listen for auth state changes
            Task {
                await SupabaseService.shared.checkSession()
                isAuthenticated = SupabaseService.shared.isAuthenticated
            }
        }
    }
}

#Preview {
    ContentView()
}
