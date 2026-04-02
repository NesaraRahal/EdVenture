import SwiftUI
import FirebaseAuth

// MARK: - SettingsView
// Features/Settings/SettingsView.swift

struct SettingsView: View {

    @State private var appeared           = false
    @State private var showSignOutConfirm = false

    var onSignOut: (() -> Void)?
    var onHome:    (() -> Void)?

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
                            .padding(.top, 24)
                            .padding(.bottom, 24)
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
                            RowConfig(icon: "bell",          label: "Notifications"),
                        ])
                        .padding(.bottom, 24)

                        // Accessibility
                        sectionLabel("Accessibility")
                        settingsGroup([
                            RowConfig(icon: "figure.stand",  label: "Accessibility"),
                        ])
                        .padding(.bottom, 24)

                        // Security
                        sectionLabel("Security")
                        settingsGroup([
                            RowConfig(icon: "lock.shield",   label: "Biometrics and Password"),
                        ])
                        .padding(.bottom, 24)

                        // Support
                        sectionLabel("Support")
                        settingsGroup([
                            RowConfig(icon: "questionmark.circle", label: "Help Center"),
                            RowConfig(icon: "envelope",             label: "Contact Us"),
                            RowConfig(icon: "doc.text",             label: "Terms and Privacy"),
                        ])
                        .padding(.bottom, 32)

                        // Sign out
                        signOutButton
                            .padding(.horizontal, 20)

                        // Version
                        Text("MINDPRINT V2.4.6 RELEASE")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.18))
                            .tracking(0.6)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 20)
                            .padding(.bottom, 110)
                    }
                }
            }

            tabBar
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
        HStack {
            HStack(spacing: 8) {
                Image("EdVentureLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                Text("EdVenture")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "0EB060"))
            }
            Spacer()
            HStack(spacing: 10) {
                Button {} label: {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 38, height: 38)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                }
                // Avatar (active — green ring on settings page)
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 38, height: 38)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.7))
                    )
                    .overlay(
                        Circle().stroke(Color(hex: "0EB060").opacity(0.7), lineWidth: 1.5)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Rectangle().fill(Color(hex: "0A0F0D").opacity(0.6))
                VStack {
                    Spacer()
                    Rectangle().fill(Color.white.opacity(0.07)).frame(height: 0.5)
                }
            }
        )
        .padding(.top, 44)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.35), value: appeared)
    }

    // MARK: - Profile card
    private var profileCard: some View {
        Button {} label: {
            HStack(spacing: 14) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 54, height: 54)
                    Image(systemName: "person.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.55))
                }
                .overlay(
                    Circle().stroke(Color(hex: "0EB060").opacity(0.5), lineWidth: 1.5)
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
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.09), lineWidth: 0.5)
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
            .foregroundColor(.white.opacity(0.38))
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
    }

    private func settingsGroup(_ rows: [RowConfig]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { i, row in
                Button {} label: {
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
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
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
                    .fill(Color(hex: "FF453A").opacity(0.08))
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

    // MARK: - Tab bar (Settings tab active)
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabItems.enumerated()), id: \.offset) { i, item in
                Button {
                    if i == 0 { onHome?() }
                } label: {
                    VStack(spacing: 4) {
                        // Settings tab (i==4) active pill
                        if i == 4 {
                            ZStack {
                                Capsule()
                                    .fill(Color(hex: "0EB060"))
                                    .frame(width: 52, height: 32)
                                Image(systemName: item.icon)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(hex: "0A0F0D"))
                            }
                        } else {
                            Image(systemName: item.icon)
                                .font(.system(size: 18))
                                .foregroundColor(.white.opacity(0.30))
                                .frame(height: 32)
                        }
                        Text(item.label)
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundColor(i == 4 ? Color(hex: "0EB060") : .white.opacity(0.28))
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
                RoundedRectangle(cornerRadius: 30, style: .continuous).fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 30, style: .continuous).fill(Color(hex: "111714").opacity(0.75))
                RoundedRectangle(cornerRadius: 30, style: .continuous).stroke(Color.white.opacity(0.07), lineWidth: 0.5)
            }
        )
        .padding(.horizontal, 16)
        .shadow(color: .black.opacity(0.55), radius: 24, y: -6)
    }

    private let tabItems: [(icon: String, label: String)] = [
        ("house.fill",     "HOME"),
        ("book.fill",      "LESSONS"),
        ("safari",         "DISCOVERY"),
        ("chart.bar.fill", "RANK"),
        ("gearshape.fill", "SETTINGS"),
    ]

    // MARK: - Sign out
    private func performSignOut() {
        try? Auth.auth().signOut()
        onSignOut?()
    }
}

#Preview {
    SettingsView()
}
