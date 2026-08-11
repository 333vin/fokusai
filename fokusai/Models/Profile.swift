//
//  Profile.swift
//  fokusai
//
//  Maps to the planned backend `profiles`, `upgrades`, and `user_upgrades` tables.
//

import Foundation

struct Profile: Codable {
    let id: UUID
    var createdAt: Date?
    var estimateMultiplier: Double
    var xp: Int
    var level: Int
    var streakCount: Int
    var longestStreak: Int
    var lastActiveDate: Date?
    var freezesAvailable: Int
    var procrastinationType: String?
    var selectedTheme: String
    /// Gamification extension (schema-compatible addition): active orb skin.
    var selectedSkin: String
    /// Gamification extension: active streak-flame flair.
    var selectedFlameFlair: String
    /// Gamification extension: completion sound choice.
    var selectedSound: String

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case estimateMultiplier = "estimate_multiplier"
        case xp, level
        case streakCount = "streak_count"
        case longestStreak = "longest_streak"
        case lastActiveDate = "last_active_date"
        case freezesAvailable = "freezes_available"
        case procrastinationType = "procrastination_type"
        case selectedTheme = "selected_theme"
        case selectedSkin = "selected_skin"
        case selectedFlameFlair = "selected_flame_flair"
        case selectedSound = "selected_sound"
    }

    init(
        id: UUID,
        createdAt: Date? = nil,
        estimateMultiplier: Double = 1.0,
        xp: Int = 0,
        level: Int = 1,
        streakCount: Int = 0,
        longestStreak: Int = 0,
        lastActiveDate: Date? = nil,
        freezesAvailable: Int = 2,
        procrastinationType: String? = nil,
        selectedTheme: String = "deep_focus",
        selectedSkin: String = "deep_focus",
        selectedFlameFlair: String = "classic",
        selectedSound: String = "chime"
    ) {
        self.id = id
        self.createdAt = createdAt
        self.estimateMultiplier = estimateMultiplier
        self.xp = xp
        self.level = level
        self.streakCount = streakCount
        self.longestStreak = longestStreak
        self.lastActiveDate = lastActiveDate
        self.freezesAvailable = freezesAvailable
        self.procrastinationType = procrastinationType
        self.selectedTheme = selectedTheme
        self.selectedSkin = selectedSkin
        self.selectedFlameFlair = selectedFlameFlair
        self.selectedSound = selectedSound
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        estimateMultiplier = try container.decodeIfPresent(Double.self, forKey: .estimateMultiplier) ?? 1.0
        xp = try container.decodeIfPresent(Int.self, forKey: .xp) ?? 0
        level = try container.decodeIfPresent(Int.self, forKey: .level) ?? 1
        streakCount = try container.decodeIfPresent(Int.self, forKey: .streakCount) ?? 0
        longestStreak = try container.decodeIfPresent(Int.self, forKey: .longestStreak) ?? 0
        lastActiveDate = try container.decodeIfPresent(Date.self, forKey: .lastActiveDate)
        freezesAvailable = try container.decodeIfPresent(Int.self, forKey: .freezesAvailable) ?? 2
        procrastinationType = try container.decodeIfPresent(String.self, forKey: .procrastinationType)
        selectedTheme = try container.decodeIfPresent(String.self, forKey: .selectedTheme) ?? "deep_focus"
        selectedSkin = try container.decodeIfPresent(String.self, forKey: .selectedSkin) ?? "deep_focus"
        selectedFlameFlair = try container.decodeIfPresent(String.self, forKey: .selectedFlameFlair) ?? "classic"
        selectedSound = try container.decodeIfPresent(String.self, forKey: .selectedSound) ?? "chime"
    }
}

struct Upgrade: Codable, Identifiable {
    let id: UUID
    let key: String
    let name: String
    let category: String
    let unlockLevel: Int
    let description: String?

    enum CodingKeys: String, CodingKey {
        case id, key, name, category, description
        case unlockLevel = "unlock_level"
    }
}

struct UserUpgrade: Codable {
    let userId: UUID
    let upgradeId: UUID
    let unlockedAt: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case upgradeId = "upgrade_id"
        case unlockedAt = "unlocked_at"
    }
}
