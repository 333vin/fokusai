//
//  Haptics.swift
//  fokusai
//
//  Subtle haptics on key reward moments. UIKit generators respect the
//  system haptics setting automatically.
//

import UIKit
import AudioToolbox

enum Haptics {
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

enum SoundPlayer {
    /// Plays the user's chosen completion sound (system sounds; no assets).
    static func playCompletion(_ key: String) {
        let soundID: SystemSoundID?
        switch key {
        case "chime": soundID = 1057
        case "click": soundID = 1104
        case "pop": soundID = 1306
        default: soundID = nil  // "silent"
        }
        if let soundID {
            AudioServicesPlaySystemSound(soundID)
        }
    }
}
