//
//  MicrotaskFocusView.swift
//  fokusai
//
//  Created by Navneet Sharma on 2026-07-16.
//

import SwiftUI

struct MicrotaskFocusView: View {
    let task: Task
    let microtask: Microtask
    let appState: AppState
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var timeRemaining: Int
    @State private var isTimerRunning = false
    @State private var showingCompletion = false
    
    init(task: Task, microtask: Microtask, appState: AppState) {
        self.task = task
        self.microtask = microtask
        self.appState = appState
        self._timeRemaining = State(initialValue: microtask.estimatedMinutes * 60)
    }
    
    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Focus Orb
                FocusOrb(
                    state: isTimerRunning ? .pulsing : .dim,
                    level: appState.currentLevel
                )
                
                // Timer
                Text(timeString(from: timeRemaining))
                    .font(.system(size: 56, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                    .monospacedDigit()
                
                // Microtask text
                VStack(spacing: 12) {
                    Text(microtask.text)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Text("Just start — only \(microtask.estimatedMinutes) minutes.")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    // Done button (accent color - primary action)
                    Button {
                        completeTask(ranOutOfTime: false)
                    } label: {
                        Text("Done")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.bg)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .fill(Color.accent)
                            )
                            .shadow(color: .accent.opacity(0.3), radius: 12, x: 0, y: 6)
                    }
                    
                    // Ran out of time button (quiet)
                    Button {
                        completeTask(ranOutOfTime: true)
                    } label: {
                        Text("Ran out of time")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                .padding(.horizontal, Layout.screenPadding)
                .padding(.bottom, 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isTimerRunning)
        .toolbar {
            if !isTimerRunning {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            isTimerRunning = false
        }
    }
    
    private func startTimer() {
        isTimerRunning = true
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            guard isTimerRunning else {
                timer.invalidate()
                return
            }
            
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer.invalidate()
                isTimerRunning = false
            }
        }
    }
    
    private func completeTask(ranOutOfTime: Bool) {
        let elapsedTime = microtask.estimatedMinutes - (timeRemaining / 60)
        let actualMinutes = max(1, elapsedTime)
        
        // Award XP: +10 for completion, +5 for running out of time
        Task {
            do {
                try await appState.completeMicrotask(
                    taskId: task.id,
                    microtaskId: microtask.id,
                    actualMinutes: actualMinutes
                )
                
                // Show brief success feedback
                await MainActor.run {
                    withAnimation(.fokusSpring) {
                        showingCompletion = true
                    }
                }
                
                // Dismiss after a brief moment
                try await Task.sleep(nanoseconds: 500_000_000)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Failed to complete microtask: \(error)")
            }
        }
    }
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

#Preview {
    NavigationStack {
        MicrotaskFocusView(
            task: MockData.sampleTasks[0],
            microtask: MockData.sampleTasks[0].microtasks[2],
            appState: AppState()
        )
    }
}
