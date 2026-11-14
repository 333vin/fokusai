//
//  fokusaiApp.swift
//  fokusai
//
//  Created by Navneet Sharma on 2026-07-13.
//

import SwiftUI

@main
struct fokusaiApp: App {
    @State private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                AnalyticsService.log("app_opened")
            }
        }
    }
}
