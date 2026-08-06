//
//  FocusOrb.swift
//  fokusai
//
//  Created by Navneet Sharma on 2026-07-16.
//

import SwiftUI

enum OrbState {
    case dim
    case pulsing
    case flare
}

struct FocusOrb: View {
    let state: OrbState
    let level: Int
    
    @State private var pulsePhase: CGFloat = 0
    @State private var flarePhase: CGFloat = 0
    
    init(state: OrbState = .dim, level: Int = 1) {
        self.state = state
        self.level = level
    }
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                .brand.opacity(glowOpacity(time)),
                                .brand.opacity(0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: glowRadius(time)
                        )
                    )
                    .frame(width: outerSize(time), height: outerSize(time))
                
                // Core orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                .accent.opacity(coreOpacity(time)),
                                .brand
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: coreSize(time), height: coreSize(time))
                    .shadow(color: .brand.opacity(0.5), radius: 20, x: 0, y: 0)
            }
        }
    }
    
    // MARK: - Animation Parameters
    
    private func coreSize(_ time: TimeInterval) -> CGFloat {
        let baseSize: CGFloat = 100
        
        switch state {
        case .dim:
            return baseSize * 0.8
        case .pulsing:
            let pulse = sin(time * 2) * 0.05 + 1.0
            return baseSize * pulse
        case .flare:
            return baseSize * 1.2
        }
    }
    
    private func outerSize(_ time: TimeInterval) -> CGFloat {
        let levelBonus = CGFloat(level) * 5
        let baseSize: CGFloat = 160 + levelBonus
        
        switch state {
        case .dim:
            return baseSize * 0.7
        case .pulsing:
            let pulse = sin(time * 2) * 0.1 + 1.0
            return baseSize * pulse
        case .flare:
            return baseSize * 1.4
        }
    }
    
    private func glowRadius(_ time: TimeInterval) -> CGFloat {
        switch state {
        case .dim:
            return 60
        case .pulsing:
            let pulse = sin(time * 2) * 0.15 + 1.0
            return 80 * pulse
        case .flare:
            return 100
        }
    }
    
    private func glowOpacity(_ time: TimeInterval) -> CGFloat {
        switch state {
        case .dim:
            return 0.15
        case .pulsing:
            let pulse = sin(time * 2) * 0.1 + 0.3
            return pulse
        case .flare:
            return 0.6
        }
    }
    
    private func coreOpacity(_ time: TimeInterval) -> CGFloat {
        switch state {
        case .dim:
            return 0.4
        case .pulsing:
            let pulse = sin(time * 2) * 0.1 + 0.6
            return pulse
        case .flare:
            return 0.9
        }
    }
}

#Preview("Dim Orb") {
    ZStack {
        Color.bg.ignoresSafeArea()
        FocusOrb(state: .dim, level: 1)
    }
}

#Preview("Pulsing Orb") {
    ZStack {
        Color.bg.ignoresSafeArea()
        FocusOrb(state: .pulsing, level: 3)
    }
}

#Preview("Flare Orb") {
    ZStack {
        Color.bg.ignoresSafeArea()
        FocusOrb(state: .flare, level: 5)
    }
}
