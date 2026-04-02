import SwiftUI
import FirebaseAuth

// MARK: - SettingsView
// Features/Settings/SettingsView.swift
// iOS 26 HIG — Liquid Glass nav + grouped settings

struct SettingsView: View {

    @State private var appeared    = false
    @State private var selectedTab = 4           // Settings tab active
    @State private var showSignOutConfirm = false

    // Navigation callbacks
    var onSignOut:  (() -> Void)?   // → back to WelcomeView / LoginView
    var onHome:     (() -> Void)?

    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: "0A0F0D").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Spacer for liquid glass nav
                    Color.clear.frame(height: 100)

                    // ── Page title ─────────────────────────────────
                    Text("Settings")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                        .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)

                    // ── Profile card ───────────────────────────────
                    profileCard
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)

                    // ── Preferences ────────────────────────────────
                    settingsSection(title: "Preferences", rows: [
                        SettingsRow(icon: "bell",          iconColor: Color(hex: "0EB060"), title: "Notifications"),
                    ])
                    .padding(.bottom, 24)

                    // ── Accessibility ──────────────────────────────
                    settingsSection(title: "Accessibility", rows: [
                        SettingsRow(icon: "figure.stand",  iconColor: Color(hex: "0EB060"), title: "Accessibility"),
                    ])
                    .padding(.bottom, 24)

                    // ── Security ───────────────────────────────────
                    settingsSection(title: "Security", rows: [
                        SettingsRow(icon: "lock.shield",   iconColor: Color(hex: "0EB060"), title: "Biometrics and Password"),
                    ])
                    .padding(.bottom, 24)

                    // ── Support ────────────────────────────────────
                    settingsSection(title: "Support", rows: [
                        SettingsRow(icon: "questionmark.circle", iconColor: Color(hex: "0EB060"), title: "Help Center"),
                        SettingsRow(icon: "envelope",            iconColor: Color(hex: "0EB060"), title: "Contact Us"),
                        SettingsRow(icon: "doc.text",            iconColor: Color(hex: "0EB060"), title: "Terms and Privacy"),
                    ])
                    .padding(.bottom, 32)

                    // ── Sign Out ───────────────────────────────────
                    signOutButton
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                    // ── Version footer ─────────────────────────────
                    Text("MINDPRINT V2.4.6 RELEASE")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.2))
                        .tracking(0.5)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 110)
                }
            }

            // ── Liquid Glass Nav Bar ────────────────────────────────
            liquidGlassNavBar

            // ── Liquid Glass Tab Bar ────────────────────────────────
            VStack {
                Spacer()
                liquidGlassTabBar
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarHidden(true)
        .onAppear {
            withAnimation { appeared = true }
        }
        // Sign out confirmation sheet
        .confirmationDialog(
            "Sign Out",
            isPresented: $showSignOutConfirm,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                signOut()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }

    // MARK: - Liquid Glass Nav Bar
    private var liquidGlassNavBar: some View {
        HStack {
            HStack(spacing: 8) {
                Image("EdVentureLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                Text("EdVenture")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "0EB060"))
            }

            Spacer()

            HStack(spacing: 10) {
                Button {} label: {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 38, height: 38)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                }

                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 38, height: 38)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.7))
                    )
                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 56)
        .background(
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Rectangle().fill(Color(hex: "0A0F0D").opacity(0.55))
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 0.5)
                }
            }
        )
        .padding(.top, 44)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4), value: appeared)
    }

    // MARK: - Profile card
    private var profileCard: some View {
        Button {} label: {
            HStack(spacing: 14) {
                // Avatar circle
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.6))
                    )
                    .overlay(Circle().stroke(Color(hex: "0EB060").opacity(0.4), lineWidth: 1.5))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Nesara Rahal")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Text("ID: 111111111111")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.white.opacity(0.35))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .animation(.easeOut(duration: 0.4).delay(0.15), value: appeared)
    }

    // MARK: - Settings section builder
    private func settingsSection(title: String, rows: [SettingsRow]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.4))
                .tracking(0.3)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { i, row in
                    settingsRowView(row)

                    if i < rows.count - 1 {
                        Rectangle()
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 0.5)
                            .padding(.leading, 56)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    )
            )
            .padding(.horizontal, 20)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)
    }

    private func settingsRowView(_ row: SettingsRow) -> some View {
        Button {} label: {
            HStack(spacing: 14) {
                // Icon badge
                Image(systemName: row.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(row.iconColor)
                    .frame(width: 32, height: 32)
                    .background(row.iconColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text(row.title)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.25))
            }
            .padding(.horizontal, 14)
            .frame(height: 52)   // HIG: 44pt minimum touch target
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Sign Out button
    private var signOutButton: some View {
        Button {
            showSignOutConfirm = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "FF453A"))

                Text("SIGN OUT")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "FF453A"))
                    .tracking(0.5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(hex: "FF453A").opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color(hex: "FF453A").opacity(0.2), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.3), value: appeared)
    }

    // MARK: - Sign out logic
    private func signOut() {
        do {
            try Auth.auth().signOut()
            onSignOut?()
        } catch {
            print("Sign out error: \(error.localizedDescription)")
        }
    }

    // MARK: - Liquid Glass Tab Bar
    private var liquidGlassTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabItems.enumerated()), id: \.offset) { i, item in
                Button {
                    selectedTab = i
                    if i == 0 { onHome?() }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.icon)
                            .font(.system(size: 18))
                            .foregroundColor(
                                selectedTab == i
                                    ? Color(hex: "0EB060")
                                    : .white.opacity(0.35)
                            )
                            .frame(height: 32)

                        Text(item.label)
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundColor(
                                selectedTab == i
                                    ? Color(hex: "0EB060")
                                    : .white.opacity(0.3)
                            )
                            .tracking(0.5)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                }
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 28)
        .padding(.horizontal, 8)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(Color(hex: "111714").opacity(0.7))
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(Color.white.opacity(0.09), lineWidth: 0.5)
            }
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private let tabItems: [(icon: String, label: String)] = [
        ("house.fill",     "HOME"),
        ("book.fill",      "LESSONS"),
        ("safari",         "DISCOVERY"),
        ("chart.bar.fill", "RANK"),
        ("gearshape.fill", "SETTINGS"),
    ]
}

// MARK: - SettingsRow model
struct SettingsRow: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
}

#Preview {
    SettingsView()
}
