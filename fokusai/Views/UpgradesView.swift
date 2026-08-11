//
//  UpgradesView.swift
//  fokusai
//
//  Cosmetic upgrades grid: orb skins, themes, flame flair, sounds.
//  Locked items show the unlock LEVEL, never a price. Tapping an unlocked
//  item applies it immediately.
//

import SwiftUI

struct UpgradesView: View {
    @Environment(AppState.self) private var appState

    private let columns = [
        GridItem(.flexible(), spacing: Layout.cardSpacing),
        GridItem(.flexible(), spacing: Layout.cardSpacing),
    ]

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    ForEach(CosmeticItem.Category.allCases) { category in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(category.title)
                                .font(.fokusRounded(.headline))
                                .foregroundStyle(Color.textPrimary)

                            LazyVGrid(columns: columns, spacing: Layout.cardSpacing) {
                                ForEach(CosmeticCatalog.items(in: category)) { item in
                                    UpgradeCell(
                                        item: item,
                                        unlocked: appState.currentLevel >= item.unlockLevel,
                                        applied: isApplied(item)
                                    ) {
                                        apply(item)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(Layout.screenPadding)
            }
        }
        .navigationTitle("Upgrades")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Level \(appState.currentLevel)")
                .font(.fokusDisplay(30))
                .foregroundStyle(Color.textPrimary)
            Text("Everything here is unlocked by showing up. No prices, ever.")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .fokusCard()
    }

    private func isApplied(_ item: CosmeticItem) -> Bool {
        switch item.category {
        case .orbSkin: return appState.profile.selectedSkin == item.key
        case .theme: return appState.profile.selectedTheme == item.key
        case .flameFlair: return appState.profile.selectedFlameFlair == item.key
        case .sound: return appState.profile.selectedSound == item.key
        }
    }

    private func apply(_ item: CosmeticItem) {
        guard appState.currentLevel >= item.unlockLevel else { return }
        Haptics.light()
        switch item.category {
        case .orbSkin: appState.applySkin(item.key)
        case .theme: appState.applyTheme(item.key)
        case .flameFlair: appState.applyFlameFlair(item.key)
        case .sound:
            appState.applySound(item.key)
            SoundPlayer.playCompletion(item.key)  // instant preview
        }
    }
}

// MARK: - Cell

private struct UpgradeCell: View {
    let item: CosmeticItem
    let unlocked: Bool
    let applied: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                preview
                    .frame(height: 64)
                    .saturation(unlocked ? 1 : 0.25)
                    .opacity(unlocked ? 1 : 0.55)

                VStack(spacing: 3) {
                    Text(item.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(unlocked ? Color.textPrimary : Color.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    if unlocked {
                        Text(item.blurb)
                            .font(.caption2)
                            .foregroundStyle(Color.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    } else {
                        Label("Level \(item.unlockLevel)", systemImage: "lock.fill")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 10)
            .fokusCard(fill: applied ? .surfaceRaised : .surface)
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cardRadius)
                    .stroke(applied ? Color.focus.opacity(0.6) : .clear, lineWidth: 2)
            )
            .overlay(alignment: .topTrailing) {
                if applied {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.focus)
                        .padding(8)
                }
            }
        }
        .disabled(!unlocked)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        if applied { return "\(item.name), applied" }
        if unlocked { return "\(item.name), tap to apply" }
        return "\(item.name), locked, unlocks at level \(item.unlockLevel)"
    }

    @ViewBuilder
    private var preview: some View {
        switch item.category {
        case .orbSkin:
            let skin = OrbSkin.named(item.key)
            Circle()
                .fill(
                    RadialGradient(
                        stops: [
                            .init(color: skin.core, location: 0),
                            .init(color: skin.mid, location: 0.55),
                            .init(color: skin.rim, location: 1),
                        ],
                        center: UnitPoint(x: 0.5, y: 0.42),
                        startRadius: 0, endRadius: 36
                    )
                )
                .overlay(Circle().strokeBorder(skin.rim.opacity(0.5), lineWidth: 1))
                .shadow(color: skin.mid.opacity(0.5), radius: 10)
                .frame(width: 56, height: 56)

        case .theme:
            let theme = AppTheme.named(item.key)
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [theme.aura.opacity(0.5), Color.bgDeep],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.stroke, lineWidth: 1))
                .frame(width: 72, height: 56)

        case .flameFlair:
            Image(systemName: "flame.fill")
                .font(.system(size: 36))
                .foregroundStyle(FlameFlair.color(for: item.key))
                .shadow(color: FlameFlair.color(for: item.key).opacity(0.5), radius: 10)

        case .sound:
            Image(systemName: item.key == "silent" ? "speaker.slash.fill" : "speaker.wave.2.fill")
                .font(.system(size: 32))
                .foregroundStyle(Color.brand)
        }
    }
}

#Preview {
    NavigationStack {
        UpgradesView()
            .environment(AppState())
    }
}
