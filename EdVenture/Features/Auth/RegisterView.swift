//
//  RegisterView.swift
//  EdVenture
//
//  Created by COBSCCOMP24.2p-053 on 2026-03-31.
//

//
//  RegisterView.swift
//  EdVenture
//
//  Features/Auth/RegisterView.swift

import SwiftUI

struct RegisterView: View {

    @StateObject private var vm = AuthViewModel()

    @State private var username        = ""
    @State private var email           = ""
    @State private var password        = ""
    @State private var confirmPassword = ""
    @State private var showPassword    = false
    @State private var showConfirm     = false
    @State private var appeared        = false

    var onSignIn: (() -> Void)?
    // ← Now passes the email back to ContentView
    var onRegistered: ((String) -> Void)?

    var body: some View {
        ZStack {
            Color(hex: "0A0F0D").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── Logo ──────────────────────────────────────────
                    Text("EdVenture")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "0EB060"))
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
                        EVTextField(icon: "person",   placeholder: "Username",        text: $username)
                        EVTextField(icon: "envelope", placeholder: "Email Address",   text: $email, keyboardType: .emailAddress)
                        EVSecureField(icon: "lock",   placeholder: "Password",        text: $password,        isVisible: $showPassword)
                        EVSecureField(icon: "lock",   placeholder: "Confirm Password",text: $confirmPassword, isVisible: $showConfirm)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
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

                    // ── Continue button ───────────────────────────────
                    EVPrimaryButton(title: "Continue", isLoading: vm.isLoading) {
                        Task {
                            await vm.register(
                                username: username,
                                email: email,
                                password: password,
                                confirmPassword: confirmPassword
                            )
                            // Pass email up so OTPView can display it masked
                            if vm.otpSent { onRegistered?(email) }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.3), value: appeared)

                    // ── Divider ───────────────────────────────────────
                    EVDivider()
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                    // ── Social buttons ────────────────────────────────
                    VStack(spacing: 12) {
                        EVSocialButton(icon: "g.circle",  title: "Continue with Google", isGoogle: true) {}
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.38), value: appeared)

                    // ── Footer ────────────────────────────────────────
                    HStack(spacing: 4) {
                        Text("Already have an Account?")
                            .foregroundColor(.white.opacity(0.45))
                        Button("Sign In") { onSignIn?() }
                            .foregroundColor(Color(hex: "0EB060"))
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
    RegisterView()
}
