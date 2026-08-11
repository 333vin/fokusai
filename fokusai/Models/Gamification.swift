//
//  Gamification.swift
//  fokusai
//
//  Model types for the gamification engine: completion outcomes, rewards,
//  chests, achievements, and locally persisted player stats.
//

import Foundation

// MARK: - Completion

enum CompletionOutcome {
    case done          // +10 XP, counts toward streak
    case ranOutOfTime  // +5 XP — showing up counts; step stays available
}

// MARK: - Focus Chest

/// Variable reward, done ethically: always positive, never a loss,
/// never a purchase prompt.
enum ChestReward: Equatable {
    case bonusXP(Int)
    case shard
    case kindMessage(String)
}

// MARK: - Reward Result

/// Everything a completion earned, returned synchronously so the UI can play
/// the reward sequence.
struct RewardResult {
    var xpAwarded: Int = 0
    var outcome: CompletionOutcome = .done
    var leveledUpTo: Int?
    var chest: ChestReward?
    var unlockedAchievements: [Achievement] = []
    var streakAdvancedTo: Int?
    var usedFreeze: Bool = false
    var streakWasReset: Bool = false
    var wholeTaskCompleted: Bool = false
}

// MARK: - Achievements

struct Achievement: Identifiable, Equatable {
    let id: String
    let name: String
    let blurb: String
    let symbol: String
    let xpBonus: Int
}

extension Achievement {
    static let all: [Achievement] = [
        Achievement(id: "first_step", name: "First Step",
                    blurb: "Complete your first microtask. Statistically the hardest one.",
                    symbol: "figure.walk", xpBonus: 15),
        Achievement(id: "momentum", name: "Momentum",
                    blurb: "Keep a 3-day streak going.",
                    symbol: "flame.fill", xpBonus: 20),
        Achievement(id: "deep_diver", name: "Deep Diver",
                    blurb: "Finish an entire task, first step to last.",
                    symbol: "checkmark.seal.fill", xpBonus: 25),
        Achievement(id: "night_owl", name: "Night Owl",
                    blurb: "Complete a step after 10pm. Respect.",
                    symbol: "moon.stars.fill", xpBonus: 15),
        Achievement(id: "early_bird", name: "Early Bird",
                    blurb: "Complete a step before 9am. Who even are you?",
                    symbol: "sunrise.fill", xpBonus: 15),
        Achievement(id: "on_a_roll", name: "On a Roll",
                    blurb: "Complete 10 microtasks in total.",
                    symbol: "bolt.fill", xpBonus: 20),
        Achievement(id: "chest_magnet", name: "Chest Magnet",
                    blurb: "Open 3 Focus Chests.",
                    symbol: "shippingbox.fill", xpBonus: 15),
        Achievement(id: "seven_circles", name: "Seven Circles",
                    blurb: "Keep a 7-day streak. Certified habit behavior.",
                    symbol: "calendar", xpBonus: 30),
    ]

    static func byID(_ id: String) -> Achievement? {
        all.first { $0.id == id }
    }
}

// MARK: - Player Stats (local, mock persistence)

/// Counters that back achievements and the weekly freeze refill.
/// Kept separate from Profile so the backend schema stays untouched.
struct PlayerStats: Codable {
    var totalMicrotasksCompleted = 0
    var totalTasksCompleted = 0
    var chestsOpened = 0
    var shardsCollected = 0
    /// Distinct active days counted in the current week (for freeze refill).
    var activeDaysThisWeek = 0
    /// Start of the week `activeDaysThisWeek` refers to.
    var weekAnchor: Date?
}

// MARK: - Level math

enum LevelMath {
    /// Cumulative XP required to *reach* `level` (L2 @ 50, L3 @ 150, L4 @ 300…).
    static func xpToReach(level: Int) -> Int {
        guard level > 1 else { return 0 }
        let n = level - 1
        return 50 * n * (n + 1) / 2
    }

    static func level(forXP xp: Int) -> Int {
        var level = 1
        while xp >= xpToReach(level: level + 1) {
            level += 1
        }
        return level
    }

    /// Progress 0…1 through the current level.
    static func progress(forXP xp: Int) -> Double {
        let current = level(forXP: xp)
        let floor = xpToReach(level: current)
        let ceiling = xpToReach(level: current + 1)
        guard ceiling > floor else { return 0 }
        return Double(xp - floor) / Double(ceiling - floor)
    }
}
