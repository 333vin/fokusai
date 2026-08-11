//
//  ConfettiBurst.swift
//  fokusai
//
//  A one-shot celebratory particle burst in reward gold, drawn with Canvas.
//  Reduce Motion: a soft static glow that fades instead of flying particles.
//

import SwiftUI

struct ConfettiBurst: View {
    /// Total lifetime of the burst.
    var duration: TimeInterval = 1.1
    var colors: [Color] = [.reward, .focus, .textPrimary]
    var particleCount: Int = 30

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startDate = Date()

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            let progress = min(timeline.date.timeIntervalSince(startDate) / duration, 1.0)

            if reduceMotion {
                // Static celebratory glow.
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.reward.opacity(0.4), .clear],
                            center: .center, startRadius: 0, endRadius: 120
                        )
                    )
            } else {
                Canvas { context, size in
                    guard progress < 1.0 else { return }
                    let origin = CGPoint(x: size.width / 2, y: size.height / 2)
                    let fade = 1.0 - easeIn(progress)

                    for i in 0..<particleCount {
                        // Deterministic pseudo-random attributes per particle.
                        let seed = Double(i)
                        let angle = seed * 2.399 + sin(seed * 12.9898) * 0.7
                        let speed = 130 + abs(sin(seed * 78.233)) * 190
                        let gravity = 320.0
                        let t = progress * duration

                        let x = origin.x + cos(angle) * speed * t
                        let y = origin.y + sin(angle) * speed * t * 0.85 + 0.5 * gravity * t * t - 60 * t
                        let rotation = Angle(radians: seed + t * (2 + sin(seed) * 3))
                        let pieceSize = CGSize(width: 6 + (i % 3 == 0 ? 3 : 0), height: 4)

                        var pieceContext = context
                        pieceContext.opacity = fade
                        pieceContext.translateBy(x: x, y: y)
                        pieceContext.rotate(by: rotation)
                        let rect = CGRect(
                            x: -pieceSize.width / 2, y: -pieceSize.height / 2,
                            width: pieceSize.width, height: pieceSize.height
                        )
                        pieceContext.fill(Path(roundedRect: rect, cornerRadius: 1.5),
                                          with: .color(colors[i % colors.count]))
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear { startDate = Date() }
        .accessibilityHidden(true)
    }

    private func easeIn(_ t: Double) -> Double {
        t * t
    }
}

#Preview {
    ZStack {
        Color.bgDeep.ignoresSafeArea()
        ConfettiBurst()
            .frame(width: 300, height: 300)
    }
}
