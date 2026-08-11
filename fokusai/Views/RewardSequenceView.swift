//
//  RewardSequenceView.swift
//  fokusai
//
//  The completion moment (Section 9.4): orb flare → XP counts into the ring
//  → optional achievement, level-up, and Focus Chest beats. Each beat stays
//  under ~1.2s, auto-advances, and is always skippable by tapping.
//  Reward GOLD appears only here — level-ups and chests.
//

import SwiftUI

struct RewardSequenceView: View {
    let result: RewardResult
    let orbLevel: Int
    let orbSkin: OrbSkin
    let onFinish: () -> Void

    private enum Stage: Int, Equatable {
        case xp
        case achievements
        case levelUp
        case chestClosed
        case chestOpened
    }

    @State private var stage: Stage = .xp
    @State private var ringProgress: Double = 0
    @State private var chestBounce = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var preXP: Int {
        max(0, xpAfter - result.xpAwarded)
    }
    // The engine already applied the XP; read the "after" from level math inputs.
    private var xpAfter: Int { _xpAfter }
    private let _xpAfter: Int

    init(result: RewardResult, xpAfter: Int, orbLevel: Int, orbSkin: OrbSkin, onFinish: @escaping () -> Void) {
        self.result = result
        self._xpAfter = xpAfter
        self.orbLevel = orbLevel
        self.orbSkin = orbSkin
        self.onFinish = onFinish
    }

    var body: some View {
        ZStack {
            Color.bgDeep.opacity(0.97).ignoresSafeArea()

            switch stage {
            case .xp: xpStage
            case .achievements: achievementsStage
            case .levelUp: levelUpStage
            case .chestClosed, .chestOpened: chestStage
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { advance() }
        .onAppear { runXPStage() }
        .accessibilityAddTraits(.isModal)
    }

    // MARK: Stage flow

    private var stagesAfterXP: [Stage] {
        var stages: [Stage] = []
        if !result.unlockedAchievements.isEmpty { stages.append(.achievements) }
        if result.leveledUpTo != nil { stages.append(.levelUp) }
        if result.chest != nil { stages.append(.chestClosed) }
        return stages
    }

    private func advance() {
        switch stage {
        case .chestClosed:
            Haptics.success()
            withAnimation(.fokusCelebration) { stage = .chestOpened }
        case .chestOpened:
            onFinish()
        default:
            let currentOrder = stage.rawValue
            let remaining = stagesAfterXP.drop(while: { $0.rawValue <= currentOrder })
            if let next = remaining.first {
                withAnimation(.fokusCelebration) { stage = next }
                if next == .levelUp { Haptics.success() }
            } else {
                onFinish()
            }
        }
    }

    private func runXPStage() {
        ringProgress = LevelMath.progress(forXP: preXP)
        withAnimation(.easeOut(duration: 0.8).delay(0.15)) {
            ringProgress = result.leveledUpTo != nil ? 1.0 : LevelMath.progress(forXP: xpAfter)
        }
        autoAdvance(after: 1.4)
    }

    private func autoAdvance(after seconds: Double) {
        let current = stage
        Task {
            try? await Task.sleep(for: .seconds(seconds))
            if stage == current, current != .chestClosed, current != .chestOpened {
                advance()
            }
        }
    }

    // MARK: XP stage

    private var xpStage: some View {
        VStack(spacing: 24) {
            ZStack {
                FocusOrb(
                    state: result.outcome == .done ? .flare : .pulsing,
                    level: orbLevel,
                    skin: orbSkin,
                    size: 120
                )
                if result.outcome == .done {
                    ConfettiBurst(colors: [.focus, .brand, .textPrimary])
                        .frame(width: 300, height: 300)
                }
            }

            Text("+\(result.xpAwarded) XP")
                .font(.fokusDisplay(44))
                .foregroundStyle(Color.focus)
                .transition(.scale.combined(with: .opacity))

            XPRing(level: orbLevel, progress: ringProgress, size: 54)

            Text(result.outcome == .done ? Copy.random(.completion) : Copy.random(.ranOutOfTime))
                .font(.body)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if result.wholeTaskCompleted {
                Label("Whole task finished, +25 bonus inside", systemImage: "checkmark.seal.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.success)
            }

            Text("Tap to continue")
                .font(.caption)
                .foregroundStyle(Color.textSecondary.opacity(0.7))
                .padding(.top, 8)
        }
        .transition(.opacity)
        .onAppear { autoAdvance(after: 1.4) }
    }

    // MARK: Achievements stage

    private var achievementsStage: some View {
        VStack(spacing: 20) {
            Text("Achievement unlocked")
                .font(.fokusRounded(.headline))
                .foregroundStyle(Color.textSecondary)

            ForEach(result.unlockedAchievements) { achievement in
                HStack(spacing: 14) {
                    Image(systemName: achievement.symbol)
                        .font(.title2)
                        .foregroundStyle(Color.reward)
                        .frame(width: 40)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(achievement.name)
                            .font(.fokusRounded(.title3))
                            .foregroundStyle(Color.textPrimary)
                        Text(achievement.blurb)
                            .font(.footnote)
                            .foregroundStyle(Color.textSecondary)
                    }
                    Spacer()
                    Text("+\(achievement.xpBonus)")
                        .font(.fokusDisplay(20))
                        .foregroundStyle(Color.reward)
                }
                .padding(16)
                .fokusCard(fill: .surfaceRaised)
                .padding(.horizontal, Layout.screenPadding)
            }

            Text("Tap to continue")
                .font(.caption)
                .foregroundStyle(Color.textSecondary.opacity(0.7))
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .onAppear { autoAdvance(after: 1.6) }
    }

    // MARK: Level-up stage (the biggest dopamine beat — gold territory)

    private var levelUpStage: some View {
        VStack(spacing: 24) {
            ZStack {
                FocusOrb(state: .flare, level: result.leveledUpTo ?? orbLevel, skin: orbSkin, size: 150)
                ConfettiBurst(colors: [.reward, .reward, .focus, .textPrimary], particleCount: 44)
                    .frame(width: 340, height: 340)
            }

            Text("LEVEL \(result.leveledUpTo ?? orbLevel)")
                .font(.fokusDisplay(52))
                .foregroundStyle(Color.reward)
                .shadow(color: Color.reward.opacity(0.5), radius: 18)

            Text(Copy.random(.levelUp))
                .font(.body)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("Continue") { advance() }
                .fokusPrimaryCapsule()
                .padding(.top, 6)
        }
        .transition(.scale(scale: 0.9).combined(with: .opacity))
    }

    // MARK: Chest stage

    private var chestStage: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.reward.opacity(stage == .chestOpened ? 0.5 : 0.25), .clear],
                            center: .center, startRadius: 0, endRadius: 130
                        )
                    )
                    .frame(width: 260, height: 260)

                if stage == .chestOpened {
                    ConfettiBurst(colors: [.reward, .reward, .textPrimary])
                        .frame(width: 300, height: 300)
                }

                Image(systemName: stage == .chestOpened ? "shippingbox.and.arrow.backward.fill" : "shippingbox.fill")
                    .font(.system(size: 76))
                    .foregroundStyle(Color.reward)
                    .scaleEffect(chestBounce && !reduceMotion ? 1.06 : 1.0)
                    .animation(
                        reduceMotion ? nil : .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                        value: chestBounce
                    )
                    .onAppear { chestBounce = true }
            }

            if stage == .chestOpened {
                VStack(spacing: 10) {
                    Text(chestRevealTitle)
                        .font(.fokusDisplay(30))
                        .foregroundStyle(Color.reward)
                    Text(chestRevealSubtitle)
                        .font(.body)
                        .foregroundStyle(Color.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                }
                .transition(.scale.combined(with: .opacity))

                Button("Nice") { onFinish() }
                    .fokusPrimaryCapsule()
                    .padding(.top, 6)
            } else {
                VStack(spacing: 8) {
                    Text("A Focus Chest appeared!")
                        .font(.fokusRounded(.title3))
                        .foregroundStyle(Color.textPrimary)
                    Text("Tap to open. It's always something good.")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .transition(.opacity)
    }

    private var chestRevealTitle: String {
        switch result.chest {
        case .bonusXP(let amount): return "+\(amount) bonus XP"
        case .shard: return "A cosmetic shard!"
        case .kindMessage: return "A note for you"
        case nil: return ""
        }
    }

    private var chestRevealSubtitle: String {
        switch result.chest {
        case .bonusXP: return Copy.random(.chestOpen)
        case .shard: return "Collect them for bragging rights. \(Copy.random(.chestOpen))"
        case .kindMessage(let message): return message
        case nil: return ""
        }
    }
}

#Preview("Level up + chest") {
    RewardSequenceView(
        result: RewardResult(
            xpAwarded: 35,
            outcome: .done,
            leveledUpTo: 3,
            chest: .bonusXP(12),
            unlockedAchievements: [Achievement.all[0]],
            streakAdvancedTo: 2,
            wholeTaskCompleted: true
        ),
        xpAfter: 160,
        orbLevel: 3,
        orbSkin: .deepFocus
    ) {}
}
