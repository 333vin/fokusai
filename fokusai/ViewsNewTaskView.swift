//
//  NewTaskView.swift
//  fokusai
//
//  Created by Navneet Sharma on 2026-07-16.
//

import SwiftUI

struct NewTaskView: View {
    @Environment(\.dismiss) private var dismiss
    let appState: AppState
    
    @State private var taskTitle = ""
    @State private var showingDetails = false
    @State private var deadline: Date = Date().addingTimeInterval(86400 * 7)
    @State private var hasDeadline = false
    @State private var taskFormat: TaskFormat = .other
    @State private var scope = ""
    @State private var rubric = ""
    @State private var timeAvailable = 30
    @State private var isDecomposing = false
    
    enum TaskFormat: String, CaseIterable {
        case essay = "Essay"
        case problemSet = "Problem Set"
        case reading = "Reading"
        case test = "Test"
        case project = "Project"
        case chore = "Chore"
        case other = "Other"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Main question
                        Text("What are you putting off?")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.textPrimary)
                            .padding(.horizontal, Layout.screenPadding)
                            .padding(.top, 8)
                        
                        // Title field
                        TextField("Type your task here...", text: $taskTitle, axis: .vertical)
                            .font(.body)
                            .foregroundStyle(Color.textPrimary)
                            .padding(16)
                            .lineLimit(3...6)
                            .background(
                                RoundedRectangle(cornerRadius: Layout.cardRadius)
                                    .fill(Color.surface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Layout.cardRadius)
                                            .stroke(Color.stroke, lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, Layout.screenPadding)
                        
                        // Details disclosure
                        VStack(alignment: .leading, spacing: 16) {
                            Button {
                                withAnimation(.fokusSpring) {
                                    showingDetails.toggle()
                                }
                            } label: {
                                HStack {
                                    Text("Add details")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.textSecondary)
                                    Image(systemName: showingDetails ? "chevron.up" : "chevron.down")
                                        .font(.caption)
                                        .foregroundStyle(Color.textSecondary)
                                }
                            }
                            
                            if showingDetails {
                                VStack(alignment: .leading, spacing: 20) {
                                    // Deadline
                                    VStack(alignment: .leading, spacing: 8) {
                                        Toggle("Has deadline", isOn: $hasDeadline)
                                            .font(.subheadline)
                                            .foregroundStyle(Color.textPrimary)
                                            .tint(.brand)
                                        
                                        if hasDeadline {
                                            DatePicker("Due date", selection: $deadline, displayedComponents: .date)
                                                .font(.subheadline)
                                                .foregroundStyle(Color.textPrimary)
                                        }
                                    }
                                    
                                    // Format
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Type")
                                            .font(.subheadline)
                                            .foregroundStyle(Color.textSecondary)
                                        
                                        Picker("Format", selection: $taskFormat) {
                                            ForEach(TaskFormat.allCases, id: \.self) { format in
                                                Text(format.rawValue).tag(format)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .tint(.brand)
                                    }
                                    
                                    // Scope
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Scope (optional)")
                                            .font(.subheadline)
                                            .foregroundStyle(Color.textSecondary)
                                        
                                        TextField("e.g., 5 pages, 10 problems", text: $scope)
                                            .font(.body)
                                            .foregroundStyle(Color.textPrimary)
                                            .padding(12)
                                            .background(
                                                RoundedRectangle(cornerRadius: Layout.buttonRadius)
                                                    .fill(Color.surfaceRaised)
                                            )
                                    }
                                    
                                    // Rubric
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Notes or rubric (optional)")
                                            .font(.subheadline)
                                            .foregroundStyle(Color.textSecondary)
                                        
                                        TextField("Paste rubric or add notes...", text: $rubric, axis: .vertical)
                                            .font(.body)
                                            .foregroundStyle(Color.textPrimary)
                                            .padding(12)
                                            .lineLimit(3...6)
                                            .background(
                                                RoundedRectangle(cornerRadius: Layout.buttonRadius)
                                                    .fill(Color.surfaceRaised)
                                            )
                                    }
                                    
                                    // Time available
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Time available now: \(timeAvailable) min")
                                            .font(.subheadline)
                                            .foregroundStyle(Color.textSecondary)
                                        
                                        Slider(value: Binding(
                                            get: { Double(timeAvailable) },
                                            set: { timeAvailable = Int($0) }
                                        ), in: 5...120, step: 5)
                                        .tint(.brand)
                                    }
                                    
                                    // Photo placeholder
                                    Button {
                                        // Future: image picker
                                    } label: {
                                        HStack {
                                            Image(systemName: "photo")
                                            Text("Attach assignment photo")
                                        }
                                        .font(.subheadline)
                                        .foregroundStyle(Color.brand)
                                    }
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: Layout.cardRadius)
                                        .fill(Color.surface)
                                )
                            }
                        }
                        .padding(.horizontal, Layout.screenPadding)
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.vertical, 8)
                }
                
                // Bottom button
                VStack {
                    Spacer()
                    Button {
                        createTask()
                    } label: {
                        Text("Break it down")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.bg)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .fill(taskTitle.isEmpty ? Color.textSecondary : Color.accent)
                            )
                            .padding(.horizontal, Layout.screenPadding)
                    }
                    .disabled(taskTitle.isEmpty)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }
    
    private func createTask() {
        // Mock decomposition: create a task with mock microtasks
        let microtasks = mockDecompose(title: taskTitle)
        
        let newTask = Task(
            title: taskTitle,
            taskType: taskFormat.rawValue.lowercased(),
            microtasks: microtasks
        )
        
        Task {
            do {
                try await appState.addTask(newTask)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Failed to create task: \(error)")
            }
        }
    }
    
    private func mockDecompose(title: String) -> [Microtask] {
        // Simple mock: create 3-5 microtasks based on the title
        let count = Int.random(in: 3...5)
        return (1...count).map { index in
            Microtask(
                orderIndex: index,
                text: "Step \(index): \(title.prefix(20))...",
                estimatedMinutes: Int.random(in: 2...5)
            )
        }
    }
}

#Preview {
    NewTaskView(appState: AppState())
}
