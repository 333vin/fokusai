//
//  Cosmetics.swift
//  fokusai
//
//  The cosmetic upgrade catalog: orb skins, app themes, streak-flame flair,
//  and completion sounds. Locked items show an unlock LEVEL, never a price.
//

import SwiftUI

// MARK: - Catalog item

struct CosmeticItem: Identifiable, Equatable {
    enum Category: String, CaseIterable, Identifiable {
        case orbSkin
        case theme
        case flameFlair
        case sound

        var id: String { rawValue }

        var title: String {
            switch self {
            case .orbSkin: return "Orb Skins"
            case .theme: return "Themes"
            case .flameFlair: return "Flame Flair"
            case .sound: return "Sounds"
            }
        }
    }

    let key: String
    let name: String
    let blurb: String
    let category: Category
    let unlockLevel: Int

    var id: String { "\(category.rawValue).\(key)" }
}

// MARK: - Catalog

enum CosmeticCatalog {
    static let all: [CosmeticItem] = [
        // Orb skins
        CosmeticItem(key: "deep_focus", name: "Deep Focus", blurb: "The original. Calm, blue, dependable.", category: .orbSkin, unlockLevel: 1),
        CosmeticItem(key: "mint_flow", name: "Mint Flow", blurb: "Fresh and unbothered.", category: .orbSkin, unlockLevel: 2),
        CosmeticItem(key: "ember_heart", name: "Ember Heart", blurb: "Warm core, big cozy energy.", category: .orbSkin, unlockLevel: 4),
        CosmeticItem(key: "violet_drift", name: "Violet Drift", blurb: "Mysterious. Slightly dramatic. We love it.", category: .orbSkin, unlockLevel: 6),
        CosmeticItem(key: "aurora", name: "Aurora", blurb: "Northern lights, but pocket-sized.", category: .orbSkin, unlockLevel: 8),

        // App themes
        CosmeticItem(key: "deep_focus", name: "Midnight Blue", blurb: "The default deep-blue room.", category: .theme, unlockLevel: 1),
        CosmeticItem(key: "violet_night", name: "Violet Night", blurb: "A softer, purpler kind of dark.", category: .theme, unlockLevel: 3),
        CosmeticItem(key: "abyss_teal", name: "Abyss Teal", blurb: "Deep sea focus energy.", category: .theme, unlockLevel: 5),
        CosmeticItem(key: "ember_glow", name: "Ember Glow", blurb: "Fireside warmth for late sessions.", category: .theme, unlockLevel: 7),

        // Streak-flame flair
        CosmeticItem(key: "classic", name: "Cyan Classic", blurb: "The signature flame.", category: .flameFlair, unlockLevel: 1),
        CosmeticItem(key: "mint", name: "Mint Fire", blurb: "Cool flame, hot streak.", category: .flameFlair, unlockLevel: 3),
        CosmeticItem(key: "violet", name: "Violet Blaze", blurb: "Burns fancier.", category: .flameFlair, unlockLevel: 5),
        CosmeticItem(key: "golden", name: "Golden Flame", blurb: "The rarest fire. You earned it.", category: .flameFlair, unlockLevel: 7),

        // Completion sounds
        CosmeticItem(key: "chime", name: "Chime", blurb: "A tiny victory bell.", category: .sound, unlockLevel: 1),
        CosmeticItem(key: "click", name: "Click", blurb: "Satisfying. Mechanical. Done.", category: .sound, unlockLevel: 2),
        CosmeticItem(key: "pop", name: "Pop", blurb: "Bubble-wrap dopamine.", category: .sound, unlockLevel: 4),
        CosmeticItem(key: "silent", name: "Silence", blurb: "For the library ninjas.", category: .sound, unlockLevel: 1),
    ]

    static func items(in category: CosmeticItem.Category) -> [CosmeticItem] {
        all.filter { $0.category == category }.sorted { $0.unlockLevel < $1.unlockLevel }
    }
}

// MARK: - Orb skin palettes

extension OrbSkin {
    static let mintFlow = OrbSkin(key: "mint_flow", name: "Mint Flow", core: .brandDeep, mid: .success, rim: .auroraRim)
    static let emberHeart = OrbSkin(key: "ember_heart", name: "Ember Heart", core: .emberCore, mid: .reward, rim: .emberRim)
    static let violetDrift = OrbSkin(key: "violet_drift", name: "Violet Drift", core: .violetCore, mid: .violetMid, rim: .violetRim)
    static let aurora = OrbSkin(key: "aurora", name: "Aurora", core: .violetCore, mid: .success, rim: .auroraRim)

    static func named(_ key: String) -> OrbSkin {
        switch key {
        case "mint_flow": return .mintFlow
        case "ember_heart": return .emberHeart
        case "violet_drift": return .violetDrift
        case "aurora": return .aurora
        default: return .deepFocus
        }
    }
}

// MARK: - App themes

/// Themes re-skin the app's ambience: an aura wash over the deep background.
struct AppTheme: Equatable {
    let key: String
    let name: String
    let aura: Color

    static let deepFocus = AppTheme(key: "deep_focus", name: "Midnight Blue", aura: .brand)
    static let violetNight = AppTheme(key: "violet_night", name: "Violet Night", aura: .violetMid)
    static let abyssTeal = AppTheme(key: "abyss_teal", name: "Abyss Teal", aura: .focus)
    static let emberGlow = AppTheme(key: "ember_glow", name: "Ember Glow", aura: .emberRim)

    static func named(_ key: String) -> AppTheme {
        switch key {
        case "violet_night": return .violetNight
        case "abyss_teal": return .abyssTeal
        case "ember_glow": return .emberGlow
        default: return .deepFocus
        }
    }
}

// MARK: - Flame flair

enum FlameFlair {
    static func color(for key: String) -> Color {
        switch key {
        case "mint": return .success
        case "violet": return .violetMid
        case "golden": return .reward
        default: return .focus
        }
    }
}
