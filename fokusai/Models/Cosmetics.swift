//
//  Cosmetics.swift
//  fokusai
//
//  Four equippable cosmetic slots for the Focus Orb as a dressable character:
//  orbCore, orbAura, trail, appAccent. Softlocked to level — no currency.
//

import SwiftUI

// MARK: - Slot

enum CosmeticSlot: String, CaseIterable, Identifiable, Hashable {
    case orbCore
    case orbAura
    case trail
    case appAccent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .orbCore: return "Core"
        case .orbAura: return "Aura"
        case .trail: return "Trail"
        case .appAccent: return "Accent"
        }
    }

    var subtitle: String {
        switch self {
        case .orbCore: return "The orb's inner color identity"
        case .orbAura: return "Outer glow and particle style"
        case .trail: return "Plays when you finish a step"
        case .appAccent: return "App color wash and streak tint"
        }
    }
}

// MARK: - Catalog item

struct CosmeticItem: Identifiable, Equatable, Hashable {
    let key: String
    let name: String
    let blurb: String
    let slot: CosmeticSlot
    let unlockLevel: Int

    var id: String { "\(slot.rawValue).\(key)" }
}

// MARK: - Catalog + unlock table (levels 1–20)

enum CosmeticCatalog {
    static let all: [CosmeticItem] = [
        // ── orbCore (headline slot; marquee at the top end) ──
        CosmeticItem(key: "default", name: "Default",
                     blurb: "Calm blue. The classic companion.",
                     slot: .orbCore, unlockLevel: 1),
        CosmeticItem(key: "ember", name: "Ember",
                     blurb: "Warm core. Cozy late-night energy.",
                     slot: .orbCore, unlockLevel: 3),
        CosmeticItem(key: "nebula", name: "Nebula",
                     blurb: "Soft violet drift. Slightly dramatic.",
                     slot: .orbCore, unlockLevel: 6),
        CosmeticItem(key: "aurora", name: "Aurora",
                     blurb: "Northern lights, pocket-sized.",
                     slot: .orbCore, unlockLevel: 10),
        CosmeticItem(key: "void", name: "Void",
                     blurb: "Deep hush. Rare and a little eerie.",
                     slot: .orbCore, unlockLevel: 15),
        CosmeticItem(key: "solar", name: "Solar",
                     blurb: "Bright gold flare. The marquee flex.",
                     slot: .orbCore, unlockLevel: 20),

        // ── orbAura ──
        CosmeticItem(key: "soft", name: "Soft",
                     blurb: "A gentle outer bloom.",
                     slot: .orbAura, unlockLevel: 1),
        CosmeticItem(key: "rings", name: "Rings",
                     blurb: "Quiet concentric halos.",
                     slot: .orbAura, unlockLevel: 4),
        CosmeticItem(key: "sparks", name: "Sparks",
                     blurb: "Tiny orbiting flecks of light.",
                     slot: .orbAura, unlockLevel: 8),
        CosmeticItem(key: "comet", name: "Comet",
                     blurb: "A trailing sweep around the rim.",
                     slot: .orbAura, unlockLevel: 14),

        // ── trail (completion celebration) ──
        CosmeticItem(key: "sparkle", name: "Sparkle",
                     blurb: "Classic confetti pop.",
                     slot: .trail, unlockLevel: 1),
        CosmeticItem(key: "pulse", name: "Pulse",
                     blurb: "Expanding rings of light.",
                     slot: .trail, unlockLevel: 5),
        CosmeticItem(key: "stardust", name: "Stardust",
                     blurb: "Fine glitter drifting outward.",
                     slot: .trail, unlockLevel: 9),
        CosmeticItem(key: "ember_rain", name: "Ember Rain",
                     blurb: "Warm flecks falling like sparks.",
                     slot: .trail, unlockLevel: 12),
        CosmeticItem(key: "nova", name: "Nova",
                     blurb: "A bright radial burst. Rare.",
                     slot: .trail, unlockLevel: 18),

        // ── appAccent ──
        CosmeticItem(key: "midnight", name: "Midnight",
                     blurb: "The default deep-blue room.",
                     slot: .appAccent, unlockLevel: 1),
        CosmeticItem(key: "violet", name: "Violet Night",
                     blurb: "A softer, purpler kind of dark.",
                     slot: .appAccent, unlockLevel: 2),
        CosmeticItem(key: "teal", name: "Abyss Teal",
                     blurb: "Deep-sea focus energy.",
                     slot: .appAccent, unlockLevel: 7),
        CosmeticItem(key: "ember_glow", name: "Ember Glow",
                     blurb: "Fireside warmth for late sessions.",
                     slot: .appAccent, unlockLevel: 11),
        CosmeticItem(key: "aurora_wash", name: "Aurora Wash",
                     blurb: "Mint-violet ambience. Fancy.",
                     slot: .appAccent, unlockLevel: 16),
    ]

    static func items(in slot: CosmeticSlot) -> [CosmeticItem] {
        all.filter { $0.slot == slot }.sorted { $0.unlockLevel < $1.unlockLevel }
    }

    static func item(slot: CosmeticSlot, key: String) -> CosmeticItem? {
        all.first { $0.slot == slot && $0.key == key }
    }

    static func defaultKey(for slot: CosmeticSlot) -> String {
        switch slot {
        case .orbCore: return "default"
        case .orbAura: return "soft"
        case .trail: return "sparkle"
        case .appAccent: return "midnight"
        }
    }
}

// MARK: - Orb core palettes (inner gradient)

struct OrbCoreStyle: Equatable, Identifiable, Hashable {
    let key: String
    let name: String
    let core: Color
    let mid: Color
    let rim: Color

    var id: String { key }

    static let `default` = OrbCoreStyle(key: "default", name: "Default", core: .brandDeep, mid: .brand, rim: .focus)
    static let ember = OrbCoreStyle(key: "ember", name: "Ember", core: .emberCore, mid: .reward, rim: .emberRim)
    static let nebula = OrbCoreStyle(key: "nebula", name: "Nebula", core: .violetCore, mid: .violetMid, rim: .violetRim)
    static let aurora = OrbCoreStyle(key: "aurora", name: "Aurora", core: .violetCore, mid: .success, rim: .auroraRim)
    static let voidStyle = OrbCoreStyle(key: "void", name: "Void", core: .bgDeep, mid: .violetCore, rim: .textPrimary)
    static let solar = OrbCoreStyle(key: "solar", name: "Solar", core: .emberCore, mid: .reward, rim: .textPrimary)

    static func named(_ key: String) -> OrbCoreStyle {
        switch key {
        case "ember": return .ember
        case "nebula": return .nebula
        case "aurora": return .aurora
        case "void": return .voidStyle
        case "solar": return .solar
        // Legacy skin keys → nearest core
        case "deep_focus": return .default
        case "ember_heart": return .ember
        case "violet_drift": return .nebula
        case "mint_flow": return .aurora
        default: return .default
        }
    }
}

// MARK: - Orb aura styles (outer glow / particles)

enum OrbAuraStyle: String, Equatable, Hashable, CaseIterable {
    case soft
    case rings
    case sparks
    case comet

    var name: String {
        switch self {
        case .soft: return "Soft"
        case .rings: return "Rings"
        case .sparks: return "Sparks"
        case .comet: return "Comet"
        }
    }

    static func named(_ key: String) -> OrbAuraStyle {
        OrbAuraStyle(rawValue: key) ?? .soft
    }
}

// MARK: - App accent palettes

struct AppAccent: Equatable {
    let key: String
    let name: String
    let aura: Color
    let streak: Color

    static let midnight = AppAccent(key: "midnight", name: "Midnight", aura: .brand, streak: .focus)
    static let violet = AppAccent(key: "violet", name: "Violet Night", aura: .violetMid, streak: .violetMid)
    static let teal = AppAccent(key: "teal", name: "Abyss Teal", aura: .focus, streak: .focus)
    static let emberGlow = AppAccent(key: "ember_glow", name: "Ember Glow", aura: .emberRim, streak: .reward)
    static let auroraWash = AppAccent(key: "aurora_wash", name: "Aurora Wash", aura: .auroraRim, streak: .success)

    static func named(_ key: String) -> AppAccent {
        switch key {
        case "violet", "violet_night": return .violet
        case "teal", "abyss_teal": return .teal
        case "ember_glow": return .emberGlow
        case "aurora_wash": return .auroraWash
        case "deep_focus", "midnight": return .midnight
        default: return .midnight
        }
    }
}

// MARK: - Backward-compat aliases used during migration

enum FlameFlair {
    /// Streak tint now comes from the equipped app accent.
    static func color(for key: String) -> Color {
        AppAccent.named(key).streak
    }
}

/// Legacy name kept so older call sites compile while migrating to AppAccent.
typealias AppTheme = AppAccent
