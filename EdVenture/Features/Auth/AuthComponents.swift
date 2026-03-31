//
//  AuthComponents.swift.swift
//  EdVenture
//
//  Created by COBSCCOMP24.2p-053 on 2026-03-31.
//

import SwiftUI

// MARK: - AuthComponents.swift
// Features/Auth/AuthComponents.swift
// Shared UI building blocks used across all Auth screens.

// ─────────────────────────────────────────────────────────────
// MARK: EVTextField
// Standard text input with optional leading icon
// ─────────────────────────────────────────────────────────────
struct EVTextField: View {
    var icon: String?
    var placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.evTextMuted)
                    .frame(width: 20)
            }
            TextField(placeholder, text: $text)
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.white)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .frame(height: 52)                       // HIG: comfortable tap area
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
        )
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: EVSecureField
// Password input with show/hide toggle
// ─────────────────────────────────────────────────────────────
struct EVSecureField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String
    @Binding var isVisible: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.evTextMuted)
                .frame(width: 20)

            Group {
                if isVisible {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .font(.system(size: 15, design: .rounded))
            .foregroundColor(.white)
            .autocapitalization(.none)
            .autocorrectionDisabled()

            // HIG: 44pt touch target for toggle
            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .font(.system(size: 15))
                    .foregroundColor(.evTextMuted)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
        )
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: EVPrimaryButton
// Full-width capsule CTA — iOS HIG primary action style
// ─────────────────────────────────────────────────────────────
struct EVPrimaryButton: View {
    var title: String
    var isLoading: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(Color.evBackground)
                } else {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.evBackground)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.evPrimary)
            .clipShape(Capsule())
        }
        .disabled(isLoading)
        .buttonStyle(ScaleButtonStyle())
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: EVSocialButton
// Apple / Google social sign-in button
// ─────────────────────────────────────────────────────────────
struct EVSocialButton: View {
    var icon: String
    var title: String
    var isGoogle: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isGoogle {
                    // Google "G" placeholder — replace with Image("google_logo")
                    Text("G")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "4285F4"))
                        .frame(width: 20)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                        .frame(width: 20)
                }
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: EVDivider
// "or" divider line used between primary and social buttons
// ─────────────────────────────────────────────────────────────
struct EVDivider: View {
    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 0.5)
            Text("or")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.evTextMuted)
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 0.5)
        }
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: ScaleButtonStyle
// Subtle press-down feedback — iOS HIG standard interaction
// ─────────────────────────────────────────────────────────────
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
