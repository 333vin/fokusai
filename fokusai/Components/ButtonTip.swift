//
//  ButtonTip.swift
//  fokusai
//
//  Hover (pointer / mouse-in-simulator) or long-press tip that names a control
//  and briefly explains what it does.
//

import SwiftUI

extension View {
    /// Shows a tip on pointer hover, or when the user holds the control.
    func buttonTip(_ title: String, detail: String) -> some View {
        modifier(ButtonTipModifier(title: title, detail: detail))
    }
}

private struct ButtonTipModifier: ViewModifier {
    let title: String
    let detail: String

    @State private var isHovering = false
    @State private var isPinned = false
    @State private var dismissTask: Task<Void, Never>?

    private var showing: Bool { isHovering || isPinned }

    func body(content: Content) -> some View {
        content
            .help("\(title). \(detail)")
            .onHover { hovering in
                dismissTask?.cancel()
                withAnimation(.fokusSpring) {
                    isHovering = hovering
                    if hovering { isPinned = false }
                }
            }
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.45)
                    .onEnded { _ in
                        dismissTask?.cancel()
                        withAnimation(.fokusSpring) { isPinned = true }
                        dismissTask = Task {
                            try? await Task.sleep(for: .seconds(2.6))
                            guard !Task.isCancelled else { return }
                            await MainActor.run {
                                withAnimation(.fokusSpring) { isPinned = false }
                            }
                        }
                    }
            )
            .popover(isPresented: Binding(
                get: { showing },
                set: { newValue in
                    if !newValue {
                        dismissTask?.cancel()
                        isHovering = false
                        isPinned = false
                    }
                }
            ), arrowEdge: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.fokusRounded(.subheadline, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .frame(maxWidth: 240, alignment: .leading)
                .presentationCompactAdaptation(.popover)
            }
            .accessibilityHint(detail)
    }
}
