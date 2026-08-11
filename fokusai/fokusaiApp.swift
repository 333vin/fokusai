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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
    }
}
