//
//  LoginView.swift
//  EdVenture
//
//  Created by COBSCCOMP24.2p-053 on 2026-03-31.
//

import SwiftUI

// MARK: - LoginView
// Features/Auth/LoginView.swift

struct LoginView: View {

    @StateObject private var vm = AuthViewModel()

    @State private var email        = ""
    @State private var password     = ""
    @State private var showPassword = false
    @State private var appeared     = false

    // Navigation callbacks
    var onAuthenticated:   (() -> Void)?   // → Home
    var onCreateAccount:   (() -> Void)?   // → RegisterView
    var onForgotPassword:  (() -> Void)?   // → ForgotPasswordView

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
                            if vm.isAuthenticated { onAuthenticated?() }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.3), value: appeared)

                    // ── Divider ───────────────────────────────────────
                    EVDivider()
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                    // ── Social buttons ────────────────────────────────
                    VStack(spacing: 12) {
                        EVSocialButton(icon: "applelogo", title: "Sign In with Apple") {}
                        EVSocialButton(icon: "g.circle", title: "Sign In with Google", isGoogle: true) {}
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
