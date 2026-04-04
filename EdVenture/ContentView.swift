import SwiftUI

// MARK: - ContentView
// App/ContentView.swift
// Owns the NavigationStack — all screen routing lives here.

struct ContentView: View {

    @State private var path            = NavigationPath()
    @State private var registeredEmail = ""

    private func goToMainTab(_ route: AppRoute) {
        path = NavigationPath()
        path.append(route)
    }

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView {
                path.append(AppRoute.login)
            }
            .navigationDestination(for: AppRoute.self) { route in
                Group {
                    switch route {

                    // ── Auth flow ──────────────────────────────────
                    case .login:
                        LoginView(
                            onAuthenticated:  { path.append(AppRoute.home) },
                            onCreateAccount:  { path.append(AppRoute.register) },
                            onForgotPassword: { path.append(AppRoute.forgotPassword) }
                        )

                    case .register:
                        RegisterView(
                            onSignIn: { path.removeLast() },
                            onRegistered: { email in
                                registeredEmail = email
                                path.append(AppRoute.otp)
                            }
                        )

                    case .forgotPassword:
                        ForgotPasswordView(
                            onCreateAccount: { path.append(AppRoute.register) }
                        )

                    case .otp:
                        OTPView(
                            email:      registeredEmail,
                            onVerified: { path.append(AppRoute.home) }
                        )

                    // ── Main app ───────────────────────────────────
                    case .home:
                        HomeView(
                            onLessons:   { goToMainTab(.lessons) },
                            onDiscovery: { goToMainTab(.discovery) },
                            onRank:      { goToMainTab(.rank) },
                            onSettings:  { goToMainTab(.settings) },
                            onProfile:   { path.append(AppRoute.profile) }
                        )

                    case .lessons:
                        LessonsView(
                            onHome:      { goToMainTab(.home) },
                            onDiscovery: { goToMainTab(.discovery) },
                            onRank:      { goToMainTab(.rank) },
                            onSettings:  { goToMainTab(.settings) },
                            onProfile:   { path.append(AppRoute.profile) }
                        )

                    case .discovery:
                        DiscoveryView(
                            onHome:     { goToMainTab(.home) },
                            onLessons:  { goToMainTab(.lessons) },
                            onRank:     { goToMainTab(.rank) },
                            onSettings: { goToMainTab(.settings) },
                            onProfile:  { path.append(AppRoute.profile) }
                        )

                    case .rank:
                        RankView(
                            onHome:      { goToMainTab(.home) },
                            onLessons:   { goToMainTab(.lessons) },
                            onDiscovery: { goToMainTab(.discovery) },
                            onSettings:  { goToMainTab(.settings) },
                            onProfile:   { path.append(AppRoute.profile) }
                        )

                    case .settings:
                        SettingsView(
                            onSignOut: { path = NavigationPath() },
                            onHome:      { goToMainTab(.home) },
                            onLessons:   { goToMainTab(.lessons) },
                            onDiscovery: { goToMainTab(.discovery) },
                            onRank:      { goToMainTab(.rank) },
                            onProfile:   { path.append(AppRoute.profile) }
                        )

                    case .profile:
                        ProfileView(
                            onEditProfile: { path.append(AppRoute.editProfile) },
                            onBack: {
                                if !path.isEmpty {
                                    path.removeLast()
                                }
                            }
                        )

                    case .editProfile:
                        EditProfileView(
                            onBack: {
                                if !path.isEmpty {
                                    path.removeLast()
                                }
                            }
                        )
                    }
                }
                // ── iOS standard slide transition ──────────────────
                // .navigationTransition is iOS 18+
                // NavigationStack already provides the correct
                // push/pop slide-from-right by default on all iOS 16+
                // No modifier needed — removing custom transitions
                // that were overriding the native glass morph effect.
            }
            // Hide the system nav bar globally — each screen
            // draws its own liquid glass nav bar
            .navigationBarHidden(true)
        }
        // iOS 16+ NavigationStack uses the correct push/pop
        // slide transition with velocity-matched spring by default.
        // The liquid glass morph on the nav bar is automatic when
        // .ultraThinMaterial is used consistently across screens.
    }
}

#Preview {
    ContentView()
}
