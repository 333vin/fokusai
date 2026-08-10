//
//  SupabaseConfig.swift
//  fokusai
//
//  Created by Navneet Sharma on 2026-07-16.
//

import Foundation

enum SupabaseConfig {
    // MARK: - Configuration
    // ⚠️ IMPORTANT: Replace these with your actual Supabase project values
    // Find them at: https://app.supabase.com/project/YOUR_PROJECT/settings/api
    
    static let supabaseURL = "https://ncuqomxqmvfuufwdntwn.supabase.co"
    static let supabaseAnonKey = "sb_publishable_d3TMQTNU8VnRUGV5iYGHhw_JaEPuYvY"
    
    // MARK: - Validation
    static var isConfigured: Bool {
        !supabaseURL.contains("ncuqomxqmvfuufwdntwn") &&
        !supabaseAnonKey.contains("sb_publishable_d3TMQTNU8VnRUGV5iYGHhw_JaEPuYvY")
    }
}

// MARK: - Setup Instructions
/*
 HOW TO CONFIGURE SUPABASE:
 
 1. Create a Supabase project at https://app.supabase.com
 
 2. Get your credentials:
    - Go to Project Settings → API
    - Copy the "Project URL" → Replace supabaseURL above
    - Copy the "anon/public" key → Replace supabaseAnonKey above
    
 3. NEVER commit the secret/service_role key to source control!
    - The anon key is safe because Row Level Security (RLS) protects your data
    - Secret keys should ONLY live in Edge Functions or backend services
 
 4. Set up the database schema (see DATABASE_SCHEMA.sql)
 
 5. Enable Row Level Security on all tables (see RLS_POLICIES.sql)
 */
