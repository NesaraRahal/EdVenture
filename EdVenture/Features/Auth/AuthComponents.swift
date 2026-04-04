import SwiftUI

// MARK: - AuthComponents.swift
// Features/Auth/AuthComponents.swift

// ─────────────────────────────────────────────────────────────
// MARK: EVTextField
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
                    .foregroundColor(Color(hex: "8A9E93"))
                    .frame(width: 20)
            }

            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.35))
                }
                TextField("", text: $text)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(.white)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    // Hide system placeholder (we draw our own above)
                    .tint(Color(hex: "0EB060"))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
        )
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: EVSecureField
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
                .foregroundColor(Color(hex: "8A9E93"))
                .frame(width: 20)

            ZStack(alignment: .leading) {
                // Visible placeholder
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.35))
                }
                Group {
                    if isVisible {
                        TextField("", text: $text)
                    } else {
                        SecureField("", text: $text)
                    }
                }
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.white)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .tint(Color(hex: "0EB060"))
            }

            // Show/hide toggle — 44pt HIG touch target
            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .font(.system(size: 15))
                    .foregroundColor(Color.white.opacity(0.4))
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
        )
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: EVPrimaryButton
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
                        .tint(Color(hex: "0A0F0D"))
                } else {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "0A0F0D"))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color(hex: "0EB060"))
            .clipShape(Capsule())
        }
        .disabled(isLoading)
        .buttonStyle(ScaleButtonStyle())
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: EVSocialButton
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
// ─────────────────────────────────────────────────────────────
struct EVDivider: View {
    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 0.5)
            Text("or")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(Color.white.opacity(0.35))
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 0.5)
        }
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: ScaleButtonStyle
// ─────────────────────────────────────────────────────────────
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: EVLiquidGlassIconButton
// ─────────────────────────────────────────────────────────────
struct EVLiquidGlassIconButton: View {
    var systemName: String
    var size: CGFloat = 38
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: size, height: size)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.14), lineWidth: 0.6))
                .shadow(color: .black.opacity(0.25), radius: 8, y: 3)
        }
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
        .buttonStyle(ScaleButtonStyle())
    }
}
