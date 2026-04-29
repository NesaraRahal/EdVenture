//
//  LoginView.swift
//  EdVenture
//
//  Created by COBSCCOMP24.2p-053 on 2026-03-31.
//

import SwiftUI
import LocalAuthentication

// MARK: - LoginView
// Features/Auth/LoginView.swift

struct LoginView: View {

    @StateObject private var vm = AuthViewModel()

    @State private var email        = ""
    @State private var password     = ""
    @State private var showPassword = false
    @State private var appeared     = false

    @AppStorage("security.biometricsEnabled") private var biometricsEnabled = false
    @AppStorage("security.biometricEnrollmentCompleted") private var biometricEnrollmentCompleted = false

    // Navigation callbacks
    var onAuthenticated:   (() -> Void)?   // → Home
    var onCreateAccount:   (() -> Void)?   // → RegisterView
    var onForgotPassword:  (() -> Void)?   // → ForgotPasswordView

    private var canUseBiometricLogin: Bool {
        biometricsEnabled && biometricEnrollmentCompleted
    }

    private var biometryLabel: String {
        let context = LAContext()
        switch context.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        default: return "Biometrics"
        }
    }

    var body: some View {
        ZStack {
            Color.evBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── Logo ─────────────────────────────────────────
                    Text("EdVenture")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.evPrimary)
                        .padding(.top, 56)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.05), value: appeared)

                    // ── Hero ──────────────────────────────────────────
                    Image("EdVentureLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 130, height: 130)
                        .padding(.top, 20)
                        .scaleEffect(appeared ? 1 : 0.88)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.55, dampingFraction: 0.72).delay(0.1), value: appeared)

                    // ── Fields ────────────────────────────────────────
                    VStack(spacing: 14) {
                        EVTextField(
                            icon: "envelope",
                            placeholder: "Email Address",
                            text: $email,
                            keyboardType: .emailAddress
                        )
                        EVSecureField(
                            icon: "lock",
                            placeholder: "Password",
                            text: $password,
                            isVisible: $showPassword
                        )

                        // Forgot password — right aligned, 44pt touch target (HIG)
                        HStack {
                            Spacer()
                            Button("Forgot password?") { onForgotPassword?() }
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.evPrimary)
                                .frame(minHeight: 44)
                        }
                        .padding(.top, -6)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 36)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 18)
                    .animation(.easeOut(duration: 0.45).delay(0.2), value: appeared)

                    // ── Error ─────────────────────────────────────────
                    if let error = vm.errorMessage {
                        Text(error)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                            .padding(.top, 10)
                    }

                    // ── Sign In button ────────────────────────────────
                    EVPrimaryButton(
                        title: "Sign In",
                        isLoading: vm.isLoading
                    ) {
                        Task {
                            await vm.login(email: email, password: password)
                            if vm.isAuthenticated {
                                if canUseBiometricLogin {
                                    _ = EVCredentialStore.save(email: email, password: password)
                                }
                                onAuthenticated?()
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.3), value: appeared)

                    if canUseBiometricLogin {
                        Button {
                            Task {
                                let ok = await EVBiometricAuth.authorize(
                                    reason: "Sign in to EdVenture"
                                )

                                guard ok else {
                                    vm.errorMessage = "\(biometryLabel) verification failed."
                                    return
                                }

                                guard let credential = EVCredentialStore.load() else {
                                    vm.errorMessage = "No saved login found. Please sign in once with email and password."
                                    return
                                }

                                email = credential.email
                                password = credential.password

                                await vm.login(email: credential.email, password: credential.password)
                                if vm.isAuthenticated {
                                    onAuthenticated?()
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: biometryLabel == "Face ID" ? "faceid" : "touchid")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Sign In with \(biometryLabel)")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.14), lineWidth: 0.6)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                    }

                    // ── Divider ───────────────────────────────────────
                    EVDivider()
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                    // ── Social buttons ────────────────────────────────
                    VStack(spacing: 12) {
                        EVSocialButton(icon: "g.circle", title: "Sign In with Google", isGoogle: true) {
                            Task {
                                await vm.signInWithGoogle()
                                if vm.isAuthenticated {
                                    onAuthenticated?()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.38), value: appeared)

                    // ── Footer ────────────────────────────────────────
                    HStack(spacing: 4) {
                        Text("Dont have an Account?")
                            .foregroundColor(.evTextMuted)
                        Button("Create One") { onCreateAccount?() }
                            .foregroundColor(.evPrimary)
                    }
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.44), value: appeared)
                }
            }
        }
        .onAppear { appeared = true }
    }
}

#Preview {
    LoginView()
}
