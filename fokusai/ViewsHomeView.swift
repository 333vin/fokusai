//
//  HomeView.swift
//  fokusai
//
//  Created by Navneet Sharma on 2026-07-16.
//

import SwiftUI

struct HomeView: View {
    @State private var appState = AppState()
    @State private var showingNewTask = false
    @State private var selectedTask: Task?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Focus Orb
                        FocusOrb(
                            state: appState.tasks.contains(where: { $0.status == .active }) ? .dim : .dim,
                            level: appState.currentLevel
                        )
                        .padding(.top, 20)
                        
                        // Stats Bar
                        statsBar
                        
                        // Task List
                        VStack(spacing: Layout.cardSpacing) {
                            if activeTasks.isEmpty {
                                emptyState
                            } else {
                                ForEach(activeTasks) { task in
                                    TaskCard(task: task)
                                        .onTapGesture {
                                            selectedTask = task
                                        }
                                }
                            }
                        }
                        .padding(.horizontal, Layout.screenPadding)
                    }
                }
                
                // Floating New Task Button
                VStack {
                    Spacer()
                    newTaskButton
                        .padding(.bottom, 32)
                }
            }
            .navigationDestination(item: $selectedTask) { task in
                TaskDetailView(task: task, appState: appState)
            }
            .sheet(isPresented: $showingNewTask) {
                NewTaskView(appState: appState)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    BrandLogo(size: .small, showGradient: true)
                }
            }
        }
    }
    
    private var activeTasks: [Task] {
        appState.tasks.filter { $0.status == .active }
    }
    
    private var statsBar: some View {
        HStack(spacing: 20) {
            // Streak
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(Color.accent)
                Text("\(appState.streakCount)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accent)
                Text("day streak")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
            
            Spacer()
            
            // Level & XP Progress
            HStack(spacing: 8) {
                Text("L\(appState.currentLevel)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.surface)
                        .frame(width: 100, height: 8)
                    
                    Capsule()
                        .fill(Color.brand)
                        .frame(width: 100 * appState.xpProgress, height: 8)
                }
                
                Text("\(appState.currentXP) XP")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(.horizontal, Layout.screenPadding)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("Ready to start?")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.textPrimary)
            
            Text("Tap below to add your first task.\nWe'll break it into tiny steps.")
                .font(.body)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
    }
    
    private var newTaskButton: some View {
        Button {
            showingNewTask = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .fontWeight(.semibold)
                Text("New task")
                    .fontWeight(.semibold)
            }
            .font(.body)
            .foregroundStyle(Color.bg)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(Color.accent)
            )
            .shadow(color: .accent.opacity(0.3), radius: 12, x: 0, y: 6)
        }
    }
}

struct TaskCard: View {
    let task: Task
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(task.title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(Color.textPrimary)
            
            // Progress
            HStack(spacing: 8) {
                Text("\(task.completedMicrotasksCount)/\(task.microtasks.count) steps")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                
                Spacer()
                
                if task.completedMicrotasksCount > 0 {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.success)
                        .font(.caption)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.surface)
                        .frame(height: 4)
                    
                    Capsule()
                        .fill(Color.brand)
                        .frame(width: geometry.size.width * task.progress, height: 4)
                }
            }
            .frame(height: 4)
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

#Preview {
    HomeView()
}
