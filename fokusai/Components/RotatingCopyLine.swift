//
//  RotatingCopyLine.swift
//  fokusai
//
//  Cycles through witty copy lines with a gentle cross-fade. Used by the
//  decomposition loading screen and the tutorial.
//

import SwiftUI

struct RotatingCopyLine: View {
    let lines: [String]
    var interval: TimeInterval = 1.6

    @State private var index = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text(lines.isEmpty ? "" : lines[index % lines.count])
            .font(.fokusRounded(.body, weight: .medium))
            .foregroundStyle(Color.textSecondary)
            .multilineTextAlignment(.center)
            .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .bottom)))
            .id(index)
            .task {
                guard lines.count > 1 else { return }
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(interval))
                    withAnimation(.fokusSpring) {
                        index += 1
                    }
                }
            }
    }
}

#Preview {
    ZStack {
        Color.bgDeep.ignoresSafeArea()
        RotatingCopyLine(lines: Copy.all(.decompositionLoading))
    }
}
