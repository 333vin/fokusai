//
//  Task.swift
//  fokusai
//
//  Created by Navneet Sharma on 2026-07-16.
//

import Foundation

enum TaskStatus: String, Codable, Hashable {
    case active
    case done
    case abandoned
}

struct Task: Identifiable, Codable, Hashable {
    let id: UUID
    var userId: UUID?
    let title: String
    let taskType: String?
    let createdAt: Date
    var status: TaskStatus
    var microtasks: [Microtask]
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case taskType = "task_type"
        case createdAt = "created_at"
        case status
        case microtasks
    }
    
    init(
        id: UUID = UUID(),
        userId: UUID? = nil,
        title: String,
        taskType: String? = nil,
        createdAt: Date = Date(),
        status: TaskStatus = .active,
        microtasks: [Microtask] = []
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.taskType = taskType
        self.createdAt = createdAt
        self.status = status
        self.microtasks = microtasks
    }
    
    var completedMicrotasksCount: Int {
        microtasks.filter { $0.status == .done }.count
    }
    
    var progress: Double {
        guard !microtasks.isEmpty else { return 0 }
        return Double(completedMicrotasksCount) / Double(microtasks.count)
    }
    
    var isComplete: Bool {
        !microtasks.isEmpty && microtasks.allSatisfy { $0.status == .done }
    }
}
