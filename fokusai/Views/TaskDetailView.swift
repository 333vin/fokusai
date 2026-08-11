//
//  TaskDetailView.swift
//  fokusai
//
//  Ordered microtask checklist with the first open step emphasized
//  ("Start here"), overall progress in focus cyan, and a cascade entrance
//  after a fresh decomposition.
//

import SwiftUI

struct TaskDetailView: View {
    @Environment(AppState.self) private var appState
    let taskID: UUID

    @State private var selectedMicrotask: Microtask?
    @State private var visibleRows = 0
    @State private var hasCascaded = false

    private var task: TaskItem? {
        appState.task(withID: taskID)
    }

    var body: some View {
        ZStack {
            AppBackground()

            if let task {
                content(for: task)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedMicrotask) { microtask in
            MicrotaskFocusView(taskID: taskID, microtask: microtask)
        }
        .onAppear { cascadeIn() }
    }

    private func content(for task: TaskItem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(task.title)
                    .font(.fokusRounded(.title2))
                    .foregroundStyle(Color.textPrimary)
                    .padding(.top, 8)

                progressSummary(for: task)

                if task.isComplete {
                    completeBanner
                }

                VStack(spacing: Layout.cardSpacing) {
                    let sorted = task.microtasks.sorted { $0.orderIndex < $1.orderIndex }
                    let firstOpenID = sorted.first(where: { $0.status == .todo })?.id

                    ForEach(Array(sorted.enumerated()), id: \.element.id) { index, microtask in
                        if index < visibleRows {
                            MicrotaskRow(
                                microtask: microtask,
                                isStartHere: microtask.id == firstOpenID
                            ) {
                                if microtask.status == .todo {
                                    selectedMicrotask = microtask
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, Layout.screenPadding)
        }
    }

    private func cascadeIn() {
        guard let task, !hasCascaded else {
            visibleRows = task?.microtasks.count ?? 0
            return
        }
        hasCascaded = true
        visibleRows = 0
        Task {
            for row in 1...max(task.microtasks.count, 1) {
                try? await Task.sleep(for: .milliseconds(140))
                withAnimation(.fokusSpring) { visibleRows = row }
            }
        }
    }

    private func progressSummary(for task: TaskItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(task.completedMicrotasksCount) of \(task.microtasks.count) steps done")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text("\(Int(task.progress * 100))%")
                    .font(.fokusRounded(.subheadline))
                    .foregroundStyle(Color.focus)
            }

            ProgressView(value: task.progress)
                .tint(.focus)

            Text(task.completedMicrotasksCount == 0
                 ? "Just pick the first one. It's tiny on purpose."
                 : task.isComplete ? "All done. Genuinely impressive." : "Downhill from here.")
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)
        }
        .padding(16)
        .fokusCard()
        .accessibilityElement(children: .combine)
    }

    private var completeBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title3)
                .foregroundStyle(Color.success)
            Text("Task complete. The mountain is now a pancake.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.textPrimary)
            Spacer()
        }
        .padding(14)
        .fokusCard(fill: .surfaceRaised)
    }
}

// MARK: - Row

struct MicrotaskRow: View {
    let microtask: Microtask
    let isStartHere: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                statusIcon

                VStack(alignment: .leading, spacing: 4) {
                    if isStartHere {
                        Text("START HERE")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.focus)
                    }
                    Text(microtask.text)
                        .font(.body)
                        .foregroundStyle(microtask.status == .done ? Color.textSecondary : Color.textPrimary)
                        .strikethrough(microtask.status == .done)
                        .multilineTextAlignment(.leading)
                    Text("\(microtask.estimatedMinutes) min")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                if microtask.status == .todo {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .padding(16)
            .fokusCard(fill: isStartHere ? .surfaceRaised : .surface)
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cardRadius)
                    .stroke(isStartHere ? Color.focus.opacity(0.35) : .clear, lineWidth: 2)
            )
        }
        .disabled(microtask.status == .done)
        .accessibilityLabel(
            (isStartHere ? "Start here: " : "") + microtask.text +
            ", \(microtask.estimatedMinutes) minutes" +
            (microtask.status == .done ? ", completed" : "")
        )
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch microtask.status {
        case .todo:
            Circle()
                .stroke(isStartHere ? Color.focus : Color.brand, lineWidth: 2)
                .frame(width: 22, height: 22)
        case .done:
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(Color.success)
        case .skipped:
            Image(systemName: "arrow.right.circle")
                .font(.title3)
                .foregroundStyle(Color.textSecondary)
        }
    }
}

#Preview {
    let state = AppState()
    state.tasks = MockData.sampleTasks
    return NavigationStack {
        TaskDetailView(taskID: MockData.sampleTasks[0].id)
            .environment(state)
    }
}
