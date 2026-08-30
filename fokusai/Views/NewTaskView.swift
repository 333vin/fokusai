    //
    //  NewTaskView.swift
    //  fokusai
    //
    //  One big question, optional details behind a disclosure, and the witty
    //  decomposition loading moment. Only the title is required — never gate
    //  behind a form.
    //

    import SwiftUI
    import PhotosUI

    struct NewTaskView: View {
        @Environment(AppState.self) private var appState
        @Environment(\.dismiss) private var dismiss

        /// Called with the created task so Home can cascade straight into it.
        var onCreated: ((TaskItem) -> Void)?

        @State private var taskTitle = ""
        @State private var showingDetails = false
        @State private var hasDeadline = false
        @State private var deadline = Date().addingTimeInterval(86400 * 3)
        @State private var taskFormat: TaskFormat = .other
        @State private var scope = ""
        @State private var notes = ""
        @State private var timeAvailable = 30
        @State private var photoItem: PhotosPickerItem?
        @State private var photoAttached = false

        @State private var isDecomposing = false
        @State private var titleError: String?
        @FocusState private var titleFocused: Bool

        enum TaskFormat: String, CaseIterable {
            case essay = "Essay"
            case problemSet = "Problem Set"
            case reading = "Reading"
            case test = "Test / Quiz"
            case project = "Project"
            case chore = "Chore"
            case other = "Other"
        }

        var body: some View {
            NavigationStack {
                ZStack {
                    AppBackground()

                    if isDecomposing {
                        decompositionLoading
                    } else {
                        form
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if !isDecomposing {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { dismiss() }
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                }
            }
            .interactiveDismissDisabled(isDecomposing)
        }

        // MARK: Form

        private var form: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("What are you putting off?")
                        .font(.fokusRounded(.title2))
                        .foregroundStyle(Color.textPrimary)
                        .padding(.top, 8)

                    TextField("The thing. Just name the thing.", text: $taskTitle, axis: .vertical)
                        .font(.body)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(2...5)
                        .padding(16)
                        .fokusCard()
                        .focused($titleFocused)
                        .onAppear { titleFocused = true }
                        .onChange(of: taskTitle) { _, _ in
                            if titleError != nil { titleError = nil }
                        }

                    if let titleError {
                        Text(titleError)
                            .font(.footnote)
                            .foregroundStyle(Color.reward)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityLabel(titleError)
                    }

                    detailsDisclosure
                        .onChange(of: showingDetails) { _, _ in
                            if titleError != nil && hasExtraContext { titleError = nil }
                        }
                        .onChange(of: scope) { _, _ in
                            if titleError != nil && hasExtraContext { titleError = nil }
                        }
                        .onChange(of: notes) { _, _ in
                            if titleError != nil && hasExtraContext { titleError = nil }
                        }
                        .onChange(of: photoAttached) { _, _ in
                            if titleError != nil && hasExtraContext { titleError = nil }
                        }
                        .onChange(of: taskFormat) { _, _ in
                            if titleError != nil && hasExtraContext { titleError = nil }
                        }
                        .onChange(of: hasDeadline) { _, _ in
                            if titleError != nil && hasExtraContext { titleError = nil }
                        }

                    Spacer(minLength: 80)
                }
                .padding(.horizontal, Layout.screenPadding)
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                startDecomposition()
            } label: {
                Label("Break it down", systemImage: "wand.and.stars")
                    .frame(maxWidth: .infinity)
                    .fokusPrimaryCapsule(disabled: trimmedTitle.isEmpty)
            }
            .buttonTip("Break it down", detail: "Sends your task to AI (or a local template offline) and turns it into tiny steps.")
            .disabled(trimmedTitle.isEmpty)
                .padding(.horizontal, Layout.screenPadding)
                .padding(.bottom, 12)
            }
        }

        private var trimmedTitle: String {
            taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        /// Any optional context that can rescue a cryptic title.
        private var hasExtraContext: Bool {
            hasDeadline
                || taskFormat != .other
                || !scope.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || photoAttached
        }

        /// Heuristic: keyboard smash / vowel-starved nonsense with nothing else to go on.
        private func looksLikeGibberish(_ title: String) -> Bool {
            let compact = title.lowercased().filter { !$0.isWhitespace }
            let letters = compact.filter(\.isLetter)
            guard letters.count >= 3 else {
                // Tiny non-words like "??" or "x" need detail to mean anything.
                return compact.count >= 2 && letters.count < 2
            }

            let smashTokens = ["asdf", "qwer", "zxcv", "hjkl", "qwerty", "asdfgh", "xxx", "aaaa", "bbbb"]
            if smashTokens.contains(where: { compact.contains($0) }) { return true }

            if Set(letters).count == 1 { return true }

            let vowels = letters.filter { "aeiouy".contains($0) }.count
            let vowelRatio = Double(vowels) / Double(letters.count)
            let letterRatio = Double(letters.count) / Double(max(compact.count, 1))

            // Mostly symbols/numbers.
            if letterRatio < 0.5 && compact.count >= 4 { return true }

            // Single mashed token with almost no vowels (e.g. "bcdfghk").
            let isSingleToken = !title.contains(where: \.isWhitespace)
            if isSingleToken && letters.count >= 4 && vowelRatio < 0.18 { return true }
            if isSingleToken && letters.count >= 6 && vowelRatio < 0.25 { return true }

            return false
        }

        private var detailsDisclosure: some View {
            VStack(alignment: .leading, spacing: 14) {
                Button {
                    withAnimation(.fokusSpring) { showingDetails.toggle() }
                } label: {
                    HStack(spacing: 6) {
                        Text("Add details")
                        Image(systemName: showingDetails ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                }
                .accessibilityHint("Optional context like deadline and scope")

                if showingDetails {
                    VStack(alignment: .leading, spacing: 18) {
                        Toggle("Has a deadline", isOn: $hasDeadline.animation(.fokusSpring))
                            .font(.subheadline)
                            .foregroundStyle(Color.textPrimary)
                            .tint(.brand)

                        if hasDeadline {
                            DatePicker("Due", selection: $deadline, displayedComponents: .date)
                                .font(.subheadline)
                                .foregroundStyle(Color.textPrimary)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Type")
                                .font(.subheadline)
                                .foregroundStyle(Color.textSecondary)
                            Picker("Type", selection: $taskFormat) {
                                ForEach(TaskFormat.allCases, id: \.self) { format in
                                    Text(format.rawValue).tag(format)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.brand)
                        }

                        labeledField("Scope (optional)", placeholder: "e.g. 5 pages, 10 problems", text: $scope)
                        labeledField("Notes or rubric (optional)", placeholder: "Paste anything useful…", text: $notes, multiline: true)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Time available now: \(timeAvailable) min")
                                .font(.subheadline)
                                .foregroundStyle(Color.textSecondary)
                            Slider(
                                value: Binding(
                                    get: { Double(timeAvailable) },
                                    set: { timeAvailable = Int($0) }
                                ),
                                in: 5...120, step: 5
                            )
                            .tint(.brand)
                        }

                        PhotosPicker(selection: $photoItem, matching: .images) {
                            HStack(spacing: 8) {
                                Image(systemName: photoAttached ? "checkmark.circle.fill" : "photo")
                                Text(photoAttached ? "Assignment photo attached" : "Attach a photo of the assignment")
                            }
                            .font(.subheadline)
                            .foregroundStyle(photoAttached ? Color.success : Color.brand)
                        }
                        .onChange(of: photoItem) { _, newValue in
                            photoAttached = newValue != nil
                        }
                    }
                    .padding(16)
                    .fokusCard()
                }
            }
        }

        private func labeledField(_ label: String, placeholder: String, text: Binding<String>, multiline: Bool = false) -> some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                TextField(placeholder, text: text, axis: multiline ? .vertical : .horizontal)
                    .font(.body)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(multiline ? 2...5 : 1...1)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: Layout.buttonRadius)
                            .fill(Color.surfaceRaised)
                    )
            }
        }

        // MARK: Loading

        private var decompositionLoading: some View {
            VStack(spacing: 28) {
                Spacer()
            FocusOrb(
                state: .pulsing,
                level: appState.currentLevel,
                core: .named(appState.profile.selectedOrbCore),
                aura: .named(appState.profile.selectedOrbAura),
                activity: .thinking,
                size: 130
            )
                RotatingCopyLine(lines: Copy.all(.decompositionLoading).shuffled(), interval: 1.2)
                    .padding(.horizontal, 40)
                Spacer()
                Spacer()
            }
            .transition(.opacity)
            .accessibilityLabel("Breaking your task into tiny steps")
        }

        private func startDecomposition() {
            titleFocused = false

            // Gibberish title + no details → ask for something we can work with.
            if looksLikeGibberish(trimmedTitle) && !hasExtraContext {
                withAnimation(.fokusSpring) {
                    titleError = "That name looks like keyboard spaghetti. Give it a real label, or add a detail so we know what you mean."
                }
                Haptics.light()
                return
            }

            titleError = nil
            withAnimation(.fokusSpring) { isDecomposing = true }
            Haptics.light()

            Task {
                // Mock "thinking" beat so the moment lands (and the copy gets read).
                try? await Task.sleep(for: .seconds(2.4))

                let microtasks = await DecompositionService.decompose(
                    title: trimmedTitle,
                    format: taskFormat == .other ? nil : taskFormat.rawValue,
                    timeAvailableMinutes: timeAvailable,
                    multiplier: appState.profile.estimateMultiplier
                )
                let task = TaskItem(
                    title: trimmedTitle,
                    taskType: taskFormat.rawValue.lowercased(),
                    microtasks: microtasks
                )
                appState.addTask(task)
                dismiss()
                onCreated?(task)
            }
        }
    }

    #Preview {
        NewTaskView()
            .environment(AppState())
    }
