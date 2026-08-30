//
//  FocusOrb.swift
//  fokusai
//
//  The FokusAI companion: a glowing orb built purely in SwiftUI (no image
//  assets). Driven by `state`, `level`, equipped `core` + `aura` cosmetics,
//  and a tiny kaomoji face. Honors Reduce Motion with a static-glow path.
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

// MARK: - Orb Activity (what you're doing / just did)

/// Light context so the face can react beyond raw glow state.
enum OrbActivity: Equatable, Hashable {
    case neutral
    case idle
    case busy
    case focusing
    case thinking
    case celebrating
    case softWin
}

// MARK: - Face resolver

enum OrbFace {
    static func glyph(
        state: OrbState,
        activity: OrbActivity = .neutral,
        date: Date = .now,
        calendar: Calendar = .current
    ) -> String {
        let hour = calendar.component(.hour, from: date)
        let isLateNight = hour >= 22 || hour < 5
        let isMorning = hour >= 5 && hour < 10
        let isEvening = hour >= 18 && hour < 22

        switch activity {
        case .celebrating: return ":D"
        case .softWin: return ";)"
        case .thinking: return "o.o"
        case .focusing: return ":3"
        case .idle:
            if isLateNight { return "u_u" }
            if isMorning { return "^_^" }
            return ":)"
        case .busy:
            if isLateNight { return ":3" }
            return isEvening ? ";)" : ":3"
        case .neutral:
            break
        }

        switch state {
        case .flare: return ":D"
        case .pulsing: return isLateNight ? ":3" : (isMorning ? "^_^" : ":3")
        case .dim:
            if isLateNight { return "-_-" }
            if isMorning { return "^_^" }
            if isEvening { return "~_~" }
            return ":)"
        }
    }

    static func accessibilityName(for glyph: String) -> String {
        switch glyph {
        case ":D": return "beaming"
        case ":3": return "cat smile"
        case "^_^": return "happy squint"
        case ";)": return "wink"
        case "o.o": return "curious"
        case "-_-": return "sleepy"
        case "u_u": return "drowsy"
        case "~_~": return "chill"
        default: return "smiling"
        }
    }
}

// MARK: - Focus Orb

struct FocusOrb: View {
    var state: OrbState = .dim
    var level: Int = 1
    var core: OrbCoreStyle = .default
    var aura: OrbAuraStyle = .soft
    var activity: OrbActivity = .neutral
    var faceOverride: String? = nil
    /// Core diameter in points. The full view is larger to make room for glow.
    var size: CGFloat = 150

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var flareStart: Date?

    private static let flareDuration: TimeInterval = 0.9

    private var faceGlyph: String {
        faceOverride ?? OrbFace.glyph(state: state, activity: activity)
    }

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
        .accessibilityValue("\(accessibilityStateDescription), \(core.name) core, \(aura.name) aura, looking \(OrbFace.accessibilityName(for: faceGlyph))")
    }

    // MARK: Layers

    @ViewBuilder
    private func orbBody(time: TimeInterval, flareProgress: Double) -> some View {
        let breath = breathScale(time)

        ZStack {
            // 1. Aura (outer identity) — soft / rings / sparks / comet.
            auraLayer(time: time)
                .scaleEffect(breath)

            // 2. Core sphere from equipped orbCore palette.
            Circle()
                .fill(
                    RadialGradient(
                        stops: [
                            .init(color: core.core, location: 0.0),
                            .init(color: core.mid, location: 0.55),
                            .init(color: core.rim, location: 1.0),
                        ],
                        center: UnitPoint(x: 0.5, y: 0.42),
                        startRadius: 0,
                        endRadius: size * 0.62
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Circle().strokeBorder(core.rim.opacity(0.55), lineWidth: 1.5).blur(radius: 1)
                )
                .overlay(innerLife(time: time))
                .overlay(faceLayer(time: time))
                .clipShape(Circle())
                .shadow(color: core.mid.opacity(coreShadowOpacity), radius: 24)
                .scaleEffect(breath)
                .opacity(coreOpacity)

            // 3. Level-scaled orbit sparks (independent of aura; evolution cue).
            if levelOrbitSparkCount > 0 && aura != .sparks && aura != .comet {
                levelOrbitSparks(time: time)
                    .scaleEffect(breath)
            }

            // 4. Flare bloom on completion state.
            if flareProgress < 1.0 {
                flareLayer(progress: flareProgress)
            }
        }
        .drawingGroup()
    }

    // MARK: Aura variants

    @ViewBuilder
    private func auraLayer(time: TimeInterval) -> some View {
        switch aura {
        case .soft:
            Circle()
                .fill(
                    RadialGradient(
                        colors: [core.rim.opacity(glowOpacity(time)), core.rim.opacity(0)],
                        center: .center,
                        startRadius: size * 0.2,
                        endRadius: glowRadius
                    )
                )
                .frame(width: glowRadius * 2, height: glowRadius * 2)
                .blur(radius: 16)

        case .rings:
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [core.rim.opacity(glowOpacity(time) * 0.55), .clear],
                            center: .center,
                            startRadius: size * 0.15,
                            endRadius: glowRadius
                        )
                    )
                    .frame(width: glowRadius * 2, height: glowRadius * 2)
                    .blur(radius: 10)

                ForEach(0..<3, id: \.self) { i in
                    let pulse = reduceMotion ? 0.0 : 0.04 * sin(time * 1.4 + Double(i))
                    Circle()
                        .strokeBorder(core.rim.opacity(0.28 - Double(i) * 0.06), lineWidth: 1.5)
                        .frame(
                            width: size * (1.15 + CGFloat(i) * 0.28 + pulse),
                            height: size * (1.15 + CGFloat(i) * 0.28 + pulse)
                        )
                }
            }

        case .sparks:
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [core.rim.opacity(glowOpacity(time) * 0.7), .clear],
                            center: .center,
                            startRadius: size * 0.2,
                            endRadius: glowRadius
                        )
                    )
                    .frame(width: glowRadius * 2, height: glowRadius * 2)
                    .blur(radius: 14)

                auraSparks(time: time, count: 10 + min(level, 6))
            }

        case .comet:
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [core.rim.opacity(glowOpacity(time) * 0.5), .clear],
                            center: .center,
                            startRadius: size * 0.2,
                            endRadius: glowRadius
                        )
                    )
                    .frame(width: glowRadius * 2, height: glowRadius * 2)
                    .blur(radius: 12)

                cometTrail(time: time)
            }
        }
    }

    private func auraSparks(time: TimeInterval, count: Int) -> some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            for i in 0..<count {
                let phase = Double(i) * (.pi * 2 / Double(count))
                let speed = 0.4 + Double(i % 3) * 0.1
                let angle = reduceMotion ? phase : time * speed + phase
                let orbitRadius = size * 0.58 + CGFloat(i % 3) * size * 0.08
                let position = CGPoint(
                    x: center.x + cos(angle) * orbitRadius,
                    y: center.y + sin(angle) * orbitRadius * 0.92
                )
                let dotSize: CGFloat = 2.5 + CGFloat(i % 2)
                let rect = CGRect(
                    x: position.x - dotSize / 2, y: position.y - dotSize / 2,
                    width: dotSize, height: dotSize
                )
                context.opacity = 0.35
                context.fill(Path(ellipseIn: rect.insetBy(dx: -2, dy: -2)), with: .color(core.rim))
                context.opacity = 0.95
                context.fill(Path(ellipseIn: rect), with: .color(core.rim))
            }
        }
        .frame(width: frameSize, height: frameSize)
        .allowsHitTesting(false)
    }

    private func cometTrail(time: TimeInterval) -> some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let headAngle = reduceMotion ? 0.4 : time * 1.1
            let orbitRadius = size * 0.62
            for i in 0..<12 {
                let t = Double(i) / 12.0
                let angle = headAngle - t * 1.1
                let fade = 1.0 - t
                let position = CGPoint(
                    x: center.x + cos(angle) * orbitRadius,
                    y: center.y + sin(angle) * orbitRadius * 0.9
                )
                let dotSize = 5.5 * fade
                let rect = CGRect(
                    x: position.x - dotSize / 2, y: position.y - dotSize / 2,
                    width: dotSize, height: dotSize
                )
                context.opacity = 0.15 + 0.7 * fade
                context.fill(Path(ellipseIn: rect), with: .color(i == 0 ? Color.textPrimary : core.rim))
            }
        }
        .frame(width: frameSize, height: frameSize)
        .allowsHitTesting(false)
    }

    private func faceLayer(time: TimeInterval) -> some View {
        let bob: CGFloat = reduceMotion ? 0 : CGFloat(sin(time * (state == .pulsing ? 2.2 : 0.7)) * size * 0.012)
        return Text(faceGlyph)
            .font(.system(size: size * facePointSize, weight: .bold, design: .rounded))
            .foregroundStyle(Color.white.opacity(faceOpacity))
            .shadow(color: .black.opacity(0.28), radius: 1.5, y: 1)
            .offset(y: size * 0.02 + bob)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private func innerLife(time: TimeInterval) -> some View {
        let count = innerBlobCount
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                let phase = Double(i) * 2.399
                let speed = 0.25 + Double(i) * 0.07
                let angle = reduceMotion ? phase : time * speed + phase
                let orbit = size * (0.16 + 0.07 * Double(i % 3))
                Circle()
                    .fill(core.rim.opacity(0.35))
                    .frame(width: size * 0.34, height: size * 0.34)
                    .blur(radius: size * 0.09)
                    .offset(
                        x: cos(angle) * orbit,
                        y: sin(angle * 0.8) * orbit * 0.7
                    )
            }
        }
    }

    private func levelOrbitSparks(time: TimeInterval) -> some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            for i in 0..<levelOrbitSparkCount {
                let phase = Double(i) * (.pi * 2 / Double(levelOrbitSparkCount))
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
                context.opacity = 0.35
                context.fill(Path(ellipseIn: rect.insetBy(dx: -2.5, dy: -2.5)), with: .color(core.rim))
                context.opacity = 0.9
                context.fill(Path(ellipseIn: rect), with: .color(core.rim))
            }
        }
        .frame(width: frameSize, height: frameSize)
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func flareLayer(progress: Double) -> some View {
        let fade = 1.0 - easeOut(progress)

        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.textPrimary.opacity(0.85 * fade), core.rim.opacity(0.5 * fade), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: size * 0.9
                )
            )
            .frame(width: size * 1.8, height: size * 1.8)
            .blur(radius: 8)

        if !reduceMotion {
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
                    context.fill(Path(ellipseIn: rect), with: .color(i % 2 == 0 ? core.rim : Color.textPrimary))
                }
            }
            .frame(width: frameSize, height: frameSize)
            .allowsHitTesting(false)
        }
    }

    // MARK: Parameters

    private var frameSize: CGFloat { glowRadius * 2 + 24 }

    private var glowRadius: CGFloat {
        size * (0.85 + 0.05 * CGFloat(min(level, 10)))
    }

    private var innerBlobCount: Int { min(1 + level / 3, 4) }
    private var levelOrbitSparkCount: Int { max(0, min(level - 2, 6)) }

    private var facePointSize: CGFloat {
        switch faceGlyph.count {
        case 0...2: return 0.30
        case 3: return 0.26
        default: return 0.22
        }
    }

    private var faceOpacity: Double {
        switch state {
        case .dim: return 0.78
        case .pulsing: return 0.92
        case .flare: return 1.0
        }
    }

    private func breathScale(_ time: TimeInterval) -> CGFloat {
        if reduceMotion { return state == .flare ? 1.08 : 1.0 }
        switch state {
        case .dim: return 1.0 + 0.015 * sin(time * 0.7)
        case .pulsing: return 1.0 + 0.035 * sin(time * 2.2)
        case .flare: return 1.1
        }
    }

    private var coreOpacity: Double {
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
        if reduceMotion { return 0.0 }
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

#Preview("Dim · Default") {
    ZStack {
        Color.bgDeep.ignoresSafeArea()
        FocusOrb(state: .dim, level: 1, activity: .idle)
    }
}

#Preview("Pulsing · Ember + Sparks") {
    ZStack {
        Color.bgDeep.ignoresSafeArea()
        FocusOrb(state: .pulsing, level: 8, core: .ember, aura: .sparks, activity: .focusing)
    }
}

#Preview("Flare · Solar + Comet") {
    ZStack {
        Color.bgDeep.ignoresSafeArea()
        FocusOrb(state: .flare, level: 20, core: .solar, aura: .comet, activity: .celebrating)
    }
}
