//
//  TutorialView.swift
//  fokusai
//
//  The interactive first-run tutorial: six short beats, under 90 seconds.
//  The user meets the orb, sees a decomposition (of the sample task or their
//  own), completes a real microtask, feels the reward, gets a peek at orb
//  cosmetics, and lands on Home with XP and a streak.
//  Skippable; replayable from Settings (replay never re-awards XP).
//

import SwiftUI

struct TutorialView: View {
    @Environment(AppState.self) private var appState
    var isReplay = false
    var onFinish: (() -> Void)?

    private enum Beat: Int, Comparable {
        case meetOrb, selfKnowledge, magic, reward, cosmetics, world
        static func < (lhs: Beat, rhs: Beat) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    // Beat 3 sample. Left untouched it uses these canned steps; an edited
    // title gets a real decomposition instead.
    private static let sampleTaskTitle = "Write a history essay 😩"
    private static let cannedSteps: [(text: String, minutes: Int)] = [
        ("Open a doc and write one ugly sentence.", 2),
        ("Write your thesis, badly on purpose.", 3),
        ("List 3 points that back it up.", 3),
        ("Turn point one into two sentences.", 4),
        ("Find one quote that fits.", 3),
    ]

    @State private var beat: Beat = .meetOrb
    @State private var orbVisible = false

    // Beat 2
    @State private var selectedChip: String?
    private static let chips = ["Homework", "Studying", "Chores", "Everything, honestly"]

    // Beat 3
    @State private var taskTitle = Self.sampleTaskTitle
    @State private var steps: [(text: String, minutes: Int)] = Self.cannedSteps
    @FocusState private var titleFocused: Bool
    @State private var isDecomposing = false
    @State private var visibleSteps = 0
    @State private var createdTask: TaskItem?

    // Beat 4
    @State private var secondsRemaining = 120
    @State private var timerRunning = false
    @State private var stepDone = false
    @State private var showConfetti = false
    @State private var earnedXPLabel: Int = 0
    @State private var streakLabel: Int = 0

    // Cosmetics teaser. Preview only; nothing here can equip.
    @State private var teaserCoreKey: String?
    private static let teaserCoreKeys = ["ember", "nebula", "solar"]

    // Beat 5
    @State private var tourStep = 0
    private static let tourCallouts: [(symbol: String, line: String)] = [
        ("circle.circle", "Your level and XP ring. Every tiny step feeds it."),
        ("flame.fill", "Your streak. One 2-minute step a day keeps it alive."),
        ("sparkles", "Upgrades. Level up to unlock new looks for your orb."),
    ]

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                header

                Spacer(minLength: 0)

                Group {
                    switch beat {
                    case .meetOrb: meetOrbBeat
                    case .selfKnowledge: selfKnowledgeBeat
                    case .magic: magicBeat
                    case .reward: rewardBeat
                    case .cosmetics: cosmeticsBeat
                    case .world: worldBeat
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .trailing)))

                Spacer(minLength: 0)
            }
            .padding(.horizontal, Layout.screenPadding)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) { orbVisible = true }
        }
    }

    // MARK: Header (skip)

    private var header: some View {
        HStack {
            Spacer()
            Button("Skip") { skip() }
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .accessibilityHint("Skips the tutorial and goes to Home")
        }
        .padding(.top, 8)
    }

    // MARK: Beat 1 — Meet your Orb

    private var meetOrbBeat: some View {
        VStack(spacing: 32) {
            FocusOrb(state: .dim, level: 1, activity: .idle)
                .opacity(orbVisible ? 1 : 0)

            Text("This is your Focus Orb.\nIt grows when you do, and waits patiently when you don't.")
                .font(.fokusRounded(.title3, weight: .medium))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
                .opacity(orbVisible ? 1 : 0)

            Button("Nice to meet you") { advance(to: .selfKnowledge) }
                .fokusPrimaryCapsule()
        }
    }

    // MARK: Beat 2 — One tap of self-knowledge

    private var selfKnowledgeBeat: some View {
        VStack(spacing: 28) {
            FocusOrb(state: .dim, level: 1, activity: .idle, size: 100)

            Text("What do you put off the most?")
                .font(.fokusRounded(.title2))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                ForEach(Self.chips, id: \.self) { chip in
                    Button {
                        selectedChip = chip
                        Haptics.light()
                        if !isReplay {
                            appState.setProcrastinationType(chip)
                        }
                        Task {
                            try? await Task.sleep(for: .milliseconds(350))
                            advance(to: .magic)
                        }
                    } label: {
                        Text(chip)
                            .font(.body.weight(.medium))
                            .foregroundStyle(selectedChip == chip ? Color.bg : Color.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                Capsule().fill(selectedChip == chip ? Color.brand : Color.surface)
                                    .overlay(Capsule().stroke(Color.stroke, lineWidth: 1))
                            )
                    }
                }
            }
        }
    }

    // MARK: Beat 3 — Watch the magic

    private var magicBeat: some View {
        VStack(spacing: 20) {
            if visibleSteps == 0 {
                Text("Here's a task nobody wants to start:")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)

                TextField("The thing you're avoiding", text: $taskTitle)
                    .font(.fokusRounded(.title3))
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .submitLabel(.done)
                    .focused($titleFocused)
                    .disabled(isDecomposing)
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .fokusCard()
                    .accessibilityHint("Edit to use one of your own tasks")

                if !isDecomposing {
                    Text("Tap it to swap in a real one of yours.")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }

            if isDecomposing {
                VStack(spacing: 20) {
                    FocusOrb(state: .pulsing, level: 1, activity: .thinking, size: 110)
                    RotatingCopyLine(lines: Copy.all(.decompositionLoading), interval: 1.2)
                }
                .padding(.top, 12)
            } else if visibleSteps == 0 {
                Button {
                    startDecomposition()
                } label: {
                    Label("Break it down", systemImage: "wand.and.stars")
                }
                .fokusPrimaryCapsule()
                .shadow(color: Color.focus.opacity(0.4), radius: 16)
                .padding(.top, 8)
            }

            if visibleSteps > 0 {
                Text("One scary task → \(stepCountWord) easy moves:")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)

                VStack(spacing: 10) {
                    ForEach(Array(steps.prefix(visibleSteps).enumerated()), id: \.offset) { index, step in
                        tutorialStepCard(index: index, text: step.text, minutes: step.minutes, highlighted: index == 0)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }

                if visibleSteps == steps.count {
                    Button("Try the first one. It's only \(minutesLabel(firstStepMinutes))") {
                        advance(to: .reward)
                    }
                    .fokusPrimaryCapsule()
                    .padding(.top, 8)
                    .transition(.opacity)
                }
            }
        }
    }

    private func tutorialStepCard(index: Int, text: String, minutes: Int, highlighted: Bool) -> some View {
        HStack(spacing: 12) {
            Circle()
                .stroke(highlighted ? Color.focus : Color.brand, lineWidth: 2)
                .frame(width: 22, height: 22)
            VStack(alignment: .leading, spacing: 3) {
                if highlighted {
                    Text("START HERE")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.focus)
                }
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(Color.textPrimary)
                Text("\(minutes) min")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
        }
        .padding(14)
        .fokusCard(fill: highlighted ? .surfaceRaised : .surface)
    }

    private var trimmedTitle: String {
        taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var firstStepMinutes: Int { max(1, steps.first?.minutes ?? 2) }

    private var stepCountWord: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        return formatter.string(from: steps.count as NSNumber) ?? "\(steps.count)"
    }

    private func minutesLabel(_ minutes: Int) -> String {
        minutes == 1 ? "1 minute" : "\(minutes) minutes"
    }

    private func startDecomposition() {
        titleFocused = false
        let isCustom = !trimmedTitle.isEmpty && trimmedTitle != Self.sampleTaskTitle
        let title = isCustom ? trimmedTitle : Self.sampleTaskTitle
        if !isCustom { taskTitle = Self.sampleTaskTitle }

        withAnimation(.fokusSpring) { isDecomposing = true }
        Task {
            if isCustom {
                let start = Date()
                let microtasks = await DecompositionService.decompose(
                    title: title,
                    multiplier: appState.profile.estimateMultiplier
                )
                let decomposed = microtasks
                    .sorted { $0.orderIndex < $1.orderIndex }
                    .map { (text: $0.text, minutes: $0.estimatedMinutes) }
                steps = decomposed.isEmpty ? Self.cannedSteps : decomposed
                // Keep the "thinking" beat at least as long as the canned one.
                let remaining = 2.4 - Date().timeIntervalSince(start)
                if remaining > 0 { try? await Task.sleep(for: .seconds(remaining)) }
            } else {
                steps = Self.cannedSteps
                try? await Task.sleep(for: .seconds(2.4))
            }
            secondsRemaining = firstStepMinutes * 60
            withAnimation(.fokusSpring) { isDecomposing = false }

            // Create the real task so it lives on Home afterward.
            if !isReplay {
                let microtasks = steps.enumerated().map { index, step in
                    Microtask(orderIndex: index + 1, text: step.text, estimatedMinutes: step.minutes)
                }
                let task = TaskItem(title: title, taskType: isCustom ? nil : "essay", microtasks: microtasks)
                appState.addTask(task)
                createdTask = task
            }

            // Cascade the cards in.
            for step in 1...steps.count {
                try? await Task.sleep(for: .milliseconds(180))
                withAnimation(.fokusSpring) { visibleSteps = step }
            }
        }
    }

    // MARK: Beat 4 — Feel the reward

    private var rewardBeat: some View {
        VStack(spacing: 24) {
            ZStack {
                FocusOrb(
                    state: stepDone ? .flare : .pulsing,
                    level: 1,
                    activity: stepDone ? .celebrating : .focusing,
                    size: 120
                )
                if showConfetti {
                    ConfettiBurst()
                        .frame(width: 280, height: 280)
                }
            }

            if stepDone {
                VStack(spacing: 10) {
                    Text("+\(earnedXPLabel) XP")
                        .font(.fokusDisplay(40))
                        .foregroundStyle(Color.reward)
                        .transition(.scale.combined(with: .opacity))

                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(Color.focus)
                        Text("Streak: \(streakLabel)")
                            .font(.fokusRounded(.title3))
                            .foregroundStyle(Color.textPrimary)
                    }

                    Text(Copy.random(.completion))
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }

                Button("That felt good. What else?") { advance(to: .cosmetics) }
                    .fokusPrimaryCapsule()
                    .padding(.top, 8)
            } else {
                VStack(spacing: 8) {
                    Text(steps.first?.text ?? Self.cannedSteps[0].text)
                        .font(.fokusRounded(.title3))
                        .foregroundStyle(Color.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(timeString(secondsRemaining))
                        .font(.fokusDisplay(52))
                        .foregroundStyle(Color.textPrimary)
                        .monospacedDigit()

                    Text("Just start. Only \(minutesLabel(firstStepMinutes)).")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                }

                Button("Done") { completeTutorialStep() }
                    .fokusPrimaryCapsule()
            }
        }
        .onAppear { startTutorialTimer() }
    }

    private func startTutorialTimer() {
        guard !timerRunning else { return }
        timerRunning = true
        Task {
            while timerRunning && secondsRemaining > 0 && !stepDone {
                try? await Task.sleep(for: .seconds(1))
                if !stepDone { secondsRemaining -= 1 }
            }
        }
    }

    private func completeTutorialStep() {
        timerRunning = false
        Haptics.success()

        if !isReplay, let task = createdTask, let firstStep = task.microtasks.first {
            let result = appState.completeMicrotask(
                taskId: task.id,
                microtaskId: firstStep.id,
                outcome: .done,
                actualMinutes: max(1, (firstStepMinutes * 60 - secondsRemaining) / 60),
                allowChest: false  // keep the tutorial moment a clean +10
            )
            // Show the simple +10; achievements surface later so the moment stays clean.
            earnedXPLabel = 10
            streakLabel = result.streakAdvancedTo ?? appState.streakCount
        } else {
            earnedXPLabel = 10
            streakLabel = max(appState.streakCount, 1)
        }

        withAnimation(.fokusCelebration) {
            stepDone = true
            showConfetti = true
        }
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            withAnimation(.easeOut(duration: 0.3)) { showConfetti = false }
        }
    }

    // MARK: Beat 4½ — Your orb can level up its look

    private var cosmeticsBeat: some View {
        let previewKey = teaserCoreKey ?? appState.profile.selectedOrbCore
        return VStack(spacing: 24) {
            FocusOrb(
                state: .pulsing,
                level: appState.currentLevel,
                core: .named(previewKey),
                aura: .named(appState.profile.selectedOrbAura),
                activity: .busy,
                size: 110
            )
            .animation(.fokusSpring, value: previewKey)

            VStack(spacing: 8) {
                Text("Your orb can dress up.")
                    .font(.fokusRounded(.title2))
                    .foregroundStyle(Color.textPrimary)
                Text("New cores, auras, and trails unlock as you level up. No shop, no prices. Just keep showing up.")
                    .font(.body)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 12) {
                ForEach(Self.teaserCoreKeys, id: \.self) { key in
                    teaserChip(key)
                }
            }

            Text("Tap one to peek.")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)

            Button("I want that") { advance(to: .world) }
                .fokusPrimaryCapsule()
        }
    }

    private func teaserChip(_ key: String) -> some View {
        let core = OrbCoreStyle.named(key)
        let unlockLevel = CosmeticCatalog.item(slot: .orbCore, key: key)?.unlockLevel ?? 1
        let unlocked = appState.isUnlocked(slot: .orbCore, key: key)
        let selected = teaserCoreKey == key

        return Button {
            Haptics.light()
            withAnimation(.fokusSpring) { teaserCoreKey = selected ? nil : key }
        } label: {
            VStack(spacing: 8) {
                Circle()
                    .fill(
                        RadialGradient(
                            stops: [
                                .init(color: core.core, location: 0),
                                .init(color: core.mid, location: 0.55),
                                .init(color: core.rim, location: 1),
                            ],
                            center: UnitPoint(x: 0.5, y: 0.42),
                            startRadius: 0, endRadius: 30
                        )
                    )
                    .overlay(Circle().strokeBorder(core.rim.opacity(0.5), lineWidth: 1))
                    .shadow(color: core.mid.opacity(0.5), radius: 8)
                    .frame(width: 48, height: 48)

                Text(core.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Label(unlocked ? "Unlocked" : "Lv \(unlockLevel)", systemImage: unlocked ? "checkmark" : "lock.fill")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Color.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .fokusCard(fill: selected ? .surfaceRaised : .surface)
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous)
                    .stroke(selected ? Color.focus : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(core.name) core preview")
        .accessibilityValue(unlocked ? "Unlocked" : "Unlocks at level \(unlockLevel)")
    }

    // MARK: Beat 5 — Here's your world

    private var worldBeat: some View {
        VStack(spacing: 28) {
            FocusOrb(state: .dim, level: appState.currentLevel, activity: .busy, size: 100)

            StatBar(
                level: appState.currentLevel,
                xpProgress: appState.xpProgress,
                xp: appState.currentXP,
                streak: max(appState.streakCount, isReplay ? 1 : 0),
                flairKey: appState.profile.selectedAppAccent
            )

            VStack(spacing: 14) {
                let callout = Self.tourCallouts[tourStep]
                HStack(spacing: 10) {
                    Image(systemName: callout.symbol)
                        .font(.title3)
                        .foregroundStyle(Color.focus)
                    Text(callout.line)
                        .font(.body)
                        .foregroundStyle(Color.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .fokusCard()
                .id(tourStep)
                .transition(.opacity.combined(with: .move(edge: .trailing)))

                Text("\(tourStep + 1) of \(Self.tourCallouts.count)")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            if tourStep < Self.tourCallouts.count - 1 {
                Button("Next") {
                    withAnimation(.fokusSpring) { tourStep += 1 }
                }
                .fokusPrimaryCapsule()
            } else {
                Button("Enter FokusAI") { finish() }
                    .fokusPrimaryCapsule()
            }
        }
    }

    // MARK: Flow

    private func advance(to next: Beat) {
        withAnimation(.fokusSpring) { beat = next }
    }

    /// Skipping discards the canned tutorial task — unless the user already
    /// completed its first step, in which case it's real progress and stays.
    private func skip() {
        if !isReplay, !stepDone, let createdTask {
            appState.deleteTask(createdTask.id)
        }
        finish()
    }

    private func finish() {
        if !isReplay {
            appState.completeTutorial()
        }
        onFinish?()
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

#Preview {
    TutorialView(isReplay: true)
        .environment(AppState())
}
