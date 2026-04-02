import SwiftUI

// MARK: - ContentView
// App/ContentView.swift
// Owns the NavigationStack — all screen routing lives here.

struct ContentView: View {

    @State private var path            = NavigationPath()
    @State private var registeredEmail = ""

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView {
                path.append("login")
            }
            .navigationDestination(for: String.self) { route in
                Group {
                    switch route {

                    // ── Auth flow ──────────────────────────────────
                    case "login":
                        LoginView(
                            onAuthenticated:  { path.append("home") },
                            onCreateAccount:  { path.append("register") },
                            onForgotPassword: { path.append("forgot") }
                        )

                    case "register":
                        RegisterView(
                            onSignIn: { path.removeLast() },
                            onRegistered: { email in
                                registeredEmail = email
                                path.append("otp")
                            }
                        )

                    case "forgot":
                        ForgotPasswordView(
                            onCreateAccount: { path.append("register") }
                        )

                    case "otp":
                        OTPView(
                            email:      registeredEmail,
                            onVerified: { path.append("home") }
                        )

                    // ── Main app ───────────────────────────────────
                    case "home":
                        HomeView(
                            onLessons:  { path.append("lessons") },
                            onSettings: { path.append("settings") }
                        )

                    case "lessons":
                        LessonsView(
                            onSettings: { path.append("settings") },
                            onHome:     { path.removeLast() }
                        )

                    case "settings":
                        SettingsView(
                            onSignOut: { path = NavigationPath() },
                            onHome:    { path.removeLast() }
                        )

                    default:
                        EmptyView()
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
