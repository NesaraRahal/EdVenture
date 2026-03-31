//
//  ForgotPasswordView.swift.swift
//  EdVenture
//
//  Created by COBSCCOMP24.2p-053 on 2026-03-31.
//

import SwiftUI

// MARK: - ForgotPasswordView
// Features/Auth/ForgotPasswordView.swift

struct ForgotPasswordView: View {

    @StateObject private var vm = AuthViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var email    = ""
    @State private var appeared = false

    // Navigation callback
    var onCreateAccount: (() -> Void)?   // → RegisterView

    var body: some View {
        ZStack {
            Color.evBackground.ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Back button (HIG: leading, 44pt min) ─────────────
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Capsule())
                        // HIG: minimum 44pt touch target
                        .frame(minHeight: 44)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)

                Spacer()

                // ── Card ──────────────────────────────────────────────
                VStack(spacing: 0) {

                    Text("Forgot Password")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Enter your email address. We will send\nrecovery information.")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.evTextMuted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.top, 10)

                    // ── Email field ───────────────────────────────────
                    EVTextField(
                        icon: nil,
                        placeholder: "example@gmail.com",
                        text: $email,
                        keyboardType: .emailAddress
                    )
                    .padding(.top, 28)

                    // ── Error ─────────────────────────────────────────
                    if let error = vm.errorMessage {
                        Text(error)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.top, 10)
                    }

                    // ── Success ───────────────────────────────────────
                    if vm.resetEmailSent {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.evPrimary)
                            Text("Recovery email sent! Check your inbox.")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(.evPrimary)
                        }
                        .padding(.top, 10)
                    }

                    // ── Send button ───────────────────────────────────
                    EVPrimaryButton(
                        title: "Send",
                        isLoading: vm.isLoading
                    ) {
                        Task { await vm.sendPasswordReset(email: email) }
                    }
                    .padding(.top, 24)

                    // ── Footer ────────────────────────────────────────
                    HStack(spacing: 4) {
                        Text("Dont have an Account?")
                            .foregroundColor(.evTextMuted)
                        Button("Create One") { onCreateAccount?() }
                            .foregroundColor(.evPrimary)
                    }
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .padding(.top, 20)
                }
                .padding(28)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(.horizontal, 20)
                .scaleEffect(appeared ? 1 : 0.96)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appeared)

                Spacer()
            }
        }
        // HIG: hide default nav bar — we supply our own back button
        .navigationBarHidden(true)
        .onAppear { appeared = true }
    }
}

#Preview {
    ForgotPasswordView()
}
