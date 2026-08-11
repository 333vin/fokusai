//
//  Theme.swift
//  fokusai
//
//  Design-system constants. Color tokens live in Assets.xcassets (light/dark
//  sets, dark is the default experience) and are accessed as Color.bg,
//  Color.brand, Color.focus, Color.reward, etc. Never hardcode hex in views.
//

import SwiftUI

// MARK: - Animation

extension Animation {
    /// Gentle spring for everyday UI motion.
    static let fokusSpring = Animation.spring(response: 0.35, dampingFraction: 0.8)

    /// Bigger, faster spring for celebration moments (still under ~1.2s total).
    static let fokusCelebration = Animation.spring(response: 0.45, dampingFraction: 0.65)
}

// MARK: - Typography

extension Font {
    /// SF Rounded display font for the wordmark, big numbers (streak, XP),
    /// and reward moments — rounded reads friendlier and more game-like.
    static func fokusDisplay(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// Rounded variant of a Dynamic Type text style.
    static func fokusRounded(_ style: Font.TextStyle, weight: Font.Weight = .semibold) -> Font {
        .system(style, design: .rounded).weight(weight)
    }
}

// MARK: - Layout Constants

enum Layout {
    static let screenPadding: CGFloat = 16
    static let cardSpacing: CGFloat = 12
    static let cardRadius: CGFloat = 20
    static let buttonRadius: CGFloat = 14
}

// MARK: - Reusable styles

extension View {
    /// Standard card chrome: surface fill, hairline stroke, 20pt radius.
    func fokusCard(radius: CGFloat = Layout.cardRadius, fill: Color = .surface) -> some View {
        background(
            RoundedRectangle(cornerRadius: radius)
                .fill(fill)
                .overlay(
                    RoundedRectangle(cornerRadius: radius)
                        .stroke(Color.stroke, lineWidth: 1)
                )
        )
    }

    /// Primary capsule button chrome in brand blue.
    func fokusPrimaryCapsule(disabled: Bool = false) -> some View {
        self
            .font(.body.weight(.semibold))
            .foregroundStyle(Color.bg)
            .padding(.vertical, 16)
            .padding(.horizontal, 32)
            .background(Capsule().fill(disabled ? Color.textSecondary : Color.brand))
            .shadow(color: disabled ? .clear : Color.brand.opacity(0.35), radius: 12, y: 6)
    }
}
