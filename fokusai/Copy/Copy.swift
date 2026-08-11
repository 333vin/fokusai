//
//  Copy.swift
//  fokusai
//
//  The personality system. Every witty line in the app lives here so tone can
//  be tuned in one file. Voice: self-aware, warm, lightly funny, a bit Gen-Z,
//  never mean, never trying too hard, never shaming.
//

import Foundation

enum Copy {
    enum Category: Hashable {
        case decompositionLoading
        case homeEmpty
        case completion
        case ranOutOfTime
        case streakReturn
        case freezeUsed
        case chestOpen
        case chestKindMessage
        case levelUp
        case focusNudge
    }

    // MARK: - Lines

    private static let lines: [Category: [String]] = [
        .decompositionLoading: [
            "Chopping your mountain into stairs…",
            "Making this way less scary…",
            "Bullying your procrastination (affectionately)…",
            "Finding the tiniest possible first step…",
            "Doing the hard part so you don't have to…",
            "Consulting the ancient art of Just Starting™…",
            "Shrinking the monster to bite-size…",
            "Negotiating with your to-do list…",
            "Locating the easy way in…",
            "Turning \u{201C}ugh\u{201D} into \u{201C}oh, that's it?\u{201D}…",
        ],
        .homeEmpty: [
            "Suspiciously empty in here. What are we avoiding today?",
            "No tasks yet. Your future self is watching hopefully.",
            "The orb is rested and ready. Feed it a task.",
            "Nothing here but potential. Dangerous amounts of it.",
            "Empty list, full battery. Rare combo. Use it.",
            "Your procrastination called. It's nervous.",
            "A blank page, but in a good way for once.",
            "Add the thing. You know the thing.",
        ],
        .completion: [
            "That's the hardest part done. Everything else is downhill.",
            "Look at you. Starting things. Iconic.",
            "The task feared you. Good.",
            "One tiny step for you, one giant L for procrastination.",
            "Started. Which is 90% of the battle, scientifically-ish.",
            "Your orb felt that. It's glowing about it.",
            "Momentum unlocked. Physics is on your side now.",
            "That was you, doing the thing. Noted and celebrated.",
            "Small step, big deal. We keep the receipts.",
            "Certified starter behavior.",
        ],
        .ranOutOfTime: [
            "You showed up. That literally counts.",
            "Timer ran out, but you didn't run away. +5 XP.",
            "Progress isn't always finished. It's still progress.",
            "The clock lost. You were there, and that's the win.",
            "Showing up is the skill. You just practiced it.",
            "Not done ≠ nothing. You moved the needle.",
            "Time's up, effort's banked. Take the XP.",
            "You sat with the hard thing. Respect.",
        ],
        .streakReturn: [
            "Back again. Your orb never doubted you.",
            "Streak reset, but your XP and orb are exactly where you left them.",
            "Streaks restart. Progress doesn't. Welcome back.",
            "The orb waited patiently. It's kind of its whole thing.",
            "Day one, again. Day ones are underrated.",
            "You came back. That's the part most people skip.",
            "Fresh streak, same you, same orb, same XP.",
            "Missed days aren't debt. Start tiny, start now.",
        ],
        .freezeUsed: [
            "Your orb used a freeze. You're still going. 🧊",
            "A freeze quietly saved your streak. The orb's got you.",
            "Missed a day? The orb covered your shift.",
            "Streak intact. One freeze down, zero guilt.",
            "The orb spent a freeze so you didn't have to stress.",
            "Freeze deployed. Your flame never even flickered.",
            "Life happened. The orb handled it.",
            "Covered by freeze insurance. Premiums: showing up sometimes.",
        ],
        .chestOpen: [
            "The Focus Gods smile upon you.",
            "Small reward, big vibes.",
            "Ooh. Shiny.",
            "A wild chest appeared. It likes you.",
            "Bonus loot for doing the healthy thing. Wild concept.",
            "The universe tips well today.",
            "Chest says: keep going, superstar.",
            "Free treasure. No strings. We checked.",
        ],
        .chestKindMessage: [
            "You're doing better than you think you are.",
            "Whoever said starting is the hardest part never met you today.",
            "Your effort is quietly compounding. Keep going.",
            "Somewhere, your future self just smiled.",
            "This chest contains: proof you showed up. Priceless.",
            "You + tiny steps = lowkey unstoppable.",
            "Rest is productive too. Pace yourself, champion.",
            "Today's rare drop: genuine pride. Equip it.",
        ],
        .levelUp: [
            "Your orb evolved. It's beaming. So are we.",
            "New level, new glow. You earned every photon.",
            "Level up! Your orb is showing off now.",
            "Evolution complete. The orb remembers every step.",
            "You leveled up by starting things. Legendary strategy.",
            "The orb grew. Coincidentally, so did you.",
            "More glow, more you. Keep stacking those tiny wins.",
            "Achievement in orb husbandry: outstanding.",
        ],
        .focusNudge: [
            "Just start. The timer does the worrying.",
            "Only this one tiny step. Nothing else exists.",
            "Two minutes of brave. That's the whole ask.",
            "Start ugly. Fix it later. That's the secret.",
            "The step is small on purpose. Take it.",
            "You vs. one tiny action. Easy odds.",
            "Don't do it well. Just do it at all.",
            "Three minutes. Then you get to feel smug.",
        ],
    ]

    // MARK: - Access

    private static var lastServed: [Category: Int] = [:]

    /// A random line for the context, avoiding immediate repeats.
    static func random(_ category: Category) -> String {
        guard let options = lines[category], !options.isEmpty else { return "" }
        guard options.count > 1 else { return options[0] }

        var index = Int.random(in: 0..<options.count)
        if index == lastServed[category] {
            index = (index + 1) % options.count
        }
        lastServed[category] = index
        return options[index]
    }

    /// All lines for a category, in order (used by rotating loading screens).
    static func all(_ category: Category) -> [String] {
        lines[category] ?? []
    }
}
