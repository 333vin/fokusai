//
//  StatBar.swift
//  fokusai
//
//  Compact Home stat bar: level + XP progress ring, streak flame with count,
//  and the tap-through entry to Upgrades. Also reused by the tutorial tour.
//

import SwiftUI

// MARK: - XP Ring

struct XPRing: View {
    let level: Int
    let progress: Double
    var size: CGFloat = 46

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.surfaceRaised, lineWidth: 5)
            Circle()
                .trim(from: 0, to: max(0.001, min(progress, 1)))
                .stroke(
                    AngularGradient(
                        colors: [.brand, .focus],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Text("\(level)")
                .font(.fokusDisplay(size * 0.38))
                .foregroundStyle(Color.textPrimary)
                .minimumScaleFactor(0.6)
        }
        .frame(width: size, height: size)
        .animation(.fokusSpring, value: progress)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Level \(level), \(Int(progress * 100)) percent to next level")
    }
}

// MARK: - Streak Flame

struct StreakFlame: View {
    let count: Int
    var flairKey: String = "classic"

    private var flameColor: Color {
        count > 0 ? FlameFlair.color(for: flairKey) : .textSecondary
    }

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "flame.fill")
                .font(.body)
                .foregroundStyle(flameColor)
            Text("\(count)")
                .font(.fokusDisplay(20))
                .foregroundStyle(count > 0 ? Color.textPrimary : Color.textSecondary)
                .contentTransition(.numericText())
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(count == 1 ? "1 day streak" : "\(count) day streak")
    }
}

// MARK: - Stat Bar

struct StatBar: View {
    let level: Int
    let xpProgress: Double
    let xp: Int
    let streak: Int
    var flairKey: String = "classic"
    var onTapUpgrades: (() -> Void)?

    var body: some View {
        HStack(spacing: 14) {
            XPRing(level: level, progress: xpProgress)

            VStack(alignment: .leading, spacing: 2) {
                Text("Level \(level)")
                    .font(.fokusRounded(.subheadline))
                    .foregroundStyle(Color.textPrimary)
                Text("\(xp) XP")
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
                    .contentTransition(.numericText())
            }

            Spacer()

            StreakFlame(count: streak, flairKey: flairKey)

            if let onTapUpgrades {
                Button(action: onTapUpgrades) {
                    Image(systemName: "sparkles")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.brand)
                        .padding(10)
                        .background(Circle().fill(Color.surfaceRaised))
                }
                .accessibilityLabel("Upgrades")
            }
        }
        .padding(.horizontal, Layout.screenPadding)
        .padding(.vertical, 12)
        .fokusCard()
    }
}

#Preview {
    ZStack {
        Color.bgDeep.ignoresSafeArea()
        StatBar(level: 4, xpProgress: 0.6, xp: 420, streak: 6, onTapUpgrades: {})
            .padding()
    }
}
