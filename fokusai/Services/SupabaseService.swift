//
//  SupabaseService.swift
//  fokusai
//
//  Created by Navneet Sharma on 2026-07-16.
//

import Foundation
import Supabase
import Observation

@Observable
class SupabaseService {
    // MARK: - Singleton
    static let shared = SupabaseService()
    
    // MARK: - Properties
    private(set) var client: SupabaseClient
    private(set) var currentUser: User?
    private(set) var isAuthenticated = false
    
    // MARK: - Initialization
    private init() {
        // Initialize Supabase client
        guard SupabaseConfig.isConfigured else {
            fatalError("""
                ⚠️ Supabase is not configured!
                Please update SupabaseConfig.swift with your project credentials.
                See Config/SupabaseConfig.swift for instructions.
                """)
        }
        
        guard let url = URL(string: SupabaseConfig.supabaseURL) else {
            fatalError("Invalid Supabase URL in SupabaseConfig")
        }
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: SupabaseConfig.supabaseAnonKey
        )
        
        // Check for existing session
        Task {
            await checkSession()
        }
    }
    
    // MARK: - Auth Methods
    
    /// Check if there's an existing session
    func checkSession() async {
        do {
            let session = try await client.auth.session
            currentUser = session.user
            isAuthenticated = true
        } catch {
            currentUser = nil
            isAuthenticated = false
        }
    }
    
    /// Sign up with email and password
    func signUp(email: String, password: String) async throws {
        let response = try await client.auth.signUp(
            email: email,
            password: password
        )
        
        currentUser = response.user
        isAuthenticated = true
    }
    
    /// Sign in with email and password
    func signIn(email: String, password: String) async throws {
        let response = try await client.auth.signIn(
            email: email,
            password: password
        )
        
        currentUser = response.session.user
        isAuthenticated = true
    }
    
    /// Sign out
    func signOut() async throws {
        try await client.auth.signOut()
        currentUser = nil
        isAuthenticated = false
    }
    
    /// Reset password
    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }
    
    // MARK: - Helper
    
    var userId: UUID? {
        guard let id = currentUser?.id else { return nil }
        return UUID(uuidString: id.uuidString)
    }
}
