//
//  ContentView.swift
//  EdVenture
//
//  Created by COBSCCOMP24.2p-053 on 2026-03-31.
//

import SwiftUI

struct ContentView: View {

    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView {
                path.append("login")   // ← this fires when Get Started is tapped
            }
            .navigationDestination(for: String.self) { route in
                switch route {
                case "login":
                    LoginView(
                        onAuthenticated: { },
                        onCreateAccount: { path.append("register") },
                        onForgotPassword: { path.append("forgot") }
                    )
                case "register":
                    RegisterView(
                        onSignIn: { path.removeLast() },
                        onRegistered: { path.append("otp") }
                    )
                case "forgot":
                    ForgotPasswordView(onCreateAccount: { path.append("register") })
                case "otp":
                    OTPView(onVerified: { })
                default:
                    EmptyView()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

