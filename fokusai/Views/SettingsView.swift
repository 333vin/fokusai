//
//  SettingsView.swift
//  fokusai
//
//  Profile & settings: level, XP, streaks (longest preserved separately),
//  freezes, achievements, daily reminder, tutorial replay, mock sign-out.
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @AppStorage("fokusai.reminderEnabled") private var reminderEnabled = false
    @AppStorage("fokusai.reminderTime") private var reminderTimeInterval: Double = defaultReminderTime

    @State private var showingTutorial = false
    @State private var showingResetConfirmation = false

    private static var defaultReminderTime: Double {
        let components = DateComponents(hour: 16, minute: 30)
        let date = Calendar.current.nextDate(after: Date(), matching: components, matchingPolicy: .nextTime) ?? Date()
        return date.timeIntervalSinceReferenceDate
    }

    private var reminderTime: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSinceReferenceDate: reminderTimeInterval) },
            set: { newValue in
                reminderTimeInterval = newValue.timeIntervalSinceReferenceDate
                if reminderEnabled {
                    ReminderService.scheduleDaily(at: newValue)
                }
            }
        )
    }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(spacing: Layout.cardSpacing) {
                    profileHeader
                    statsCard
                    achievementsCard
                    reminderCard
                    actionsCard
                }
                .padding(Layout.screenPadding)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showingTutorial) {
            TutorialView(isReplay: true) {
                showingTutorial = false
            }
        }
        .confirmationDialog(
            "Reset everything?",
            isPresented: $showingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset all data", role: .destructive) {
                appState.resetAllData()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears your XP, streaks, and tasks on this device. (Mock sign-out. Real accounts come later.)")
        }
    }

    // MARK: Sections

    private var profileHeader: some View {
        VStack(spacing: 14) {
            FocusOrb(
                state: .dim,
                level: appState.currentLevel,
                skin: .named(appState.profile.selectedSkin),
                size: 90
            )

            Text("Level \(appState.currentLevel)")
                .font(.fokusDisplay(28))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 6) {
                ProgressView(value: appState.xpProgress)
                    .tint(.focus)
                Text("\(appState.xpIntoCurrentLevel) / \(appState.xpNeededForNextLevel) XP to level \(appState.currentLevel + 1)")
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .fokusCard()
    }

    private var statsCard: some View {
        VStack(spacing: 0) {
            statRow(symbol: "flame.fill", tint: FlameFlair.color(for: appState.profile.selectedFlameFlair),
                    title: "Current streak",
                    value: appState.streakCount == 1 ? "1 day" : "\(appState.streakCount) days")
            Divider().overlay(Color.stroke)
            statRow(symbol: "trophy.fill", tint: .reward,
                    title: "Longest streak",
                    value: appState.profile.longestStreak == 1 ? "1 day" : "\(appState.profile.longestStreak) days")
            Divider().overlay(Color.stroke)
            statRow(symbol: "snowflake", tint: .focus,
                    title: "Streak freezes",
                    value: "\(appState.profile.freezesAvailable) of 3")
            Divider().overlay(Color.stroke)
            statRow(symbol: "sparkle", tint: .brand,
                    title: "Cosmetic shards",
                    value: "\(appState.stats.shardsCollected)")
        }
        .fokusCard()
    }

    private func statRow(symbol: String, tint: Color, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.body)
                .foregroundStyle(tint)
                .frame(width: 28)
            Text(title)
                .font(.body)
                .foregroundStyle(Color.textPrimary)
            Spacer()
            Text(value)
                .font(.fokusRounded(.body))
                .foregroundStyle(Color.textPrimary)
        }
        .padding(14)
        .accessibilityElement(children: .combine)
    }

    private var achievementsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.fokusRounded(.headline))
                .foregroundStyle(Color.textPrimary)

            ForEach(Achievement.all) { achievement in
                let unlocked = appState.unlockedAchievementIDs.contains(achievement.id)
                HStack(spacing: 12) {
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
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fokusCard()
    }

    private var reminderCard: some View {
        VStack(spacing: 12) {
            Toggle(isOn: Binding(
                get: { reminderEnabled },
                set: { enabled in
                    reminderEnabled = enabled
                    if enabled {
                        ReminderService.scheduleDaily(at: reminderTime.wrappedValue)
                    } else {
                        ReminderService.cancel()
                    }
                }
            )) {
                Label("Daily reminder", systemImage: "bell.fill")
                    .font(.body)
                    .foregroundStyle(Color.textPrimary)
            }
            .tint(.brand)

            if reminderEnabled {
                DatePicker("Remind me at", selection: reminderTime, displayedComponents: .hourAndMinute)
                    .font(.body)
                    .foregroundStyle(Color.textPrimary)
            }
        }
        .padding(16)
        .fokusCard()
    }

    private var actionsCard: some View {
        VStack(spacing: 0) {
            Button {
                showingTutorial = true
            } label: {
                HStack {
                    Label("Replay tutorial", systemImage: "arrow.counterclockwise.circle.fill")
                        .foregroundStyle(Color.brand)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(14)
            }

            Divider().overlay(Color.stroke)

            #if DEBUG
            Button {
                appState.loadSampleTasks()
            } label: {
                HStack {
                    Label("Load sample tasks (debug)", systemImage: "tray.and.arrow.down.fill")
                        .foregroundStyle(Color.textSecondary)
                    Spacer()
                }
                .padding(14)
            }
            Divider().overlay(Color.stroke)
            #endif

            Button(role: .destructive) {
                showingResetConfirmation = true
            } label: {
                HStack {
                    Label("Sign out (resets mock data)", systemImage: "rectangle.portrait.and.arrow.right")
                        .foregroundStyle(Color.textSecondary)
                    Spacer()
                }
                .padding(14)
            }
        }
        .font(.body)
        .fokusCard()
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(AppState())
    }
}
