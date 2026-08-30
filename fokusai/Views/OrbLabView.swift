//
//  OrbLabView.swift
//  fokusai
//
//  DEBUG playground for orb state / activity / level. Core + aura colors
//  always match what's currently equipped in the player's Orb Lab.
//

import SwiftUI

struct OrbLabView: View {
    @Environment(AppState.self) private var appState

    @State private var orbState: OrbState = .dim
    @State private var activity: OrbActivity = .neutral
    @State private var level = 1

    private var equippedCore: OrbCoreStyle {
        .named(appState.profile.selectedOrbCore)
    }

    private var equippedAura: OrbAuraStyle {
        .named(appState.profile.selectedOrbAura)
    }

    private var previewFace: String {
        OrbFace.glyph(state: orbState, activity: activity)
    }

    var body: some View {
        ZStack {
            Color.bgDeep.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                FocusOrb(
                    state: orbState,
                    level: level,
                    core: equippedCore,
                    aura: equippedAura,
                    activity: activity
                )

                VStack(spacing: 4) {
                    Text(previewFace)
                        .font(.fokusDisplay(28))
                        .foregroundStyle(Color.textPrimary)
                    Text("\(equippedCore.name) · \(equippedAura.name)")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                controls
            }
        }
        .navigationTitle("Orb Debug")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            level = appState.currentLevel
        }
    }

    private var controls: some View {
        VStack(spacing: 16) {
            Picker("State", selection: $orbState) {
                Text("Dim").tag(OrbState.dim)
                Text("Pulsing").tag(OrbState.pulsing)
                Text("Flare").tag(OrbState.flare)
            }
            .pickerStyle(.segmented)

            Picker("Activity", selection: $activity) {
                Text("Neutral").tag(OrbActivity.neutral)
                Text("Idle").tag(OrbActivity.idle)
                Text("Busy").tag(OrbActivity.busy)
                Text("Focus").tag(OrbActivity.focusing)
                Text("Think").tag(OrbActivity.thinking)
                Text("Win").tag(OrbActivity.celebrating)
                Text("Soft").tag(OrbActivity.softWin)
            }
            .pickerStyle(.segmented)

            HStack {
                Text("Level \(level)")
                    .font(.fokusRounded(.body))
                    .foregroundStyle(Color.textPrimary)
                    .frame(width: 90, alignment: .leading)
                Slider(
                    value: Binding(
                        get: { Double(level) },
                        set: { level = Int($0) }
                    ),
                    in: 1...20, step: 1
                )
                .tint(.brand)
            }

            Text("Core & aura follow your equipped Orb Lab cosmetics.")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button("Replay flare") {
                orbState = .dim
                Task {
                    try? await Task.sleep(for: .milliseconds(80))
                    orbState = .flare
                    activity = .celebrating
                }
            }
            .font(.fokusRounded(.subheadline))
            .foregroundStyle(Color.focus)
        }
        .padding(Layout.screenPadding)
        .fokusCard()
        .padding(Layout.screenPadding)
    }
}

#Preview {
    NavigationStack {
        OrbLabView()
            .environment(AppState())
    }
}
