//
//  UpgradesView.swift
//  fokusai
//
//  Orb Lab — live preview + four cosmetic slots (core, aura, trail, accent).
//  Softlocked to level. Equipping is instant and persists via AppState.
//  Hover / hold a locked item to peek its real look on the live orb.
//

import SwiftUI

struct UpgradesView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedSlot: CosmeticSlot = .orbCore
    /// Temporarily shown on the live orb while hovering/holding a catalog item.
    @State private var peekItem: CosmeticItem?

    private let columns = [
        GridItem(.flexible(), spacing: Layout.cardSpacing),
        GridItem(.flexible(), spacing: Layout.cardSpacing),
    ]

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    livePreview
                    slotPicker
                    slotHeader
                    itemGrid
                }
                .padding(Layout.screenPadding)
            }
        }
        .navigationTitle("Orb Lab")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Live preview (equipped, or peeked cosmetic)

    private var previewCore: OrbCoreStyle {
        if let peek = peekItem, peek.slot == .orbCore {
            return .named(peek.key)
        }
        return .named(appState.profile.selectedOrbCore)
    }

    private var previewAura: OrbAuraStyle {
        if let peek = peekItem, peek.slot == .orbAura {
            return .named(peek.key)
        }
        return .named(appState.profile.selectedOrbAura)
    }

    private var previewAccentKey: String? {
        guard let peek = peekItem, peek.slot == .appAccent else { return nil }
        return peek.key
    }

    private var livePreview: some View {
        VStack(spacing: 12) {
            ZStack {
                FocusOrb(
                    state: .pulsing,
                    level: appState.currentLevel,
                    core: previewCore,
                    aura: previewAura,
                    activity: .busy,
                    size: 120
                )

                if let peek = peekItem, peek.slot == .trail {
                    TrailEffect(key: peek.key, rim: previewCore.rim)
                        .frame(width: 260, height: 260)
                        .allowsHitTesting(false)
                }
            }
            .frame(maxWidth: .infinity)
            .animation(.fokusSpring, value: peekItem?.id)

            if let peek = peekItem {
                VStack(spacing: 4) {
                    Text(peek.name)
                        .font(.fokusRounded(.headline))
                        .foregroundStyle(Color.textPrimary)
                    Text(
                        appState.isUnlocked(peek)
                            ? peek.blurb
                            : "Preview · Unlock at Lv \(peek.unlockLevel)"
                    )
                        .font(.footnote)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                Text("Level \(appState.currentLevel)")
                    .font(.fokusDisplay(26))
                    .foregroundStyle(Color.textPrimary)

                Text("Everything here unlocks by showing up. No prices, ever.")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .fokusCard()
        .overlay {
            if let accentKey = previewAccentKey {
                RoundedRectangle(cornerRadius: Layout.cardRadius)
                    .stroke(AppAccent.named(accentKey).aura.opacity(0.55), lineWidth: 2)
            }
        }
        .animation(.fokusSpring, value: peekItem?.id)
    }

    private var slotPicker: some View {
        Picker("Slot", selection: $selectedSlot) {
            ForEach(CosmeticSlot.allCases) { slot in
                Text(slot.title).tag(slot)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedSlot) { _, _ in
            peekItem = nil
        }
    }

    private var slotHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(selectedSlot.title)
                .font(.fokusRounded(.headline))
                .foregroundStyle(Color.textPrimary)
            Text(selectedSlot.subtitle)
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)
            if selectedSlot == .orbCore || selectedSlot == .orbAura || selectedSlot == .trail || selectedSlot == .appAccent {
                Text("Hover or hold a locked look to peek it on the orb.")
                    .font(.caption2)
                    .foregroundStyle(Color.textSecondary.opacity(0.85))
            }
        }
    }

    private var itemGrid: some View {
        LazyVGrid(columns: columns, spacing: Layout.cardSpacing) {
            ForEach(CosmeticCatalog.items(in: selectedSlot)) { item in
                let unlocked = appState.isUnlocked(item)
                let equipped = appState.equippedKey(for: item.slot) == item.key
                CosmeticCell(
                    item: item,
                    unlocked: unlocked,
                    equipped: equipped,
                    isPeeking: peekItem?.id == item.id,
                    onPeek: { hovering in
                        withAnimation(.fokusSpring) {
                            if hovering {
                                peekItem = item
                            } else if peekItem?.id == item.id {
                                peekItem = nil
                            }
                        }
                    }
                ) {
                    guard unlocked else { return }
                    Haptics.light()
                    _ = appState.equip(slot: item.slot, itemKey: item.key)
                }
            }
        }
    }
}

// MARK: - Cell

private struct CosmeticCell: View {
    let item: CosmeticItem
    let unlocked: Bool
    let equipped: Bool
    var isPeeking: Bool = false
    var onPeek: ((Bool) -> Void)?
    let onTap: () -> Void

    @State private var isHovering = false
    @State private var holdTask: Task<Void, Never>?

    /// Locked cells reveal full color while peeked/hovered.
    private var showFullLook: Bool {
        unlocked || isPeeking || isHovering
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                preview
                    .frame(height: 64)
                    .saturation(showFullLook ? 1 : 0.25)
                    .opacity(showFullLook ? 1 : 0.55)

                VStack(spacing: 3) {
                    Text(item.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(showFullLook ? Color.textPrimary : Color.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    if unlocked {
                        Text(item.blurb)
                            .font(.caption2)
                            .foregroundStyle(Color.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    } else {
                        Label("Unlock at Lv \(item.unlockLevel)", systemImage: "lock.fill")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 10)
            .fokusCard(fill: equipped || isPeeking ? .surfaceRaised : .surface)
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cardRadius)
                    .stroke(
                        equipped ? Color.focus.opacity(0.6)
                            : (isPeeking ? Color.focus.opacity(0.35) : .clear),
                        lineWidth: 2
                    )
            )
            .overlay(alignment: .topTrailing) {
                if equipped {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.focus)
                        .padding(8)
                } else if !unlocked && isPeeking {
                    Image(systemName: "eye.fill")
                        .font(.caption)
                        .foregroundStyle(Color.focus)
                        .padding(8)
                }
            }
        }
        .onHover { hovering in
            isHovering = hovering
            onPeek?(hovering)
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.4)
                .onEnded { _ in
                    holdTask?.cancel()
                    onPeek?(true)
                    holdTask = Task {
                        try? await Task.sleep(for: .seconds(2.4))
                        guard !Task.isCancelled else { return }
                        await MainActor.run { onPeek?(false) }
                    }
                }
        )
        .buttonTip(
            item.name,
            detail: unlocked
                ? (equipped ? "Equipped. \(item.blurb)" : "Tap to equip. \(item.blurb)")
                : "Locked until Lv \(item.unlockLevel). Hover or hold to preview. \(item.blurb)"
        )
        .accessibilityLabel(accessibilityText)
        .accessibilityHint(unlocked ? "Double tap to equip" : "Hover or long press to preview. Unlocks at level \(item.unlockLevel)")
    }

    private var accessibilityText: String {
        if equipped { return "\(item.name), equipped" }
        if unlocked { return "\(item.name), tap to equip" }
        return "\(item.name), locked, unlock at level \(item.unlockLevel)"
    }

    @ViewBuilder
    private var preview: some View {
        switch item.slot {
        case .orbCore:
            let core = OrbCoreStyle.named(item.key)
            Circle()
                .fill(
                    RadialGradient(
                        stops: [
                            .init(color: core.core, location: 0),
                            .init(color: core.mid, location: 0.55),
                            .init(color: core.rim, location: 1),
                        ],
                        center: UnitPoint(x: 0.5, y: 0.42),
                        startRadius: 0, endRadius: 36
                    )
                )
                .overlay(Circle().strokeBorder(core.rim.opacity(0.5), lineWidth: 1))
                .shadow(color: core.mid.opacity(0.5), radius: 10)
                .frame(width: 56, height: 56)

        case .orbAura:
            ZStack {
                Circle()
                    .strokeBorder(Color.focus.opacity(0.35), lineWidth: item.key == "rings" ? 2 : 0)
                    .frame(width: 52, height: 52)
                Circle()
                    .fill(Color.focus.opacity(0.25))
                    .frame(width: 28, height: 28)
                if item.key == "sparks" || item.key == "comet" {
                    Image(systemName: "sparkle")
                        .font(.caption)
                        .foregroundStyle(Color.focus)
                        .offset(x: 18, y: -14)
                }
            }
            .frame(width: 56, height: 56)

        case .trail:
            Image(systemName: trailSymbol)
                .font(.system(size: 30))
                .foregroundStyle(Color.reward)
                .shadow(color: Color.reward.opacity(0.4), radius: 8)

        case .appAccent:
            let accent = AppAccent.named(item.key)
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [accent.aura.opacity(0.55), Color.bgDeep],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.stroke, lineWidth: 1))
                .frame(width: 72, height: 56)
        }
    }

    private var trailSymbol: String {
        switch item.key {
        case "pulse": return "circle.dotted"
        case "stardust": return "sparkles"
        case "ember_rain": return "flame.fill"
        case "nova": return "sun.max.fill"
        default: return "sparkles"
        }
    }
}

#Preview {
    NavigationStack {
        UpgradesView()
            .environment(AppState())
    }
}
