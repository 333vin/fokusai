//
//  HomeView.swift
//  fokusai
//
//  The calm deep-blue room: Focus Orb centerpiece, stat bar, active task
//  cards, and a warm witty empty state. Celebration lives elsewhere.
//

import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState

    @State private var showingNewTask = false
    @State private var selectedTask: TaskItem?
    @State private var emptyStateLine = Copy.random(.homeEmpty)

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                List {
                    Section {
                        // The companion. Awake when something's in motion.
                        FocusOrb(
                            state: appState.activeTasks.isEmpty ? .dim : .pulsing,
                            level: appState.currentLevel,
                            core: .named(appState.profile.selectedOrbCore),
                            aura: .named(appState.profile.selectedOrbAura),
                            activity: appState.activeTasks.isEmpty ? .idle : .busy,
                            size: 130
                        )
                        .buttonTip("Focus Orb", detail: "Your companion. Its little face changes with mood, time of day, and what you just did.")
                        .frame(maxWidth: .infinity)
                        .padding(.top, -4)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 4, trailing: 0))

                    Section {
                        StatBar(
                            level: appState.currentLevel,
                            xpProgress: appState.xpProgress,
                            xp: appState.currentXP,
                            streak: appState.streakCount,
                                flairKey: appState.profile.selectedAppAccent
                        ) {
                            navigateToUpgrades = true
                        }

                        if appState.pendingFreezeNotice || appState.pendingStreakResetNotice || showDeleteTip {
                            noticeBanner
                        }

                        if appState.activeTasks.isEmpty {
                            emptyState
                        } else {
                            ForEach(appState.activeTasks) { task in
                                TaskCard(task: task) {
                                    selectedTask = task
                                }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        Haptics.light()
                                        appState.markDeleteTipSeen()
                                        withAnimation(.fokusSpring) {
                                            appState.deleteTask(task.id)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .accessibilityLabel("Delete \(task.title)")
                                }
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(
                        top: Layout.cardSpacing / 2,
                        leading: Layout.screenPadding,
                        bottom: Layout.cardSpacing / 2,
                        trailing: Layout.screenPadding
                    ))

                    Section {
                        Color.clear.frame(height: 110)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)

                // Floating "+ New task"
                VStack {
                    Spacer()
                    Button {
                        showingNewTask = true
                    } label: {
                        Label("New task", systemImage: "plus")
                            .fokusPrimaryCapsule()
                    }
                    .buttonTip("New task", detail: "Name something you're putting off. We'll break it into tiny steps.")
                    .padding(.bottom, 24)
                }
            }
            .navigationDestination(item: $selectedTask) { task in
                TaskDetailView(taskID: task.id)
            }
            .navigationDestination(isPresented: $navigateToUpgrades) {
                UpgradesView()
            }
            .sheet(isPresented: $showingNewTask) {
                NewTaskView { newTask in
                    selectedTask = newTask
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    BrandLogo(size: .small, showGradient: true)
                }
                #if DEBUG
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        OrbLabView()
                    } label: {
                        Image(systemName: "circle.hexagongrid.circle")
                            .foregroundStyle(Color.textSecondary)
                    }
                    .buttonTip("Orb Lab", detail: "Debug playground for orb skins and states.")
                    .accessibilityLabel("Orb Lab (debug)")
                }
                #endif
            }
            .onAppear {
                if appState.activeTasks.isEmpty {
                    emptyStateLine = Copy.random(.homeEmpty)
                }
            }
        }
    }

    @State private var navigateToUpgrades = false

    // MARK: Warm notices (freeze used / streak reset / delete tip)

    /// Shown once after the tutorial, while the sample task is still around,
    /// so the user learns the delete gesture on something disposable.
    private var showDeleteTip: Bool {
        appState.hasCompletedTutorial
            && !appState.hasSeenDeleteTip
            && !appState.activeTasks.isEmpty
    }

    @ViewBuilder
    private var noticeBanner: some View {
        if appState.pendingFreezeNotice {
            NoticeCard(
                symbol: "snowflake",
                tint: .focus,
                message: Copy.random(.freezeUsed)
            ) {
                appState.pendingFreezeNotice = false
            }
        } else if appState.pendingStreakResetNotice {
            NoticeCard(
                symbol: "sunrise.fill",
                tint: .brand,
                message: Copy.random(.streakReturn)
            ) {
                appState.pendingStreakResetNotice = false
            }
        } else if showDeleteTip {
            NoticeCard(
                symbol: "hand.point.left.fill",
                tint: .brand,
                message: "Quick tip: swipe left on a task to delete it. That sample essay won't take it personally."
            ) {
                appState.markDeleteTipSeen()
            }
        }
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: 14) {
            Text(emptyStateLine)
                .font(.fokusRounded(.title3, weight: .medium))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)

            Text("Type the thing. We'll shrink it until starting feels easy.")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
        .padding(.horizontal, 20)
        .fokusCard()
    }
}

// MARK: - Notice card

private struct NoticeCard: View {
    let symbol: String
    let tint: Color
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.body)
                .foregroundStyle(tint)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.textSecondary)
            }
            .accessibilityLabel("Dismiss")
        }
        .padding(14)
        .fokusCard(fill: .surfaceRaised)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

// MARK: - Task card

struct TaskCard: View {
    let task: TaskItem
    var onTap: (() -> Void)?

    private var nextStep: Microtask? {
        task.microtasks
            .sorted { $0.orderIndex < $1.orderIndex }
            .first { $0.status == .todo }
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Text(task.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.textPrimary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Text("\(task.completedMicrotasksCount) / \(task.microtasks.count)")
                        .font(.fokusRounded(.footnote))
                        .foregroundStyle(Color.textSecondary)
                }

                if let nextStep {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.turn.down.right")
                            .font(.caption)
                            .foregroundStyle(Color.focus)
                        Text(nextStep.text)
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                            .lineLimit(1)
                    }
                }

                ProgressView(value: task.progress)
                    .tint(.focus)
            }
            .padding(16)
            .fokusCard()
        }
        .accessibilityLabel(
            "\(task.title), \(task.completedMicrotasksCount) of \(task.microtasks.count) steps done" +
            (nextStep.map { ". Next: \($0.text)" } ?? "")
        )
    }
}

#Preview("Populated") {
    let state = AppState()
    state.tasks = MockData.sampleTasks
    return HomeView().environment(state)
}

#Preview("Empty") {
    HomeView().environment(AppState())
}
