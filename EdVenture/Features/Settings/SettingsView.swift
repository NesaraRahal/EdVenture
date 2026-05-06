import SwiftUI
import FirebaseAuth

// MARK: - SettingsView
// Features/Settings/SettingsView.swift

struct SettingsView: View {

    @State private var appeared           = false
    @State private var showSignOutConfirm = false

    var onSignOut:   (() -> Void)?
    var onHome:      (() -> Void)?
    var onLessons:   (() -> Void)?
    var onDiscovery: (() -> Void)?
    var onRank:      (() -> Void)?
    var onNotifications: (() -> Void)?
    var onNotificationSettings: (() -> Void)?
    var onHelpCenter: (() -> Void)?
    var onSupport: (() -> Void)?
    var onTermsAndPrivacy: (() -> Void)?
    var onAccessibility: (() -> Void)?
    var onBiometricsAndPassword: (() -> Void)?
    var onProfile:   (() -> Void)?
    var onPayment: (() -> Void)?

    // MARK: - Body
    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "0A0F0D").ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Nav bar ───────────────────────────────────────────
                navBar

                // ── Scrollable content ────────────────────────────────
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        // Page title
                        Text("Settings")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 22)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 8)
                            .animation(.easeOut(duration: 0.35).delay(0.05), value: appeared)

                        // Profile card
                        profileCard
                            .padding(.horizontal, 20)
                            .padding(.bottom, 32)

                        // Preferences
                        sectionLabel("Preferences")
                        settingsGroup([
                            RowConfig(icon: "bell",          label: "Notifications", action: onNotificationSettings),
                        ])
                        .padding(.bottom, 24)

                        // Accessibility
                        sectionLabel("Accessibility")
                        settingsGroup([
                            RowConfig(icon: "figure.stand",  label: "Accessibility", action: onAccessibility),
                        ])
                        .padding(.bottom, 24)

                        // Security
                        sectionLabel("Security")
                        settingsGroup([
                            RowConfig(icon: "lock.shield",   label: "Biometrics and Password", action: onBiometricsAndPassword),
                        ])
                        .padding(.bottom, 24)

                        // Support
                        sectionLabel("Billing")
                        settingsGroup([
                            RowConfig(icon: "creditcard", label: "Payment & Billing", action: onPayment),
                        ])
                        .padding(.bottom, 24)

                        sectionLabel("Support")
                        settingsGroup([
                            RowConfig(icon: "questionmark.circle", label: "Help Center", action: onHelpCenter),
                            RowConfig(icon: "envelope",             label: "Support", action: onSupport),
                            RowConfig(icon: "doc.text",             label: "Terms and Privacy", action: onTermsAndPrivacy),
                        ])
                        .padding(.bottom, 32)

                        // Sign out
                        signOutButton
                            .padding(.horizontal, 20)

                        // Version
                        Text("MINDSPRINT VERSION 2.4.0-RELEASE")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.18))
                            .tracking(0.6)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 20)
                            .padding(.bottom, 110)
                    }
                }
            }

        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarHidden(true)
        .onAppear { withAnimation { appeared = true } }
        .confirmationDialog(
            "Sign Out",
            isPresented: $showSignOutConfirm,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) { performSignOut() }
            Button("Cancel",   role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }

    // MARK: - Nav bar (matches HomeView / LessonsView exactly)
    private var navBar: some View {
        EVScreenTopBar(onProfile: onProfile, onNotifications: onNotifications)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.35), value: appeared)
    }

    // MARK: - Profile card
    private var profileCard: some View {
        Button { onProfile?() } label: {
            HStack(spacing: 14) {
                // Avatar
                EVProfileAvatarView(
                    size: 54,
                    iconSize: 22,
                    iconOpacity: 0.55,
                    ringColor: Color(hex: "0EB060").opacity(0.5),
                    ringWidth: 1.5
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Nesara Rahal")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Text("ID: 111111111111")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.white.opacity(0.32))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.25))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.045), Color(hex: "0EB060").opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.6)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.easeOut(duration: 0.35).delay(0.1), value: appeared)
    }

    // MARK: - Section label
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundColor(.white.opacity(0.52))
            .tracking(0.4)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.35).delay(0.15), value: appeared)
    }

    // MARK: - Settings group
    private struct RowConfig {
        let icon: String
        let label: String
        let action: (() -> Void)?
    }

    private func settingsGroup(_ rows: [RowConfig]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { i, row in
                Button {
                    row.action?()
                } label: {
                    HStack(spacing: 14) {
                        // Icon badge
                        Image(systemName: row.icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "0EB060"))
                            .frame(width: 32, height: 32)
                            .background(Color(hex: "0EB060").opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        Text(row.label)
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(.white)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.22))
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 54)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(row.action == nil)
                .opacity(row.action == nil ? 0.88 : 1)

                // Divider between rows only
                if i < rows.count - 1 {
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 0.5)
                        .padding(.leading, 62)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.045), Color(hex: "0EB060").opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.6)
                )
        )
        .padding(.horizontal, 20)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.35).delay(0.18), value: appeared)
    }

    // MARK: - Sign out button
    private var signOutButton: some View {
        Button { showSignOutConfirm = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "FF453A"))
                Text("SIGN OUT")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "FF453A"))
                    .tracking(0.6)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.04), Color(hex: "FF453A").opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color(hex: "FF453A").opacity(0.22), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.35).delay(0.25), value: appeared)
    }

    // MARK: - Sign out
    private func performSignOut() {
        try? Auth.auth().signOut()
        onSignOut?()
    }
}

#Preview {
    SettingsView()
}
