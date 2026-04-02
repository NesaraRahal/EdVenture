//
//  OTPView.swift
//  EdVenture
//
//  Features/Auth/OTPView.swift

import SwiftUI
import FirebaseAuth

// MARK: - OTPView  (Polls Firebase every 3s — auto-redirects on verification)
struct OTPView: View {

    @State private var appeared   = false
    @State private var resendSent = false
    @StateObject private var vm   = AuthViewModel()

    // Timer that polls Firebase every 3 seconds
    @State private var pollingTimer: Timer? = nil

    // Email passed in from RegisterView via ContentView
    var email: String = ""

    // Navigation callback — fires automatically once verified
    var onVerified: (() -> Void)?

    // MARK: - Mask helper  →  joh****@gmail.com
    private var maskedEmail: String {
        guard let atIndex = email.firstIndex(of: "@") else { return email }
        let local   = String(email[email.startIndex..<atIndex])
        let domain  = String(email[atIndex...])
        let visible = local.prefix(3)
        let stars   = String(repeating: "*", count: max(local.count - 3, 4))
        return "\(visible)\(stars)\(domain)"
    }

    var body: some View {
        ZStack {
            Color(hex: "0A0F0D").ignoresSafeArea()

            VStack(spacing: 0) {

                Spacer()

                // ── Envelope icon ─────────────────────────────────────
                ZStack {
                    Circle()
                        .fill(Color(hex: "0EB060").opacity(0.12))
                        .frame(width: 130, height: 130)
                    Circle()
                        .fill(Color(hex: "0EB060").opacity(0.2))
                        .frame(width: 100, height: 100)
                    Circle()
                        .fill(Color(hex: "0EB060"))
                        .frame(width: 76, height: 76)
                    Image(systemName: "envelope.open.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(Color(hex: "0A0F0D"))
                }
                .scaleEffect(appeared ? 1 : 0.6)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.05), value: appeared)

                // ── Title ─────────────────────────────────────────────
                Text("Check Your Inbox")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 32)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)

                // ── Subtitle ──────────────────────────────────────────
                VStack(spacing: 6) {
                    Text("We sent a verification link to")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(.white.opacity(0.45))

                    Text(maskedEmail)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "0EB060"))

                    Text("Click the link in your email.\nYou'll be redirected automatically.")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.white.opacity(0.35))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.top, 4)
                }
                .padding(.top, 12)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.26), value: appeared)

                // ── Steps card ────────────────────────────────────────
                VStack(alignment: .leading, spacing: 16) {
                    StepRow(number: "1", text: "Open your email app")
                    StepRow(number: "2", text: "Find the email from EdVenture")
                    StepRow(number: "3", text: "Tap the verification link")
                }
                .padding(20)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
                .animation(.easeOut(duration: 0.45).delay(0.32), value: appeared)

                // ── Waiting indicator ─────────────────────────────────
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(Color(hex: "0EB060"))
                        .scaleEffect(0.8)
                    Text("Waiting for verification...")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.white.opacity(0.35))
                }
                .padding(.top, 28)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.36), value: appeared)

                // ── Resend ────────────────────────────────────────────
                Button {
                    Task {
                        await vm.resendVerificationEmail()
                        resendSent = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            resendSent = false
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        if resendSent {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "0EB060"))
                            Text("Email sent!")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(Color(hex: "0EB060"))
                        } else {
                            Text("Didn't receive it?")
                                .foregroundColor(.white.opacity(0.4))
                            Text("Resend Email")
                                .foregroundColor(Color(hex: "0EB060"))
                        }
                    }
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .frame(minHeight: 44)
                }
                .padding(.top, 12)
                .animation(.easeInOut(duration: 0.2), value: resendSent)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.40), value: appeared)

                // ── Security note ─────────────────────────────────────
                HStack(spacing: 5) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11))
                    Text("Secured with end-to-end encryption")
                        .font(.system(size: 12, design: .rounded))
                }
                .foregroundColor(.white.opacity(0.2))
                .padding(.top, 20)
                .padding(.bottom, 48)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.44), value: appeared)

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            appeared = true
            startPolling()
        }
        .onDisappear {
            stopPolling()
        }
    }

    // MARK: - Polling
    // Reloads the Firebase user every 3 seconds.
    // The moment isEmailVerified flips to true, we stop and navigate.
    private func startPolling() {
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            Task { @MainActor in
                try? await Auth.auth().currentUser?.reload()
                if Auth.auth().currentUser?.isEmailVerified == true {
                    stopPolling()
                    onVerified?()
                }
            }
        }
    }

    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }
}

// MARK: - Step row
private struct StepRow: View {
    var number: String
    var text: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: "0EB060").opacity(0.15))
                    .frame(width: 30, height: 30)
                Text(number)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "0EB060"))
            }
            Text(text)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

#Preview {
    OTPView(email: "johndoe@gmail.com")
}
