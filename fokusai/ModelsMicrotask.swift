//
//  Microtask.swift
//  fokusai
//
//  Created by Navneet Sharma on 2026-07-16.
//

import Foundation

enum MicrotaskStatus: String, Codable, Hashable {
    case todo
    case done
    case skipped
}

struct Microtask: Identifiable, Codable, Hashable {
    let id: UUID
    var taskId: UUID?
    let orderIndex: Int
    let text: String
    let estimatedMinutes: Int
    var actualMinutes: Int?
    var status: MicrotaskStatus
    var completedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case taskId = "task_id"
        case orderIndex = "order_index"
        case text
        case estimatedMinutes = "estimated_minutes"
        case actualMinutes = "actual_minutes"
        case status
        case completedAt = "completed_at"
    }
    
    init(
        id: UUID = UUID(),
        taskId: UUID? = nil,
        orderIndex: Int,
        text: String,
        estimatedMinutes: Int,
        actualMinutes: Int? = nil,
        status: MicrotaskStatus = .todo,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.taskId = taskId
        self.orderIndex = orderIndex
        self.text = text
        self.estimatedMinutes = estimatedMinutes
        self.actualMinutes = actualMinutes
        self.status = status
        self.completedAt = completedAt
    }
}
