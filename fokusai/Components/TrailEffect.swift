//
//  TrailEffect.swift
//  fokusai
//
//  Equipped completion trail — plays over the orb during the reward moment.
//  Pure SwiftUI (Canvas / TimelineView). Reduce Motion → soft static glow.
//

import SwiftUI

struct TrailEffect: View {
    var key: String = "sparkle"
    var rim: Color = .focus
    var duration: TimeInterval = 1.15

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startDate = Date()

    private var style: String {
        ["sparkle", "pulse", "stardust", "ember_rain", "nova"].contains(key) ? key : "sparkle"
    }

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            let progress = min(timeline.date.timeIntervalSince(startDate) / duration, 1.0)

            if reduceMotion {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [rim.opacity(0.45), .clear],
                            center: .center, startRadius: 0, endRadius: 130
                        )
                    )
            } else {
                switch style {
                case "pulse":
                    pulseCanvas(progress: progress)
                case "stardust":
                    stardustCanvas(progress: progress)
                case "ember_rain":
                    emberRainCanvas(progress: progress)
                case "nova":
                    novaCanvas(progress: progress)
                default:
                    sparkleCanvas(progress: progress)
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear { startDate = Date() }
        .accessibilityHidden(true)
    }

    // MARK: Variants

    private func sparkleCanvas(progress: Double) -> some View {
        Canvas { context, size in
            guard progress < 1 else { return }
            let origin = CGPoint(x: size.width / 2, y: size.height / 2)
            let fade = 1 - easeIn(progress)
            let colors: [Color] = [rim, .focus, .textPrimary]
            for i in 0..<28 {
                let seed = Double(i)
                let angle = seed * 2.399 + sin(seed * 12.9898) * 0.7
                let speed = 120 + abs(sin(seed * 78.233)) * 180
                let t = progress * duration
                let x = origin.x + cos(angle) * speed * t
                let y = origin.y + sin(angle) * speed * t * 0.85 + 0.5 * 300 * t * t - 50 * t
                var ctx = context
                ctx.opacity = fade
                ctx.translateBy(x: x, y: y)
                ctx.rotate(by: .radians(seed + t * 2))
                let rect = CGRect(x: -3, y: -2, width: 6 + (i % 3 == 0 ? 3 : 0), height: 4)
                ctx.fill(Path(roundedRect: rect, cornerRadius: 1.5), with: .color(colors[i % colors.count]))
            }
        }
    }

    private func pulseCanvas(progress: Double) -> some View {
        Canvas { context, size in
            guard progress < 1 else { return }
            let origin = CGPoint(x: size.width / 2, y: size.height / 2)
            for i in 0..<3 {
                let local = min(max((progress - Double(i) * 0.12) / 0.7, 0), 1)
                guard local > 0 else { continue }
                let radius = 20 + local * 140
                var path = Path()
                path.addEllipse(in: CGRect(
                    x: origin.x - radius, y: origin.y - radius,
                    width: radius * 2, height: radius * 2
                ))
                context.stroke(
                    path,
                    with: .color(rim.opacity((1 - local) * 0.7)),
                    lineWidth: 3 - local * 2
                )
            }
        }
    }

    private func stardustCanvas(progress: Double) -> some View {
        Canvas { context, size in
            guard progress < 1 else { return }
            let origin = CGPoint(x: size.width / 2, y: size.height / 2)
            let fade = 1 - easeIn(progress)
            for i in 0..<48 {
                let seed = Double(i) * 1.618
                let angle = seed * 1.7
                let dist = (20 + abs(sin(seed * 9.1)) * 160) * progress
                let x = origin.x + cos(angle) * dist
                let y = origin.y + sin(angle) * dist * 0.95
                let dot: CGFloat = 1.5 + CGFloat(i % 3) * 0.8
                var ctx = context
                ctx.opacity = fade * (0.4 + 0.6 * abs(sin(seed)))
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x - dot / 2, y: y - dot / 2, width: dot, height: dot)),
                    with: .color(i % 2 == 0 ? rim : Color.textPrimary)
                )
            }
        }
    }

    private func emberRainCanvas(progress: Double) -> some View {
        Canvas { context, size in
            guard progress < 1 else { return }
            let fade = 1 - easeIn(progress)
            let colors: [Color] = [.reward, .emberRim, rim]
            for i in 0..<36 {
                let seed = Double(i)
                let x = size.width * (0.15 + abs(sin(seed * 7.3)) * 0.7)
                let startY = size.height * 0.25
                let y = startY + progress * (140 + abs(cos(seed * 3.1)) * 100)
                let w: CGFloat = 3 + CGFloat(i % 2)
                var ctx = context
                ctx.opacity = fade
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: w, height: w * 1.6)),
                    with: .color(colors[i % colors.count])
                )
            }
        }
    }

    private func novaCanvas(progress: Double) -> some View {
        Canvas { context, size in
            guard progress < 1 else { return }
            let origin = CGPoint(x: size.width / 2, y: size.height / 2)
            let fade = 1 - easeOut(progress)
            let eased = easeOut(progress)

            // Bright core flash.
            let flash = 18 + eased * 40
            context.opacity = fade * 0.85
            context.fill(
                Path(ellipseIn: CGRect(x: origin.x - flash, y: origin.y - flash, width: flash * 2, height: flash * 2)),
                with: .color(Color.textPrimary.opacity(0.7))
            )

            for i in 0..<24 {
                let angle = Double(i) * (.pi * 2 / 24)
                let dist = 30 + eased * 150
                let x = origin.x + cos(angle) * dist
                let y = origin.y + sin(angle) * dist
                let len = 10 + (1 - eased) * 14
                var ray = Path()
                ray.move(to: CGPoint(x: origin.x + cos(angle) * (dist - len),
                                     y: origin.y + sin(angle) * (dist - len)))
                ray.addLine(to: CGPoint(x: x, y: y))
                context.stroke(ray, with: .color((i % 2 == 0 ? rim : Color.reward).opacity(fade)), lineWidth: 2)
            }
        }
    }

    private func easeIn(_ t: Double) -> Double { t * t }
    private func easeOut(_ t: Double) -> Double { 1 - pow(1 - t, 3) }
}

#Preview {
    ZStack {
        Color.bgDeep.ignoresSafeArea()
        TrailEffect(key: "nova", rim: .reward)
            .frame(width: 300, height: 300)
    }
}
