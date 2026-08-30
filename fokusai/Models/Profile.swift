//
//  Profile.swift
//  fokusai
//
//  Maps to the planned backend `profiles`, `upgrades`, and `user_upgrades` tables.
//  Cosmetic slots: orbCore, orbAura, trail, appAccent — local UserDefaults for now.
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

    // MARK: Cosmetic slots (equipped item keys)
    var selectedOrbCore: String
    var selectedOrbAura: String
    var selectedTrail: String
    var selectedAppAccent: String

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
        case selectedOrbCore = "selected_orb_core"
        case selectedOrbAura = "selected_orb_aura"
        case selectedTrail = "selected_trail"
        case selectedAppAccent = "selected_app_accent"
        // Legacy keys (read-only migration)
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
        selectedOrbCore: String = "default",
        selectedOrbAura: String = "soft",
        selectedTrail: String = "sparkle",
        selectedAppAccent: String = "midnight"
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
        self.selectedOrbCore = selectedOrbCore
        self.selectedOrbAura = selectedOrbAura
        self.selectedTrail = selectedTrail
        self.selectedAppAccent = selectedAppAccent
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

        // Prefer new slot keys; fall back to legacy cosmetics when migrating.
        let legacySkin = try container.decodeIfPresent(String.self, forKey: .selectedSkin)
        let legacyTheme = try container.decodeIfPresent(String.self, forKey: .selectedTheme)

        selectedOrbCore = try container.decodeIfPresent(String.self, forKey: .selectedOrbCore)
            ?? Self.migrateCore(from: legacySkin)
        selectedOrbAura = try container.decodeIfPresent(String.self, forKey: .selectedOrbAura) ?? "soft"
        selectedTrail = try container.decodeIfPresent(String.self, forKey: .selectedTrail) ?? "sparkle"
        selectedAppAccent = try container.decodeIfPresent(String.self, forKey: .selectedAppAccent)
            ?? Self.migrateAccent(from: legacyTheme)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encode(estimateMultiplier, forKey: .estimateMultiplier)
        try container.encode(xp, forKey: .xp)
        try container.encode(level, forKey: .level)
        try container.encode(streakCount, forKey: .streakCount)
        try container.encode(longestStreak, forKey: .longestStreak)
        try container.encodeIfPresent(lastActiveDate, forKey: .lastActiveDate)
        try container.encode(freezesAvailable, forKey: .freezesAvailable)
        try container.encodeIfPresent(procrastinationType, forKey: .procrastinationType)
        try container.encode(selectedOrbCore, forKey: .selectedOrbCore)
        try container.encode(selectedOrbAura, forKey: .selectedOrbAura)
        try container.encode(selectedTrail, forKey: .selectedTrail)
        try container.encode(selectedAppAccent, forKey: .selectedAppAccent)
    }

    private static func migrateCore(from legacySkin: String?) -> String {
        switch legacySkin {
        case "ember_heart": return "ember"
        case "violet_drift": return "nebula"
        case "aurora", "mint_flow": return "aurora"
        case "deep_focus", .none: return "default"
        default: return "default"
        }
    }

    private static func migrateAccent(from legacyTheme: String?) -> String {
        switch legacyTheme {
        case "violet_night": return "violet"
        case "abyss_teal": return "teal"
        case "ember_glow": return "ember_glow"
        case "deep_focus", .none: return "midnight"
        default: return "midnight"
        }
    }

    /// Currently equipped key for a slot.
    func equippedKey(for slot: CosmeticSlot) -> String {
        switch slot {
        case .orbCore: return selectedOrbCore
        case .orbAura: return selectedOrbAura
        case .trail: return selectedTrail
        case .appAccent: return selectedAppAccent
        }
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
