//
//  SupabaseService.swift
//  fokusai
//
//  MOCK IMPLEMENTATION for the v2 frontend rework.
//  The real Supabase wiring (using Config/SupabaseConfig.swift) is a later
//  project. This mock preserves the API surface so it can be swapped back in
//  without touching the views. No network, no secrets, no packages.
//

import Foundation
import Observation

@Observable
class SupabaseService {
    // MARK: - Singleton
    static let shared = SupabaseService()

    // MARK: - Properties
    private(set) var isAuthenticated = false
    private(set) var isGuest = false
    private(set) var userId: UUID?

    private static let userIdKey = "fokusai.mock.userId"
    private static let isGuestKey = "fokusai.mock.isGuest"
    /// Stable guest identity so mock data / profile persist across launches.
    private static let guestUserId = UUID(uuidString: "00000000-0000-4000-8000-000000000001")!

    // MARK: - Initialization
    private init() {
        if let stored = UserDefaults.standard.string(forKey: Self.userIdKey),
           let id = UUID(uuidString: stored) {
            userId = id
            isAuthenticated = true
            isGuest = UserDefaults.standard.bool(forKey: Self.isGuestKey)
        } else {
            // No session yet — start as guest so features work without sign-in.
            continueAsGuest()
        }
    }

    // MARK: - Auth Methods (mock)

    /// Restores a previous mock session, if any (already handled in init).
    func checkSession() async {}

    /// Local guest session — no email/password, no backend.
    func continueAsGuest() {
        UserDefaults.standard.set(Self.guestUserId.uuidString, forKey: Self.userIdKey)
        UserDefaults.standard.set(true, forKey: Self.isGuestKey)
        userId = Self.guestUserId
        isGuest = true
        isAuthenticated = true
    }

    /// Mock sign up: always succeeds locally.
    func signUp(email: String, password: String) async throws {
        signInLocally()
    }

    /// Mock sign in: always succeeds locally.
    func signIn(email: String, password: String) async throws {
        signInLocally()
    }

    /// Mock sign out: clears the local session, then returns to guest.
    func signOut() async throws {
        UserDefaults.standard.removeObject(forKey: Self.userIdKey)
        UserDefaults.standard.removeObject(forKey: Self.isGuestKey)
        userId = nil
        isGuest = false
        isAuthenticated = false
        continueAsGuest()
    }

    /// Mock password reset: no-op.
    func resetPassword(email: String) async throws {}

    // MARK: - Private

    private func signInLocally() {
        let id = UUID()
        UserDefaults.standard.set(id.uuidString, forKey: Self.userIdKey)
        UserDefaults.standard.set(false, forKey: Self.isGuestKey)
        userId = id
        isGuest = false
        isAuthenticated = true
    }
}
