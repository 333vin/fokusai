//
//  OrbLabView.swift
//  fokusai
//
//  Dev-only preview screen that exercises all FocusOrb states, levels, and
//  skins. Reachable from Home via a DEBUG-only toolbar button.
//

import SwiftUI

struct OrbLabView: View {
    @State private var orbState: OrbState = .dim
    @State private var level = 1
    @State private var skin: OrbSkin = .deepFocus

    /// Test palettes so skin swapping can be exercised before Phase 7 ships
    /// real unlockables.
    private static let testSkins: [OrbSkin] = [
        .deepFocus,
        OrbSkin(key: "test_ember", name: "Ember (test)", core: .brandDeep, mid: .reward, rim: .focus),
        OrbSkin(key: "test_mint", name: "Mint (test)", core: .brandDeep, mid: .success, rim: .focus),
    ]

    var body: some View {
        ZStack {
            Color.bgDeep.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                FocusOrb(state: orbState, level: level, skin: skin)

                Spacer()

                controls
            }
        }
        .navigationTitle("Orb Lab")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var controls: some View {
        VStack(spacing: 16) {
            Picker("State", selection: $orbState) {
                Text("Dim").tag(OrbState.dim)
                Text("Pulsing").tag(OrbState.pulsing)
                Text("Flare").tag(OrbState.flare)
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
                    in: 1...10, step: 1
                )
                .tint(.brand)
            }

            Picker("Skin", selection: $skin) {
                ForEach(Self.testSkins) { testSkin in
                    Text(testSkin.name).tag(testSkin)
                }
            }
            .pickerStyle(.segmented)

            Button("Replay flare") {
                orbState = .dim
                Task {
                    try? await Task.sleep(for: .milliseconds(80))
                    orbState = .flare
                }
            }
            .font(.fokusRounded(.subheadline))
            .foregroundStyle(Color.focus)
        }
        .padding(Layout.screenPadding)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardRadius)
                .fill(Color.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: Layout.cardRadius)
                        .stroke(Color.stroke, lineWidth: 1)
                )
        )
        .padding(Layout.screenPadding)
    }
}

extension OrbSkin: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }
}

#Preview {
    NavigationStack {
        OrbLabView()
    }
}
