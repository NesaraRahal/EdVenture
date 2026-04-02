import SwiftUI

struct ContentView: View {

    @State private var path          = NavigationPath()
    @State private var registeredEmail = ""

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView {
                path.append("login")
            }
            .navigationDestination(for: String.self) { route in
                Group {
                    switch route {
                    case "login":
                        LoginView(
                            onAuthenticated: { path.append("home") },
                            onCreateAccount: { path.append("register") },
                            onForgotPassword: { path.append("forgot") }
                        )
                    case "register":
                        RegisterView(
                            onSignIn: { path.removeLast() },
                            // email is passed from RegisterView — store it, then navigate
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
                            email: registeredEmail,
                            onVerified: { path.append("home") }
                        )
                    case "home":
                        HomeView(
                            onSettings: { path.append("settings") }
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
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    ContentView()
}
