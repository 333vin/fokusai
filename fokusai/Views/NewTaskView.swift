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

                detailsDisclosure

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
            .disabled(trimmedTitle.isEmpty)
            .padding(.horizontal, Layout.screenPadding)
            .padding(.bottom, 12)
        }
    }

    private var trimmedTitle: String {
        taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
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
                skin: .named(appState.profile.selectedSkin),
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
        withAnimation(.fokusSpring) { isDecomposing = true }
        Haptics.light()

        Task {
            // Mock "thinking" beat so the moment lands (and the copy gets read).
            try? await Task.sleep(for: .seconds(2.4))

            let microtasks = DecompositionService.decompose(
                title: trimmedTitle,
                format: taskFormat == .other ? nil : taskFormat.rawValue,
                timeAvailableMinutes: timeAvailable
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
