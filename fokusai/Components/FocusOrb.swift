//
//  FocusOrb.swift
//  fokusai
//
//  The FokusAI companion: a glowing orb built purely in SwiftUI (no image
//  assets). Driven by `state` (dim / pulsing / flare), `level` (evolution:
//  bigger glow, more internal life, orbiting sparks), and `skin` (cosmetic
//  palette). Honors Reduce Motion with a static-glow path.
//

import SwiftUI

// MARK: - Orb State

enum OrbState: Equatable {
    /// Nothing active: low opacity, small glow, slow breathing.
    case dim
    /// A microtask timer is running: steady glow pulse.
    case pulsing
    /// A completion just happened: bright bloom + brief particle sparkle.
    case flare
}

// MARK: - Orb Skin

/// A cosmetic palette for the orb. Unlockable skins swap these colors.
struct OrbSkin: Equatable, Identifiable {
    let key: String
    let name: String
    let core: Color
    let mid: Color
    let rim: Color

    var id: String { key }

    /// The default palette: brandDeep core → brand → focus rim.
    static let deepFocus = OrbSkin(key: "deep_focus", name: "Deep Focus", core: .brandDeep, mid: .brand, rim: .focus)
}

// MARK: - Focus Orb

struct FocusOrb: View {
    var state: OrbState = .dim
    var level: Int = 1
    var skin: OrbSkin = .deepFocus
    /// Core diameter in points. The full view is larger to make room for glow.
    var size: CGFloat = 150

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var flareStart: Date?

    /// Total sparkle burst duration.
    private static let flareDuration: TimeInterval = 0.9

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let flareProgress = currentFlareProgress(now: timeline.date)
            orbBody(time: reduceMotion ? 0 : time, flareProgress: flareProgress)
        }
        .frame(width: frameSize, height: frameSize)
        .onChange(of: state) { _, newState in
            flareStart = (newState == .flare) ? Date() : nil
        }
        .onAppear {
            if state == .flare { flareStart = Date() }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Focus orb, level \(level)")
        .accessibilityValue(accessibilityStateDescription)
    }

    // MARK: Layers

    @ViewBuilder
    private func orbBody(time: TimeInterval, flareProgress: Double) -> some View {
        let breath = breathScale(time)

        ZStack {
            // 1. Soft outer glow (grows with level).
            Circle()
                .fill(
                    RadialGradient(
                        colors: [skin.rim.opacity(glowOpacity(time)), skin.rim.opacity(0)],
                        center: .center,
                        startRadius: size * 0.2,
                        endRadius: glowRadius
                    )
                )
                .frame(width: glowRadius * 2, height: glowRadius * 2)
                .blur(radius: 16)
                .scaleEffect(breath)

            // 2. Core sphere: skin.core → mid → rim, lit slightly above center.
            Circle()
                .fill(
                    RadialGradient(
                        stops: [
                            .init(color: skin.core, location: 0.0),
                            .init(color: skin.mid, location: 0.55),
                            .init(color: skin.rim, location: 1.0),
                        ],
                        center: UnitPoint(x: 0.5, y: 0.42),
                        startRadius: 0,
                        endRadius: size * 0.62
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    // Rim light so the edge reads as glass.
                    Circle().strokeBorder(skin.rim.opacity(0.55), lineWidth: 1.5).blur(radius: 1)
                )
                .overlay(innerLife(time: time))
                .clipShape(Circle())
                .shadow(color: skin.mid.opacity(coreShadowOpacity), radius: 24)
                .scaleEffect(breath)
                .opacity(coreOpacity(time))

            // 3. Slow-orbiting sparks appear as the orb evolves (level 3+).
            if orbitingSparkCount > 0 {
                orbitingSparks(time: time)
                    .scaleEffect(breath)
            }

            // 4. Flare: bright bloom + particle sparkle on completion.
            if flareProgress < 1.0 {
                flareLayer(progress: flareProgress)
            }
        }
        .drawingGroup()
    }

    /// Internal highlight blobs that drift inside the core; more with level.
    @ViewBuilder
    private func innerLife(time: TimeInterval) -> some View {
        let count = innerBlobCount
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                let phase = Double(i) * 2.399  // golden-angle offsets
                let speed = 0.25 + Double(i) * 0.07
                let angle = reduceMotion ? phase : time * speed + phase
                let orbit = size * (0.16 + 0.07 * Double(i % 3))
                Circle()
                    .fill(skin.rim.opacity(0.35))
                    .frame(width: size * 0.34, height: size * 0.34)
                    .blur(radius: size * 0.09)
                    .offset(
                        x: cos(angle) * orbit,
                        y: sin(angle * 0.8) * orbit * 0.7
                    )
            }
        }
    }

    /// Small dots slowly circling outside the core at higher levels.
    private func orbitingSparks(time: TimeInterval) -> some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            for i in 0..<orbitingSparkCount {
                let phase = Double(i) * (.pi * 2 / Double(orbitingSparkCount))
                let speed = 0.35 + Double(i % 3) * 0.08
                let angle = reduceMotion ? phase : time * speed + phase
                let orbitRadius = size * 0.62 + CGFloat(i % 3) * size * 0.07
                let position = CGPoint(
                    x: center.x + cos(angle) * orbitRadius,
                    y: center.y + sin(angle) * orbitRadius * 0.92
                )
                let dotSize: CGFloat = 3 + CGFloat(i % 2) * 1.5
                let rect = CGRect(
                    x: position.x - dotSize / 2, y: position.y - dotSize / 2,
                    width: dotSize, height: dotSize
                )
                // Soft halo behind each spark.
                context.opacity = 0.35
                context.fill(Path(ellipseIn: rect.insetBy(dx: -2.5, dy: -2.5)), with: .color(skin.rim))
                context.opacity = 0.9
                context.fill(Path(ellipseIn: rect), with: .color(skin.rim))
            }
        }
        .frame(width: frameSize, height: frameSize)
        .allowsHitTesting(false)
    }

    /// Bloom + sparkle burst. `progress` runs 0 → 1 over flareDuration.
    @ViewBuilder
    private func flareLayer(progress: Double) -> some View {
        let fade = 1.0 - easeOut(progress)

        // Bright bloom (this is the whole flare under Reduce Motion).
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.textPrimary.opacity(0.85 * fade), skin.rim.opacity(0.5 * fade), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: size * 0.9
                )
            )
            .frame(width: size * 1.8, height: size * 1.8)
            .blur(radius: 8)

        if !reduceMotion {
            // Particle sparkle radiating outward.
            Canvas { context, canvasSize in
                let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                let eased = easeOut(progress)
                for i in 0..<16 {
                    let angle = Double(i) * (.pi * 2 / 16) + Double(i % 4) * 0.13
                    let distance = size * 0.35 + eased * size * 0.75
                    let position = CGPoint(
                        x: center.x + cos(angle) * distance,
                        y: center.y + sin(angle) * distance
                    )
                    let particleSize = (4.5 - eased * 3.0) * (i % 3 == 0 ? 1.5 : 1.0)
                    let rect = CGRect(
                        x: position.x - particleSize / 2, y: position.y - particleSize / 2,
                        width: particleSize, height: particleSize
                    )
                    context.opacity = fade
                    context.fill(Path(ellipseIn: rect), with: .color(i % 2 == 0 ? skin.rim : Color.textPrimary))
                }
            }
            .frame(width: frameSize, height: frameSize)
            .allowsHitTesting(false)
        }
    }

    // MARK: State-driven parameters

    private var frameSize: CGFloat { glowRadius * 2 + 24 }

    /// Glow reach grows gently with level (evolution), capped so it can't blow up layout.
    private var glowRadius: CGFloat {
        size * (0.85 + 0.05 * CGFloat(min(level, 10)))
    }

    /// 1 blob at level 1 growing to 4 by level 10.
    private var innerBlobCount: Int { min(1 + level / 3, 4) }

    /// Sparks appear from level 3, up to 6.
    private var orbitingSparkCount: Int { max(0, min(level - 2, 6)) }

    private func breathScale(_ time: TimeInterval) -> CGFloat {
        if reduceMotion { return state == .flare ? 1.08 : 1.0 }
        switch state {
        case .dim: return 1.0 + 0.015 * sin(time * 0.7)
        case .pulsing: return 1.0 + 0.035 * sin(time * 2.2)
        case .flare: return 1.1
        }
    }

    private func coreOpacity(_ time: TimeInterval) -> Double {
        switch state {
        case .dim: return 0.6
        case .pulsing: return 0.95
        case .flare: return 1.0
        }
    }

    private func glowOpacity(_ time: TimeInterval) -> Double {
        if reduceMotion {
            switch state {
            case .dim: return 0.18
            case .pulsing: return 0.42
            case .flare: return 0.7
            }
        }
        switch state {
        case .dim: return 0.18 + 0.03 * sin(time * 0.7)
        case .pulsing: return 0.4 + 0.12 * sin(time * 2.2)
        case .flare: return 0.7
        }
    }

    private var coreShadowOpacity: Double {
        switch state {
        case .dim: return 0.25
        case .pulsing: return 0.45
        case .flare: return 0.7
        }
    }

    private func currentFlareProgress(now: Date) -> Double {
        guard state == .flare, let start = flareStart else { return 1.0 }
        if reduceMotion { return 0.0 }  // hold the static bloom while flaring
        return min(now.timeIntervalSince(start) / Self.flareDuration, 1.0)
    }

    private func easeOut(_ t: Double) -> Double {
        1 - pow(1 - t, 3)
    }

    private var accessibilityStateDescription: String {
        switch state {
        case .dim: return "Resting"
        case .pulsing: return "Focusing with you"
        case .flare: return "Celebrating"
        }
    }
}

// MARK: - Previews

#Preview("Dim · L1") {
    ZStack {
        Color.bgDeep.ignoresSafeArea()
        FocusOrb(state: .dim, level: 1)
    }
}

#Preview("Pulsing · L5") {
    ZStack {
        Color.bgDeep.ignoresSafeArea()
        FocusOrb(state: .pulsing, level: 5)
    }
}

#Preview("Flare · L8") {
    ZStack {
        Color.bgDeep.ignoresSafeArea()
        FocusOrb(state: .flare, level: 8)
    }
}
