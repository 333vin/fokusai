//
//  AuthView.swift
//  fokusai
//
//  Created by Navneet Sharma on 2026-07-16.
//

import SwiftUI

struct AuthView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingResetPassword = false
    
    let onAuthSuccess: () -> Void
    
    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 60)
                    
                    // Branding
                    VStack(spacing: 16) {
                        FocusOrb(state: .dim, level: 1)
                            .frame(height: 120)
                        
                        BrandLogo(size: .large)
                        
                        Text(isSignUp ? "Create your account" : "Welcome back")
                            .font(.title3)
                            .foregroundStyle(Color.textSecondary)
                    }
                    .padding(.bottom, 32)
                    
                    // Form
                    VStack(spacing: 16) {
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundStyle(Color.textSecondary)
                            
                            TextField("your@email.com", text: $email)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .font(.body)
                                .foregroundStyle(Color.textPrimary)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: Layout.cardRadius)
                                        .fill(Color.surface)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: Layout.cardRadius)
                                                .stroke(Color.stroke, lineWidth: 1)
                                        )
                                )
                        }
                        
                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .foregroundStyle(Color.textSecondary)
                            
                            SecureField("••••••••", text: $password)
                                .textContentType(isSignUp ? .newPassword : .password)
                                .font(.body)
                                .foregroundStyle(Color.textPrimary)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: Layout.cardRadius)
                                        .fill(Color.surface)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: Layout.cardRadius)
                                                .stroke(Color.stroke, lineWidth: 1)
                                        )
                                )
                        }
                        
                        // Error message
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(Color.red)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // Primary action button
                        Button {
                            handleAuth()
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(Color.bg)
                                } else {
                                    Text(isSignUp ? "Create Account" : "Sign In")
                                        .fontWeight(.semibold)
                                }
                            }
                            .font(.body)
                            .foregroundStyle(Color.bg)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .fill(isFormValid ? Color.accent : Color.textSecondary)
                            )
                        }
                        .disabled(!isFormValid || isLoading)
                        .padding(.top, 8)
                        
                        // Toggle sign up / sign in
                        Button {
                            withAnimation(.fokusSpring) {
                                isSignUp.toggle()
                                errorMessage = nil
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                    .foregroundStyle(Color.textSecondary)
                                Text(isSignUp ? "Sign In" : "Sign Up")
                                    .foregroundStyle(Color.brand)
                            }
                            .font(.subheadline)
                        }
                        .padding(.top, 8)
                        
                        // Forgot password (only on sign in)
                        if !isSignUp {
                            Button {
                                showingResetPassword = true
                            } label: {
                                Text("Forgot password?")
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, Layout.screenPadding)
                    
                    Spacer(minLength: 60)
                }
            }
        }
        .alert("Reset Password", isPresented: $showingResetPassword) {
            TextField("Email", text: $email)
            Button("Cancel", role: .cancel) { }
            Button("Send Reset Link") {
                handleResetPassword()
            }
        } message: {
            Text("Enter your email to receive a password reset link.")
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && password.count >= 6
    }
    
    private func handleAuth() {
        errorMessage = nil
        isLoading = true
        
        Task {
            do {
                if isSignUp {
                    try await SupabaseService.shared.signUp(email: email, password: password)
                } else {
                    try await SupabaseService.shared.signIn(email: email, password: password)
                }
                
                await MainActor.run {
                    isLoading = false
                    onAuthSuccess()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func handleResetPassword() {
        guard !email.isEmpty else { return }
        
        Task {
            do {
                try await SupabaseService.shared.resetPassword(email: email)
                await MainActor.run {
                    errorMessage = "Check your email for a reset link"
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    AuthView(onAuthSuccess: {})
}
