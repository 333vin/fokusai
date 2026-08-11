//
//  MockData.swift
//  fokusai
//
//  Created by Navneet Sharma on 2026-07-16.
//

import Foundation

enum MockData {
    static let sampleTasks: [TaskItem] = [
        TaskItem(
            title: "Write history essay on the Cold War",
            taskType: "essay",
            createdAt: Date().addingTimeInterval(-3600),
            status: .active,
            microtasks: [
                Microtask(orderIndex: 1, text: "Open a blank Google Doc and title it", estimatedMinutes: 2, status: .done, completedAt: Date().addingTimeInterval(-1800)),
                Microtask(orderIndex: 2, text: "Write just the thesis statement in your own words", estimatedMinutes: 5, status: .done, completedAt: Date().addingTimeInterval(-1500)),
                Microtask(orderIndex: 3, text: "List 3 events that support your thesis", estimatedMinutes: 3, status: .todo),
                Microtask(orderIndex: 4, text: "Write 2 sentences about the first event", estimatedMinutes: 4, status: .todo),
                Microtask(orderIndex: 5, text: "Find one quote from the textbook about that event", estimatedMinutes: 5, status: .todo)
            ]
        ),
        TaskItem(
            title: "Clean my room",
            taskType: "chore",
            createdAt: Date().addingTimeInterval(-7200),
            status: .active,
            microtasks: [
                Microtask(orderIndex: 1, text: "Pick up 5 things from the floor and put them away", estimatedMinutes: 2, status: .todo),
                Microtask(orderIndex: 2, text: "Make your bed. Just pull the blanket up", estimatedMinutes: 2, status: .todo),
                Microtask(orderIndex: 3, text: "Clear everything off your desk into one pile", estimatedMinutes: 3, status: .todo)
            ]
        ),
        TaskItem(
            title: "Study for biology quiz on cells",
            taskType: "test_study",
            createdAt: Date().addingTimeInterval(-86400),
            status: .done,
            microtasks: [
                Microtask(orderIndex: 1, text: "Read the first page of the chapter summary", estimatedMinutes: 3, status: .done, completedAt: Date().addingTimeInterval(-82800)),
                Microtask(orderIndex: 2, text: "Write down 3 vocab words you don't know", estimatedMinutes: 2, status: .done, completedAt: Date().addingTimeInterval(-82500)),
                Microtask(orderIndex: 3, text: "Look up those 3 words in the glossary", estimatedMinutes: 4, status: .done, completedAt: Date().addingTimeInterval(-82200))
            ]
        )
    ]
}
