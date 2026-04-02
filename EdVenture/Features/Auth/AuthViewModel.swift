//
//  AuthViewModel.swift
//  EdVenture
//
//  Created by COBSCCOMP24.2p-053 on 2026-03-31.
//

import SwiftUI
import FirebaseAuth
import Combine

// MARK: - AuthViewModel
// Shared across all Auth screens.
// Feature-based: lives in Features/Auth/

@MainActor
final class AuthViewModel: ObservableObject {

    // MARK: - Published state
    @Published var isLoading        = false
    @Published var errorMessage: String?
    @Published var isAuthenticated  = false
    @Published var otpSent          = false
    @Published var resetEmailSent   = false

    // MARK: - Register
    func register(username: String,
                  email: String,
                  password: String,
                  confirmPassword: String) async {

        errorMessage = nil

        guard !username.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Username is required."; return
        }
        guard email.contains("@") else {
            errorMessage = "Enter a valid email address."; return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."; return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."; return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            // Update display name
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = username
            try await changeRequest.commitChanges()
            // Send email verification (acts as OTP flow)
            try await result.user.sendEmailVerification()
            otpSent = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Login
    func login(email: String, password: String) async {
        errorMessage = nil

        guard email.contains("@") else {
            errorMessage = "Enter a valid email address."; return
        }
        guard !password.isEmpty else {
            errorMessage = "Password is required."; return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Forgot Password
    func sendPasswordReset(email: String) async {
        errorMessage = nil

        guard email.contains("@") else {
            errorMessage = "Enter a valid email address."; return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            resetEmailSent = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Verify OTP (email verification check)
    func verifyOTP() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await Auth.auth().currentUser?.reload()
            if Auth.auth().currentUser?.isEmailVerified == true {
                isAuthenticated = true
            } else {
                errorMessage = "Email not verified yet. Please check your inbox."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Resend verification email
    func resendVerificationEmail() async {
        errorMessage = nil
        do {
            try await Auth.auth().currentUser?.sendEmailVerification()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Sign out
    func signOut() {
        try? Auth.auth().signOut()
        isAuthenticated = false
    }
}
