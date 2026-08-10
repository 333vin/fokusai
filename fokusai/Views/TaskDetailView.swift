//
//  TaskDetailView.swift
//  fokusai
//
//  Created by Navneet Sharma on 2026-07-16.
//

import SwiftUI

struct TaskDetailView: View {
    let task: Task
    let appState: AppState
    
    @State private var selectedMicrotask: Microtask?
    
    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Task title
                    Text(task.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textPrimary)
                        .padding(.horizontal, Layout.screenPadding)
                        .padding(.top, 8)
                    
                    // Progress summary
                    progressSummary
                        .padding(.horizontal, Layout.screenPadding)
                    
                    // Microtask list
                    VStack(spacing: Layout.cardSpacing) {
                        ForEach(Array(task.microtasks.enumerated()), id: \.element.id) { index, microtask in
                            MicrotaskCard(
                                microtask: microtask,
                                isFirst: index == 0 && microtask.status == .todo,
                                onTap: {
                                    if microtask.status == .todo {
                                        selectedMicrotask = microtask
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, Layout.screenPadding)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedMicrotask) { microtask in
            MicrotaskFocusView(
                task: task,
                microtask: microtask,
                appState: appState
            )
        }
    }
    
    private var progressSummary: some View {
        HStack(spacing: 12) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.surface, lineWidth: 4)
                    .frame(width: 48, height: 48)
                
                Circle()
                    .trim(from: 0, to: task.progress)
                    .stroke(Color.brand, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(task.progress * 100))%")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(task.completedMicrotasksCount) of \(task.microtasks.count) steps complete")
                    .font(.body)
                    .foregroundStyle(Color.textPrimary)
                
                if task.completedMicrotasksCount > 0 {
                    Text("You're making progress!")
                        .font(.caption)
                        .foregroundStyle(Color.success)
                } else {
                    Text("Ready to start? Just pick the first one.")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardRadius)
                .fill(Color.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: Layout.cardRadius)
                        .stroke(Color.stroke, lineWidth: 1)
                )
        )
    }
}

struct MicrotaskCard: View {
    let microtask: Microtask
    let isFirst: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Status icon
                statusIcon
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    if isFirst {
                        Text("START HERE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.accent)
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
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: Layout.cardRadius)
                    .fill(isFirst ? Color.surfaceRaised : Color.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Layout.cardRadius)
                            .stroke(isFirst ? Color.accent.opacity(0.3) : Color.stroke, lineWidth: isFirst ? 2 : 1)
                    )
            )
        }
        .disabled(microtask.status == .done)
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch microtask.status {
        case .todo:
            Circle()
                .stroke(isFirst ? Color.accent : Color.brand, lineWidth: 2)
                .frame(width: 24, height: 24)
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
    NavigationStack {
        TaskDetailView(
            task: MockData.sampleTasks[0],
            appState: AppState()
        )
    }
}
