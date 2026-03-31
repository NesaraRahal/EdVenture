//
//  ContentView.swift
//  EdVenture
//
//  Created by COBSCCOMP24.2p-053 on 2026-03-31.
//

//
//  ContentView.swift
//  EdVenture

import SwiftUI

// MARK: - Nav routes
enum AppRoute: Hashable {
    case login
    case register
    case forgot
    case otp(email: String)   // ← carries the email through
    case home
}

struct ContentView: View {

    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView {
                path.append(AppRoute.login)
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {

                case .login:
                    LoginView(
                        onAuthenticated: { path.append(AppRoute.home) },
                        onCreateAccount: { path.append(AppRoute.register) },
                        onForgotPassword: { path.append(AppRoute.forgot) }
                    )

                case .register:
                    RegisterView(
                        onSignIn: { path.removeLast() },
                        onRegistered: { email in
                            // ← email is passed up from RegisterView
                            path.append(AppRoute.otp(email: email))
                        }
                    )

                case .forgot:
                    ForgotPasswordView(
                        onCreateAccount: { path.append(AppRoute.register) }
                    )

                case .otp(let email):
                    OTPView(
                        email: email,
                        onVerified: { path.append(AppRoute.home) }
                    )

                case .home:
                    HomeView()
                }
            }
            .navigationBarHidden(true)
        }
    }
}
