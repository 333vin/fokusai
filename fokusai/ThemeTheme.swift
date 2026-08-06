//
//  Theme.swift
//  fokusai
//
//  Created by Navneet Sharma on 2026-07-16.
//

import SwiftUI

// Note: Color assets (bg, surface, brand, accent, etc.) are now auto-generated
// by Xcode from Assets.xcassets color sets. Access them as Color.bg, Color.accent, etc.

// MARK: - Animation Springs
extension Animation {
    static let fokusSpring = Animation.spring(response: 0.35, dampingFraction: 0.8)
}

// MARK: - Layout Constants
enum Layout {
    static let screenPadding: CGFloat = 16
    static let cardSpacing: CGFloat = 12
    static let cardRadius: CGFloat = 16
    static let buttonRadius: CGFloat = 12
    static let capsuleRadius: CGFloat = 999
}
