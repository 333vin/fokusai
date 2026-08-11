//
//  AppState.swift
//  fokusai
//
//  Central observable state + the gamification engine (XP, levels, forgiving
//  streaks, freezes, Focus Chests, achievements). Everything runs on mock
//  data: profile/stats persist locally via UserDefaults, tasks live in memory
//  and mirror into the mock DatabaseService so the backend wiring can swap in
//  later without touching views.
//

import Foundation
import Observation

@Observable
class AppState {
    // MARK: - State

    var tasks: [TaskItem] = []
    var profile: Profile
    var stats: PlayerStats
    var unlockedAchievementIDs: Set<String>
    var hasCompletedTutorial: Bool

    /// Surfaced once, warmly, after a freeze silently saved the streak.
    var pendingFreezeNotice = false
    /// Surfaced once, warmly, after a real streak break.
    var pendingStreakResetNotice = false

    private let database = DatabaseService()

    private enum Keys {
        static let profile = "fokusai.profile"
        static let stats = "fokusai.stats"
        static let achievements = "fokusai.achievements"
        static let tutorialDone = "fokusai.tutorialDone"
    }

    // MARK: - Init / persistence

    init() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: Keys.profile),
           let saved = try? JSONDecoder().decode(Profile.self, from: data) {
            profile = saved
        } else {
            profile = Profile(id: UUID(), createdAt: Date())
        }
        if let data = defaults.data(forKey: Keys.stats),
           let saved = try? JSONDecoder().decode(PlayerStats.self, from: data) {
            stats = saved
        } else {
            stats = PlayerStats()
        }
        unlockedAchievementIDs = Set(defaults.stringArray(forKey: Keys.achievements) ?? [])
        hasCompletedTutorial = defaults.bool(forKey: Keys.tutorialDone)
    }

    private func persist() {
        let defaults = UserDefaults.standard
        if let data = try? JSONEncoder().encode(profile) {
            defaults.set(data, forKey: Keys.profile)
        }
        if let data = try? JSONEncoder().encode(stats) {
            defaults.set(data, forKey: Keys.stats)
        }
        defaults.set(Array(unlockedAchievementIDs), forKey: Keys.achievements)
        defaults.set(hasCompletedTutorial, forKey: Keys.tutorialDone)

        let snapshot = profile
        Task { try? await database.updateProfile(snapshot) }
    }

    // MARK: - Derived values

    var currentXP: Int { profile.xp }
    var currentLevel: Int { profile.level }
    var streakCount: Int { profile.streakCount }
    var xpProgress: Double { LevelMath.progress(forXP: profile.xp) }
    var xpIntoCurrentLevel: Int { profile.xp - LevelMath.xpToReach(level: currentLevel) }
    var xpNeededForNextLevel: Int {
        LevelMath.xpToReach(level: currentLevel + 1) - LevelMath.xpToReach(level: currentLevel)
    }
    var activeTasks: [TaskItem] { tasks.filter { $0.status == .active } }

    var isActiveToday: Bool {
        guard let last = profile.lastActiveDate else { return false }
        return Calendar.current.isDateInToday(last)
    }

    // MARK: - Task operations

    func addTask(_ task: TaskItem) {
        var newTask = task
        newTask.userId = profile.id
        tasks.insert(newTask, at: 0)

        let snapshot = newTask
        Task { _ = try? await database.createTask(snapshot, microtasks: snapshot.microtasks) }
    }

    func deleteTask(_ taskId: UUID) {
        tasks.removeAll { $0.id == taskId }
        Task { try? await database.deleteTask(id: taskId) }
    }

    func task(withID id: UUID) -> TaskItem? {
        tasks.first { $0.id == id }
    }

    // MARK: - The completion moment (gamification engine)

    /// Marks a microtask outcome and returns everything it earned, so the UI
    /// can play the reward sequence. Both outcomes are wins.
    @discardableResult
    func completeMicrotask(
        taskId: UUID,
        microtaskId: UUID,
        outcome: CompletionOutcome,
        actualMinutes: Int,
        allowChest: Bool = true
    ) -> RewardResult {
        var result = RewardResult(outcome: outcome)
        let oldLevel = LevelMath.level(forXP: profile.xp)

        guard let taskIndex = tasks.firstIndex(where: { $0.id == taskId }),
              let mtIndex = tasks[taskIndex].microtasks.firstIndex(where: { $0.id == microtaskId })
        else { return result }

        switch outcome {
        case .done:
            tasks[taskIndex].microtasks[mtIndex].status = .done
            tasks[taskIndex].microtasks[mtIndex].completedAt = Date()
            tasks[taskIndex].microtasks[mtIndex].actualMinutes = actualMinutes
            stats.totalMicrotasksCompleted += 1
            result.xpAwarded += 10

            let isFirstOfDay = !isActiveToday
            let streakChange = advanceStreak()
            result.streakAdvancedTo = streakChange.advancedTo
            result.usedFreeze = streakChange.usedFreeze
            result.streakWasReset = streakChange.wasReset
            if streakChange.usedFreeze { pendingFreezeNotice = true }
            if streakChange.wasReset { pendingStreakResetNotice = true }

            if tasks[taskIndex].isComplete {
                tasks[taskIndex].status = .done
                stats.totalTasksCompleted += 1
                result.xpAwarded += 25
                result.wholeTaskCompleted = true
            }

            // Focus Chest: variable, always positive, never a loss.
            if allowChest, let chest = rollChest(isFirstOfDay: isFirstOfDay) {
                result.chest = chest
                stats.chestsOpened += 1
                if case .bonusXP(let bonus) = chest { result.xpAwarded += bonus }
                if case .shard = chest { stats.shardsCollected += 1 }
            }

        case .ranOutOfTime:
            // Showing up counts. The step stays available to pick up again.
            result.xpAwarded += 5
        }

        profile.xp += result.xpAwarded

        result.unlockedAchievements = checkAchievements()
        let achievementXP = result.unlockedAchievements.reduce(0) { $0 + $1.xpBonus }
        profile.xp += achievementXP
        result.xpAwarded += achievementXP

        let newLevel = LevelMath.level(forXP: profile.xp)
        if newLevel > oldLevel {
            profile.level = newLevel
            result.leveledUpTo = newLevel
        }

        persist()
        if outcome == .done {
            let snapshot = tasks[taskIndex]
            Task {
                try? await database.completeMicrotask(id: microtaskId, actualMinutes: actualMinutes)
                try? await database.updateTask(snapshot)
            }
        }
        return result
    }

    // MARK: - Streaks (forgiving by design)

    private struct StreakChange {
        var advancedTo: Int?
        var usedFreeze = false
        var wasReset = false
    }

    private func advanceStreak(now: Date = Date()) -> StreakChange {
        var change = StreakChange()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)

        rolloverWeekIfNeeded(today: today, calendar: calendar)

        if let last = profile.lastActiveDate {
            let lastDay = calendar.startOfDay(for: last)
            if lastDay == today {
                return change  // today already counts; nothing to advance
            }
            let gap = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 1
            let missedDays = gap - 1
            if missedDays == 0 {
                profile.streakCount += 1
            } else if missedDays <= profile.freezesAvailable && profile.streakCount > 0 {
                // A missed day silently consumes a freeze and preserves the streak.
                profile.freezesAvailable -= missedDays
                profile.streakCount += 1
                change.usedFreeze = true
            } else {
                // Streaks restart. Progress doesn't.
                profile.streakCount = 1
                change.wasReset = true
            }
        } else {
            profile.streakCount = 1
        }

        profile.lastActiveDate = now
        profile.longestStreak = max(profile.longestStreak, profile.streakCount)
        stats.activeDaysThisWeek += 1
        change.advancedTo = profile.streakCount
        return change
    }

    /// Freezes refill +1 (cap 3) for any week with 4+ active days.
    private func rolloverWeekIfNeeded(today: Date, calendar: Calendar) {
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        guard stats.weekAnchor != weekStart else { return }
        if stats.weekAnchor != nil && stats.activeDaysThisWeek >= 4 {
            profile.freezesAvailable = min(profile.freezesAvailable + 1, 3)
        }
        stats.weekAnchor = weekStart
        stats.activeDaysThisWeek = 0
    }

    // MARK: - Focus Chest

    private func rollChest(isFirstOfDay: Bool) -> ChestReward? {
        // ~1 in 5, weighted up for the first completion of the day.
        let chance = isFirstOfDay ? 0.35 : 0.2
        guard Double.random(in: 0..<1) < chance else { return nil }
        switch Int.random(in: 0..<3) {
        case 0: return .bonusXP(Int.random(in: 5...20))
        case 1: return .shard
        default: return .kindMessage(Copy.random(.chestKindMessage))
        }
    }

    // MARK: - Achievements

    private func checkAchievements(now: Date = Date()) -> [Achievement] {
        var newlyUnlocked: [Achievement] = []
        func unlock(_ id: String, when condition: Bool) {
            guard condition,
                  !unlockedAchievementIDs.contains(id),
                  let achievement = Achievement.byID(id) else { return }
            unlockedAchievementIDs.insert(id)
            newlyUnlocked.append(achievement)
        }

        let hour = Calendar.current.component(.hour, from: now)
        unlock("first_step", when: stats.totalMicrotasksCompleted >= 1)
        unlock("momentum", when: profile.streakCount >= 3)
        unlock("deep_diver", when: stats.totalTasksCompleted >= 1)
        unlock("night_owl", when: stats.totalMicrotasksCompleted >= 1 && hour >= 22)
        unlock("early_bird", when: stats.totalMicrotasksCompleted >= 1 && (4..<9).contains(hour))
        unlock("on_a_roll", when: stats.totalMicrotasksCompleted >= 10)
        unlock("chest_magnet", when: stats.chestsOpened >= 3)
        unlock("seven_circles", when: profile.streakCount >= 7)
        return newlyUnlocked
    }

    // MARK: - Tutorial

    /// Beat 2: stores the one piece of self-knowledge we ask for.
    func setProcrastinationType(_ type: String) {
        profile.procrastinationType = type
        persist()
    }

    /// Ends the tutorial (beat 5 or skip) and lands the user on Home.
    func completeTutorial() {
        hasCompletedTutorial = true
        persist()
    }

    // MARK: - Customization (Phase 7 applies these live)

    func applySkin(_ key: String) {
        profile.selectedSkin = key
        persist()
    }

    func applyTheme(_ key: String) {
        profile.selectedTheme = key
        persist()
    }

    func applyFlameFlair(_ key: String) {
        profile.selectedFlameFlair = key
        persist()
    }

    func applySound(_ key: String) {
        profile.selectedSound = key
        persist()
    }

    // MARK: - Reset (mock sign-out)

    func resetAllData() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Keys.profile)
        defaults.removeObject(forKey: Keys.stats)
        defaults.removeObject(forKey: Keys.achievements)
        defaults.removeObject(forKey: Keys.tutorialDone)

        tasks = []
        profile = Profile(id: UUID(), createdAt: Date())
        stats = PlayerStats()
        unlockedAchievementIDs = []
        hasCompletedTutorial = false
        pendingFreezeNotice = false
        pendingStreakResetNotice = false
    }

    #if DEBUG
    /// Dev convenience: populate Home with the sample tasks from MockData.
    func loadSampleTasks() {
        for task in MockData.sampleTasks where !tasks.contains(where: { $0.id == task.id }) {
            tasks.append(task)
        }
    }
    #endif
}
