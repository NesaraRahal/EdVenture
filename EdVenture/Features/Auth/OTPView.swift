//
//  OTPView.swift
//  EdVenture
//
//  Created by COBSCCOMP24.2p-053 on 2026-03-31.
//

import SwiftUI

// MARK: - OTPView
// Features/Auth/OTPView.swift

struct OTPView: View {

    @StateObject private var vm = AuthViewModel()

    // The 6 OTP digit boxes
    @State private var digits: [String] = Array(repeating: "", count: 6)
    @FocusState private var focusedIndex: Int?
    @State private var appeared  = false
    @State private var shaking   = false

    // Masked phone/email shown in subtitle — pass from caller
    var maskedContact: String = "0761566534"

    // Navigation callback
    var onVerified: (() -> Void)?

    var body: some View {
        ZStack {
            Color.evBackground.ignoresSafeArea()

            VStack(spacing: 0) {

                Spacer()

                // ── Badge icon ────────────────────────────────────────
                ZStack {
                    // Outer ring
                    Circle()
                        .fill(Color.evPrimary.opacity(0.15))
                        .frame(width: 110, height: 110)
                    // Inner fill
                    Circle()
                        .fill(Color.evPrimary)
                        .frame(width: 86, height: 86)
                    Image(systemName: "checkmark")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color.evBackground)
                }
                .scaleEffect(appeared ? 1 : 0.7)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.55, dampingFraction: 0.65).delay(0.05), value: appeared)

                // ── Title ─────────────────────────────────────────────
                Text("Verification Code")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 28)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.18), value: appeared)

                Text("We sent a 6digit code to")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.evTextMuted)
                    .padding(.top, 8)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.22), value: appeared)

                Text(maskedContact)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.evPrimary)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.25), value: appeared)

                // ── OTP boxes ─────────────────────────────────────────
                HStack(spacing: 10) {
                    ForEach(0..<6, id: \.self) { i in
                        OTPBox(
                            digit: $digits[i],
                            isFocused: focusedIndex == i
                        )
                        .focused($focusedIndex, equals: i)
                        .onChange(of: digits[i]) { newVal in
                            handleInput(newVal, at: i)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 36)
                .offset(x: shaking ? -8 : 0)
                .animation(shaking ? .default.repeatCount(4, autoreverses: true).speed(6) : .default, value: shaking)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.3), value: appeared)

                // ── Error ─────────────────────────────────────────────
                if let error = vm.errorMessage {
                    Text(error)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .padding(.top, 12)
                }

                // ── Resend ────────────────────────────────────────────
                Button {
                    Task { await vm.resendVerificationEmail() }
                } label: {
                    Text("Resend Code")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.evPrimary)
                        .frame(minHeight: 44)   // HIG touch target
                }
                .padding(.top, 8)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.36), value: appeared)

                // ── Verify button ─────────────────────────────────────
                EVPrimaryButton(
                    title: "Verify & Continue",
                    isLoading: vm.isLoading
                ) {
                    Task {
                        await vm.verifyOTP()
                        if vm.isAuthenticated {
                            onVerified?()
                        } else {
                            triggerShake()
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.4), value: appeared)

                // ── Security note ─────────────────────────────────────
                HStack(spacing: 5) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11))
                    Text("Secure with end-to-end encryption")
                        .font(.system(size: 12, design: .rounded))
                }
                .foregroundColor(.evTextMuted)
                .padding(.top, 16)
                .padding(.bottom, 40)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.44), value: appeared)

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            appeared = true
            // Auto-focus first box
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedIndex = 0
            }
        }
    }

    // MARK: - OTP input logic
    private func handleInput(_ value: String, at index: Int) {
        // Allow only single digit
        if value.count > 1 {
            digits[index] = String(value.last ?? Character(""))
        }
        // Strip non-numerics
        digits[index] = digits[index].filter { $0.isNumber }

        // Auto-advance focus
        if !digits[index].isEmpty && index < 5 {
            focusedIndex = index + 1
        }
        // Auto-retreat on delete
        if digits[index].isEmpty && index > 0 {
            focusedIndex = index - 1
        }
    }

    private func triggerShake() {
        shaking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            shaking = false
        }
    }
}

// MARK: - Single OTP digit box
private struct OTPBox: View {
    @Binding var digit: String
    var isFocused: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(
                            isFocused ? Color.evPrimary : Color.white.opacity(0.15),
                            lineWidth: isFocused ? 2 : 1
                        )
                )
                .frame(width: 46, height: 54)

            // Hidden TextField for keyboard input
            TextField("", text: $digit)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .multilineTextAlignment(.center)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 46, height: 54)
                .opacity(digit.isEmpty ? 0 : 1)

            if digit.isEmpty {
                Circle()
                    .fill(Color.white.opacity(isFocused ? 0.5 : 0.2))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

#Preview {
    OTPView()
}
