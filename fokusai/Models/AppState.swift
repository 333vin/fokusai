//
//  AppState.swift
//  fokusai
//
//  Created by Navneet Sharma on 2026-07-16.
//

import Foundation
import Observation

@Observable
class AppState {
    // MARK: - Properties
    var tasks: [Task] = []
    var profile: Profile?
    var isLoading = false
    var errorMessage: String?
    
    private let supabase = SupabaseService.shared
    private var database: DatabaseService {
        DatabaseService(client: supabase.client)
    }
    
    // MARK: - Computed Properties
    var currentXP: Int {
        profile?.xp ?? 0
    }
    
    var currentLevel: Int {
        profile?.level ?? 1
    }
    
    var streakCount: Int {
        profile?.streakCount ?? 0
    }
    
    var xpForNextLevel: Int {
        50 * currentLevel * (currentLevel + 1) / 2
    }
    
    var xpProgress: Double {
        let previousLevelXP = currentLevel > 1 ? 50 * (currentLevel - 1) * currentLevel / 2 : 0
        let xpIntoCurrentLevel = currentXP - previousLevelXP
        let xpNeededForLevel = xpForNextLevel - previousLevelXP
        return Double(xpIntoCurrentLevel) / Double(xpNeededForLevel)
    }
    
    // MARK: - Initialization
    init() {
        // Load data if authenticated
        Task {
            await loadData()
        }
    }
    
    // MARK: - Data Loading
    func loadData() async {
        guard let userId = supabase.userId else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Load profile
            profile = try await database.fetchProfile(userId: userId)
            
            // Load tasks
            tasks = try await database.fetchTasks(userId: userId)
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Task Operations
    func addTask(_ task: Task) async throws {
        guard let userId = supabase.userId else { return }
        
        var newTask = task
        newTask.userId = userId
        
        // Separate microtasks
        let microtasks = task.microtasks.map { microtask in
            var mt = microtask
            mt.taskId = newTask.id
            return mt
        }
        
        // Create in database
        let createdTask = try await database.createTask(newTask, microtasks: microtasks)
        
        // Update local state
        await MainActor.run {
            tasks.insert(createdTask, at: 0)
        }
    }
    
    func updateTask(_ task: Task) async throws {
        try await database.updateTask(task)
        
        // Update local state
        await MainActor.run {
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index] = task
            }
        }
    }
    
    func completeTask(_ taskId: UUID) async throws {
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else { return }
        
        var task = tasks[index]
        task.status = .done
        
        try await database.updateTask(task)
        
        // Update local state
        await MainActor.run {
            tasks[index].status = .done
        }
    }
    
    func deleteTask(_ taskId: UUID) async throws {
        try await database.deleteTask(id: taskId)
        
        // Update local state
        await MainActor.run {
            tasks.removeAll { $0.id == taskId }
        }
    }
    
    // MARK: - Microtask Operations
    func completeMicrotask(taskId: UUID, microtaskId: UUID, actualMinutes: Int) async throws {
        // Update in database
        try await database.completeMicrotask(id: microtaskId, actualMinutes: actualMinutes)
        
        // Award XP
        await awardXP(10)
        
        // Update local state
        await MainActor.run {
            if let taskIndex = tasks.firstIndex(where: { $0.id == taskId }),
               let microtaskIndex = tasks[taskIndex].microtasks.firstIndex(where: { $0.id == microtaskId }) {
                tasks[taskIndex].microtasks[microtaskIndex].status = .done
                tasks[taskIndex].microtasks[microtaskIndex].completedAt = Date()
                tasks[taskIndex].microtasks[microtaskIndex].actualMinutes = actualMinutes
                
                // Check if task is complete
                if tasks[taskIndex].isComplete {
                    tasks[taskIndex].status = .done
                    Task {
                        await awardXP(25) // Bonus for completing whole task
                    }
                }
            }
        }
    }
    
    // MARK: - Gamification
    private func awardXP(_ amount: Int) async {
        guard var profile = profile else { return }
        
        profile.xp += amount
        
        // Check for level up
        let newLevel = calculateLevel(xp: profile.xp)
        if newLevel > profile.level {
            profile.level = newLevel
            // TODO: Show level-up celebration
        }
        
        // Update in database
        do {
            try await database.updateProfile(profile)
            
            await MainActor.run {
                self.profile = profile
            }
        } catch {
            print("Failed to update profile: \(error)")
        }
    }
    
    private func calculateLevel(xp: Int) -> Int {
        var level = 1
        while xp >= 50 * level * (level + 1) / 2 {
            level += 1
        }
        return level
    }
    
    // MARK: - Profile Operations
    func updateProfile(_ updatedProfile: Profile) async throws {
        try await database.updateProfile(updatedProfile)
        
        await MainActor.run {
            self.profile = updatedProfile
        }
    }
}
