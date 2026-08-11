//
//  BrandLogo.swift
//  fokusai
//
//  Created by Navneet Sharma on 2026-07-16.
//

import SwiftUI

/// Reusable FokusAI branding logo with consistent styling
struct BrandLogo: View {
    enum Size {
        case small  // Navigation bars, small UI elements
        case medium // Standard in-app usage
        case large  // Splash screen, onboarding
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 20
            case .medium: return 32
            case .large: return 48
            }
        }
        
        var tracking: CGFloat {
            switch self {
            case .small: return 1.5
            case .medium: return 2.5
            case .large: return 3
            }
        }
    }
    
    let size: Size
    let showGradient: Bool
    
    init(size: Size = .medium, showGradient: Bool = true) {
        self.size = size
        self.showGradient = showGradient
    }
    
    var body: some View {
        Text("FokusAI")
            .font(.system(size: size.fontSize, weight: .light, design: .rounded))
            .accessibilityLabel("FokusAI")
            .tracking(size.tracking)
            .foregroundStyle(
                showGradient ?
                    AnyShapeStyle(LinearGradient(
                        colors: [Color.brand, Color.focus],
                        startPoint: .leading,
                        endPoint: .trailing
                    )) :
                    AnyShapeStyle(Color.brand)
            )
    }
}

#Preview("Large") {
    ZStack {
        Color.bg.ignoresSafeArea()
        BrandLogo(size: .large)
    }
}

#Preview("Medium") {
    ZStack {
        Color.bg.ignoresSafeArea()
        BrandLogo(size: .medium)
    }
}

#Preview("Small") {
    ZStack {
        Color.bg.ignoresSafeArea()
        BrandLogo(size: .small)
    }
}
