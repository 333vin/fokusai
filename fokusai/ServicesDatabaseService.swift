//
//  DatabaseService.swift
//  fokusai
//
//  Created by Navneet Sharma on 2026-07-16.
//

import Foundation
import Supabase

/// Handles all database CRUD operations for FokusAI
class DatabaseService {
    private let client: SupabaseClient
    
    init(client: SupabaseClient) {
        self.client = client
    }
    
    // MARK: - Profile Operations
    
    func fetchProfile(userId: UUID) async throws -> Profile {
        let response: Profile = try await client.database
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value
        
        return response
    }
    
    func updateProfile(_ profile: Profile) async throws {
        try await client.database
            .from("profiles")
            .update(profile)
            .eq("id", value: profile.id)
            .execute()
    }
    
    func createProfile(userId: UUID, procrastinationType: String?) async throws {
        let profile = Profile(
            id: userId,
            procrastinationType: procrastinationType
        )
        
        try await client.database
            .from("profiles")
            .insert(profile)
            .execute()
    }
    
    // MARK: - Task Operations
    
    func fetchTasks(userId: UUID, status: TaskStatus? = nil) async throws -> [Task] {
        var query = client.database
            .from("tasks")
            .select("*, microtasks(*)")
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
        
        if let status = status {
            query = query.eq("status", value: status.rawValue)
        }
        
        let response: [Task] = try await query.execute().value
        return response
    }
    
    func createTask(_ task: Task, microtasks: [Microtask]) async throws -> Task {
        // Insert task
        let insertedTask: Task = try await client.database
            .from("tasks")
            .insert(task)
            .select()
            .single()
            .execute()
            .value
        
        // Insert microtasks
        if !microtasks.isEmpty {
            try await client.database
                .from("microtasks")
                .insert(microtasks)
                .execute()
        }
        
        return insertedTask
    }
    
    func updateTask(_ task: Task) async throws {
        try await client.database
            .from("tasks")
            .update(task)
            .eq("id", value: task.id)
            .execute()
    }
    
    func deleteTask(id: UUID) async throws {
        try await client.database
            .from("tasks")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - Microtask Operations
    
    func updateMicrotask(_ microtask: Microtask) async throws {
        try await client.database
            .from("microtasks")
            .update(microtask)
            .eq("id", value: microtask.id)
            .execute()
    }
    
    func completeMicrotask(id: UUID, actualMinutes: Int) async throws {
        try await client.database
            .from("microtasks")
            .update([
                "status": "done",
                "actual_minutes": actualMinutes,
                "completed_at": Date()
            ])
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - Feedback Operations
    
    func submitFeedback(microtaskId: UUID, userId: UUID, sizeRating: String) async throws {
        let feedback: [String: Any] = [
            "microtask_id": microtaskId,
            "user_id": userId,
            "size_rating": sizeRating
        ]
        
        try await client.database
            .from("feedback")
            .insert(feedback)
            .execute()
    }
    
    func fetchRecentFeedback(userId: UUID, limit: Int = 10) async throws -> [String] {
        struct FeedbackRow: Codable {
            let sizeRating: String?
        }
        
        let response: [FeedbackRow] = try await client.database
            .from("feedback")
            .select("size_rating")
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        
        return response.compactMap { $0.sizeRating }
    }
    
    // MARK: - Upgrade Operations
    
    func fetchAvailableUpgrades() async throws -> [Upgrade] {
        let response: [Upgrade] = try await client.database
            .from("upgrades")
            .select()
            .order("unlock_level", ascending: true)
            .execute()
            .value
        
        return response
    }
    
    func fetchUserUpgrades(userId: UUID) async throws -> [UserUpgrade] {
        let response: [UserUpgrade] = try await client.database
            .from("user_upgrades")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
        
        return response
    }
    
    func unlockUpgrade(userId: UUID, upgradeId: UUID) async throws {
        let userUpgrade: [String: Any] = [
            "user_id": userId,
            "upgrade_id": upgradeId
        ]
        
        try await client.database
            .from("user_upgrades")
            .insert(userUpgrade)
            .execute()
    }
}

// MARK: - Supporting Types

struct Profile: Codable {
    let id: UUID
    var createdAt: Date?
    var estimateMultiplier: Double
    var xp: Int
    var level: Int
    var streakCount: Int
    var longestStreak: Int
    var lastActiveDate: Date?
    var freezesAvailable: Int
    var procrastinationType: String?
    var selectedTheme: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case estimateMultiplier = "estimate_multiplier"
        case xp, level
        case streakCount = "streak_count"
        case longestStreak = "longest_streak"
        case lastActiveDate = "last_active_date"
        case freezesAvailable = "freezes_available"
        case procrastinationType = "procrastination_type"
        case selectedTheme = "selected_theme"
    }
    
    init(
        id: UUID,
        createdAt: Date? = nil,
        estimateMultiplier: Double = 1.0,
        xp: Int = 0,
        level: Int = 1,
        streakCount: Int = 0,
        longestStreak: Int = 0,
        lastActiveDate: Date? = nil,
        freezesAvailable: Int = 2,
        procrastinationType: String? = nil,
        selectedTheme: String = "deep_focus"
    ) {
        self.id = id
        self.createdAt = createdAt
        self.estimateMultiplier = estimateMultiplier
        self.xp = xp
        self.level = level
        self.streakCount = streakCount
        self.longestStreak = longestStreak
        self.lastActiveDate = lastActiveDate
        self.freezesAvailable = freezesAvailable
        self.procrastinationType = procrastinationType
        self.selectedTheme = selectedTheme
    }
}

struct Upgrade: Codable, Identifiable {
    let id: UUID
    let key: String
    let name: String
    let category: String
    let unlockLevel: Int
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case id, key, name, category, description
        case unlockLevel = "unlock_level"
    }
}

struct UserUpgrade: Codable {
    let userId: UUID
    let upgradeId: UUID
    let unlockedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case upgradeId = "upgrade_id"
        case unlockedAt = "unlocked_at"
    }
}
