//
//  DatabaseService.swift
//  fokusai
//
//  MOCK IMPLEMENTATION for the v2 frontend rework.
//  Backs the app with an in-memory store seeded from MockData, preserving the
//  API surface of the planned Supabase-backed service (profiles, tasks,
//  microtasks, feedback, upgrades, user_upgrades) so real wiring can swap in
//  later without touching the views.
//

import Foundation

/// Handles all data CRUD operations for FokusAI (in-memory mock).
class DatabaseService {
    // Shared in-memory store so every instance sees the same session data.
    // Starts empty: fresh users begin with a clean slate; MockData remains the
    // seed for previews and the DEBUG "load sample tasks" convenience.
    private static var profiles: [UUID: Profile] = [:]
    private static var tasks: [TaskItem] = []
    private static var userUpgrades: [UserUpgrade] = []

    init() {}

    // MARK: - Profile Operations

    func fetchProfile(userId: UUID) async throws -> Profile {
        if let profile = Self.profiles[userId] {
            return profile
        }
        let profile = Profile(id: userId, createdAt: Date())
        Self.profiles[userId] = profile
        return profile
    }

    func updateProfile(_ profile: Profile) async throws {
        Self.profiles[profile.id] = profile
    }

    func createProfile(userId: UUID, procrastinationType: String?) async throws {
        Self.profiles[userId] = Profile(
            id: userId,
            createdAt: Date(),
            procrastinationType: procrastinationType
        )
    }

    // MARK: - Task Operations

    func fetchTasks(userId: UUID, status: TaskStatus? = nil) async throws -> [TaskItem] {
        var result = Self.tasks
        if let status {
            result = result.filter { $0.status == status }
        }
        return result.sorted { $0.createdAt > $1.createdAt }
    }

    func createTask(_ task: TaskItem, microtasks: [Microtask]) async throws -> TaskItem {
        var newTask = task
        newTask.microtasks = microtasks
        Self.tasks.insert(newTask, at: 0)
        return newTask
    }

    func updateTask(_ task: TaskItem) async throws {
        if let index = Self.tasks.firstIndex(where: { $0.id == task.id }) {
            Self.tasks[index] = task
        }
    }

    func deleteTask(id: UUID) async throws {
        Self.tasks.removeAll { $0.id == id }
    }

    // MARK: - Microtask Operations

    func updateMicrotask(_ microtask: Microtask) async throws {
        for taskIndex in Self.tasks.indices {
            if let mtIndex = Self.tasks[taskIndex].microtasks.firstIndex(where: { $0.id == microtask.id }) {
                Self.tasks[taskIndex].microtasks[mtIndex] = microtask
                return
            }
        }
    }

    func completeMicrotask(id: UUID, actualMinutes: Int) async throws {
        for taskIndex in Self.tasks.indices {
            if let mtIndex = Self.tasks[taskIndex].microtasks.firstIndex(where: { $0.id == id }) {
                Self.tasks[taskIndex].microtasks[mtIndex].status = .done
                Self.tasks[taskIndex].microtasks[mtIndex].actualMinutes = actualMinutes
                Self.tasks[taskIndex].microtasks[mtIndex].completedAt = Date()
                return
            }
        }
    }

    // MARK: - Feedback Operations (mock no-ops)

    func submitFeedback(microtaskId: UUID, userId: UUID, sizeRating: String) async throws {}

    func fetchRecentFeedback(userId: UUID, limit: Int = 10) async throws -> [String] {
        []
    }

    // MARK: - Upgrade Operations

    func fetchAvailableUpgrades() async throws -> [Upgrade] {
        []
    }

    func fetchUserUpgrades(userId: UUID) async throws -> [UserUpgrade] {
        Self.userUpgrades.filter { $0.userId == userId }
    }

    func unlockUpgrade(userId: UUID, upgradeId: UUID) async throws {
        Self.userUpgrades.append(
            UserUpgrade(userId: userId, upgradeId: upgradeId, unlockedAt: Date())
        )
    }
}
