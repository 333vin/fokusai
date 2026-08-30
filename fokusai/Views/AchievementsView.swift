//
//  AchievementsView.swift
//  fokusai
//
//  Full achievements collection — unlocked and locked — as its own tab.
//

import SwiftUI

struct AchievementsView: View {
    @Environment(AppState.self) private var appState

    private var unlockedCount: Int {
        Achievement.all.filter { appState.unlockedAchievementIDs.contains($0.id) }.count
    }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: Layout.cardSpacing) {
                    summaryCard

                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Achievement.all) { achievement in
                            achievementRow(achievement)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fokusCard()
                }
                .padding(Layout.screenPadding)
            }
        }
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summaryCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "trophy.fill")
                .font(.title2)
                .foregroundStyle(Color.reward)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.surfaceRaised))

            VStack(alignment: .leading, spacing: 2) {
                Text("\(unlockedCount) of \(Achievement.all.count) unlocked")
                    .font(.fokusRounded(.headline))
                    .foregroundStyle(Color.textPrimary)
                Text("Tiny wins that stick. Keep showing up.")
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
        }
        .padding(16)
        .fokusCard()
        .accessibilityElement(children: .combine)
    }

    private func achievementRow(_ achievement: Achievement) -> some View {
        let unlocked = appState.unlockedAchievementIDs.contains(achievement.id)
        return HStack(spacing: 12) {
            Image(systemName: achievement.symbol)
                .font(.body)
                .foregroundStyle(unlocked ? Color.reward : Color.textSecondary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(unlocked ? Color.textPrimary : Color.textSecondary)
                Text(achievement.blurb)
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
            if unlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.success)
            } else {
                Text("+\(achievement.xpBonus) XP")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(achievement.name), \(unlocked ? "unlocked" : "locked"). \(achievement.blurb)")
    }
}

#Preview {
    NavigationStack {
        AchievementsView()
            .environment(AppState())
    }
}
