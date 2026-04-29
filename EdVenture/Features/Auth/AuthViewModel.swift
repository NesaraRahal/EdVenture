//
//  AuthViewModel.swift
//  EdVenture
//
//  Created by COBSCCOMP24.2p-053 on 2026-03-31.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore
import Combine
import GoogleSignIn

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

    private let db = Firestore.firestore()

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

            // Create initial profile document so profile/edit screens have real data.
            try await db.collection("users").document(result.user.uid).setData([
                "fullName": username,
                "username": username,
                "email": email,
                "phone": "",
                "bio": "",
                "interests": ["General Knowledge"],
                "dailyGoalMinutes": 10,
                "dailyProgressSeconds": 0,
                "onboardingPreferencesCompleted": false,
                "profileImagePath": "",
                "profileImageURL": "",
                "profileImageBase64": "",
                "telemetryConsentPending": true,
                "isEmailVerified": result.user.isEmailVerified,
                "createdAt": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date())
            ], merge: true)

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
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            try await ensureUserProfileDefaults(for: result.user)
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Google Sign In
    func signInWithGoogle() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                errorMessage = "Firebase client ID not configured."
                return
            }

            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config

            // Get the root view controller
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                errorMessage = "Unable to get view controller for sign in."
                return
            }

            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            let user = result.user

            guard let idToken = user.idToken?.tokenString else {
                errorMessage = "Failed to retrieve ID token from Google."
                return
            }

            let accessToken = user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

            let authResult = try await Auth.auth().signIn(with: credential)
            try await ensureUserProfileDefaults(for: authResult.user)
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
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
            if let user = Auth.auth().currentUser, user.isEmailVerified {
                try await ensureUserProfileDefaults(for: user)
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

    private func ensureUserProfileDefaults(for user: FirebaseAuth.User) async throws {
        let docRef = db.collection("users").document(user.uid)
        let snapshot = try await docRef.getDocument()

        let email = user.email ?? ""
        let trimmedDisplayName = user.displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let username = trimmedDisplayName.isEmpty
            ? (email.components(separatedBy: "@").first ?? "Learner")
            : trimmedDisplayName

        if let data = snapshot.data() {
            var updates: [String: Any] = [:]

            if data["dailyGoalMinutes"] == nil {
                updates["dailyGoalMinutes"] = 10
            }
            if data["dailyProgressSeconds"] == nil {
                updates["dailyProgressSeconds"] = 0
            }
            if data["dailyProgressDate"] == nil {
                updates["dailyProgressDate"] = dayKey(Date())
            }
            if data["dailyGoalCompleted"] == nil {
                updates["dailyGoalCompleted"] = false
            }
            if data["onboardingPreferencesCompleted"] == nil {
                updates["onboardingPreferencesCompleted"] = false
            }
            if data["isEmailVerified"] == nil || (data["isEmailVerified"] as? Bool) != user.isEmailVerified {
                updates["isEmailVerified"] = user.isEmailVerified
            }

            if !updates.isEmpty {
                updates["updatedAt"] = Timestamp(date: Date())
                try await docRef.setData(updates, merge: true)
            }
            return
        }

        try await docRef.setData([
            "fullName": username,
            "username": username,
            "email": email,
            "phone": "",
            "bio": "",
            "interests": ["General Knowledge"],
            "dailyGoalMinutes": 10,
            "dailyProgressSeconds": 0,
            "dailyProgressDate": dayKey(Date()),
            "dailyGoalCompleted": false,
            "onboardingPreferencesCompleted": false,
            "profileImagePath": "",
            "profileImageURL": "",
            "profileImageBase64": "",
            "telemetryConsentPending": true,
            "isEmailVerified": user.isEmailVerified,
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date())
        ], merge: true)
    }

    private func dayKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
