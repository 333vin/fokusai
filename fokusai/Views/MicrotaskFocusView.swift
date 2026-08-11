//
//  MicrotaskFocusView.swift
//  fokusai
//
//  One microtask, large and centered; orb pulsing beside it; a short
//  countdown. Two actions — "Done" and "Ran out of time" — and both are wins.
//

import SwiftUI

struct MicrotaskFocusView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let taskID: UUID
    let microtask: Microtask

    @State private var secondsRemaining: Int
    @State private var timerRunning = false
    @State private var rewardResult: RewardResult?
    @State private var nudgeLine = Copy.random(.focusNudge)

    init(taskID: UUID, microtask: Microtask) {
        self.taskID = taskID
        self.microtask = microtask
        self._secondsRemaining = State(initialValue: microtask.estimatedMinutes * 60)
    }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 32) {
                Spacer()

                FocusOrb(
                    state: rewardResult != nil ? .flare : (timerRunning ? .pulsing : .dim),
                    level: appState.currentLevel,
                    skin: .named(appState.profile.selectedSkin),
                    size: 130
                )

                VStack(spacing: 14) {
                    Text(timeString(secondsRemaining))
                        .font(.fokusDisplay(56))
                        .foregroundStyle(secondsRemaining == 0 ? Color.textSecondary : Color.textPrimary)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .accessibilityLabel(timeAccessibilityLabel)

                    Text(microtask.text)
                        .font(.fokusRounded(.title3, weight: .medium))
                        .foregroundStyle(Color.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Text(secondsRemaining == 0
                         ? "Time's up. Either way, you win something."
                         : nudgeLine)
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                VStack(spacing: 14) {
                    Button {
                        complete(.done)
                    } label: {
                        Text("Done")
                            .frame(maxWidth: .infinity)
                            .fokusPrimaryCapsule()
                    }
                    .accessibilityHint("Completes this step and collects your reward")

                    Button {
                        complete(.ranOutOfTime)
                    } label: {
                        Text("Ran out of time")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                            .padding(.vertical, 6)
                    }
                    .accessibilityHint("Still counts. Awards 5 XP and keeps the step available")
                }
                .padding(.horizontal, Layout.screenPadding)
                .padding(.bottom, 24)
            }

            if let result = rewardResult {
                RewardSequenceView(
                    result: result,
                    xpAfter: appState.currentXP,
                    orbLevel: appState.currentLevel,
                    orbSkin: .named(appState.profile.selectedSkin)
                ) {
                    dismiss()
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if rewardResult == nil {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color.textSecondary)
                    }
                    .accessibilityLabel("Leave without finishing")
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear { startTimer() }
        .onDisappear { timerRunning = false }
    }

    // MARK: Timer

    private func startTimer() {
        guard !timerRunning else { return }
        timerRunning = true
        Task {
            while timerRunning && secondsRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                if timerRunning && secondsRemaining > 0 {
                    withAnimation(.linear(duration: 0.2)) {
                        secondsRemaining -= 1
                    }
                }
            }
            timerRunning = false
        }
    }

    // MARK: Completion

    private func complete(_ outcome: CompletionOutcome) {
        guard rewardResult == nil else { return }
        timerRunning = false

        let elapsedMinutes = max(1, microtask.estimatedMinutes - secondsRemaining / 60)
        let result = appState.completeMicrotask(
            taskId: taskID,
            microtaskId: microtask.id,
            outcome: outcome,
            actualMinutes: elapsedMinutes
        )

        if outcome == .done {
            Haptics.success()
            SoundPlayer.playCompletion(appState.profile.selectedSound)
        } else {
            Haptics.light()
        }

        withAnimation(.fokusCelebration) {
            rewardResult = result
        }
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private var timeAccessibilityLabel: String {
        let minutes = secondsRemaining / 60
        let seconds = secondsRemaining % 60
        return "\(minutes) minutes \(seconds) seconds remaining"
    }
}

#Preview {
    let state = AppState()
    state.tasks = MockData.sampleTasks
    return NavigationStack {
        MicrotaskFocusView(
            taskID: MockData.sampleTasks[0].id,
            microtask: MockData.sampleTasks[0].microtasks[2]
        )
        .environment(state)
    }
}
