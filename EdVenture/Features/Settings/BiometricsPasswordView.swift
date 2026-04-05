import SwiftUI
import LocalAuthentication
import FirebaseAuth
import Combine

struct BiometricsPasswordView: View {
    @StateObject private var vm = BiometricsPasswordViewModel()

    @AppStorage("security.biometricsEnabled") private var biometricsEnabled = false
    @AppStorage("security.biometricEnrollmentCompleted") private var biometricEnrollmentCompleted = false
    @AppStorage("security.requireForAppUnlock") private var requireForAppUnlock = false
    @AppStorage("security.requireForProfileChanges") private var requireForProfileChanges = false

    var onBack: (() -> Void)?

    var body: some View {
        ZStack {
            Color(hex: "0A0F0D").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    topBar
                        .padding(.horizontal, 20)
                        .padding(.top, 52)

                    Text("Passwords")
                        .font(.system(size: 33, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.top, 22)
                        .padding(.bottom, 12)

                    passwordRow
                        .padding(.horizontal, 20)

                    Text("Biometrics")
                        .font(.system(size: 33, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 12)

                    biometricsToggleRow
                        .padding(.horizontal, 20)

                    extraBiometricOptions
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    if let status = vm.statusMessage {
                        Text(status)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(.white.opacity(0.65))
                            .padding(.horizontal, 22)
                            .padding(.top, 14)
                    }

                    Text(vm.availabilityText)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.35))
                        .padding(.horizontal, 22)
                        .padding(.top, 10)
                        .padding(.bottom, 32)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            vm.refreshBiometryAvailability()
        }
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            Button {
                onBack?()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .frame(height: 44)
                .background(Color.white.opacity(0.18))
                .clipShape(Capsule())
            }
            .frame(minWidth: 44, minHeight: 44)

            Text("Biometrics and\nPassword")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(3)

            Spacer()
        }
    }

    private var passwordRow: some View {
        Button {
            Task {
                await vm.sendPasswordResetIfPossible()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "lock.open.rotation")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "0EB060"))
                    .frame(width: 36, height: 36)
                    .background(Color(hex: "0EB060").opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Text(vm.isSendingPasswordReset ? "Sending reset link..." : "Change Password")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .frame(height: 72)
            .background(cardBackground)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(vm.isSendingPasswordReset)
    }

    private var biometricsToggleRow: some View {
        HStack(spacing: 12) {
            Image(systemName: vm.biometryIcon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "0EB060"))
                .frame(width: 52, height: 52)
                .background(Color(hex: "0EB060").opacity(0.16))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text("Enable \(vm.biometryName)")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            Toggle("", isOn: Binding(
                get: { biometricsEnabled },
                set: { newValue in
                    if newValue {
                        if biometricEnrollmentCompleted {
                            // Returning user: allow simple toggle without setup challenge.
                            biometricsEnabled = true
                            vm.statusMessage = "\(vm.biometryName) enabled."
                        } else {
                            // First-time setup: verify identity once before enabling.
                            Task {
                                let ok = await vm.authenticateForEnablement(reason: "Set up \(vm.biometryName) for your account")
                                DispatchQueue.main.async {
                                    if ok {
                                        biometricEnrollmentCompleted = true
                                        biometricsEnabled = true
                                        vm.statusMessage = "\(vm.biometryName) setup completed."
                                    } else {
                                        // Revert toggle if auth failed
                                        biometricsEnabled = false
                                    }
                                }
                            }
                        }
                    } else {
                        biometricsEnabled = false
                        requireForAppUnlock = false
                        requireForProfileChanges = false
                        EVCredentialStore.clear()
                        vm.statusMessage = "\(vm.biometryName) disabled."
                    }
                }
            ))
            .labelsHidden()
            .tint(Color(hex: "0EB060"))
            .disabled(!vm.canEnableBiometricSecurity)
        }
        .padding(.horizontal, 16)
        .frame(height: 106)
        .background(cardBackground)
    }

    private var extraBiometricOptions: some View {
        VStack(spacing: 0) {
            securityToggleRow(
                title: "Require for app unlock",
                subtitle: "Prompt on opening the app",
                isOn: $requireForAppUnlock,
                isDisabled: !biometricsEnabled
            )

            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 0.5)
                .padding(.leading, 18)

            securityToggleRow(
                title: "Require for profile changes",
                subtitle: "Protect sensitive profile edits",
                isOn: $requireForProfileChanges,
                isDisabled: !biometricsEnabled
            )
        }
        .background(cardBackground)
    }

    private func securityToggleRow(title: String,
                                   subtitle: String,
                                   isOn: Binding<Bool>,
                                   isDisabled: Bool) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.white.opacity(0.45))
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color(hex: "0EB060"))
                .disabled(isDisabled)
        }
        .padding(.horizontal, 16)
        .frame(height: 68)
        .opacity(isDisabled ? 0.5 : 1)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.045), Color(hex: "0EB060").opacity(0.02)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(hex: "0EB060").opacity(0.22), lineWidth: 0.6)
            )
    }
}

@MainActor
final class BiometricsPasswordViewModel: ObservableObject {
    @Published var isBiometryAvailable = false
    @Published var isDeviceAuthenticationAvailable = false
    @Published var biometryName = "Biometrics"
    @Published var biometryIcon = "faceid"
    @Published var statusMessage: String?
    @Published var isSendingPasswordReset = false

    private var isRunningOnSimulator: Bool {
#if targetEnvironment(simulator)
        true
#else
        false
#endif
    }

    var canEnableBiometricSecurity: Bool {
        isBiometryAvailable || isDeviceAuthenticationAvailable
    }

    var availabilityText: String {
        if isRunningOnSimulator && !isBiometryAvailable {
            return "Simulator: Enable enrolled biometrics from Features > Face ID (or Touch ID) > Enrolled."
        }

        if isBiometryAvailable {
            return "\(biometryName) is available on this device."
        }

        if isDeviceAuthenticationAvailable {
            return "Biometrics unavailable, but device authentication (passcode) is available."
        }

        return "Biometrics not available on this device."
    }

    func refreshBiometryAvailability() {
        let context = LAContext()
        var error: NSError?
        isBiometryAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        isDeviceAuthenticationAvailable = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)

        switch context.biometryType {
        case .faceID:
            biometryName = "Face ID"
            biometryIcon = "faceid"
        case .touchID:
            biometryName = "Touch ID"
            biometryIcon = "touchid"
        default:
            biometryName = "Biometrics"
            biometryIcon = "lock.shield"
        }
    }

    func authenticateForEnablement(reason: String) async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        if isBiometryAvailable {
            do {
                let success = try await context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: reason
                )

                statusMessage = success ? "Biometric authentication enabled." : "Could not enable biometrics."
                return success
            } catch {
                statusMessage = "Authentication failed. Please try again."
                return false
            }
        }

        if isDeviceAuthenticationAvailable {
            do {
                let success = try await context.evaluatePolicy(
                    .deviceOwnerAuthentication,
                    localizedReason: reason
                )

                statusMessage = success ? "Device authentication enabled." : "Could not verify device authentication."
                return success
            } catch {
                statusMessage = "Authentication failed. Please try again."
                return false
            }
        }

        if isRunningOnSimulator {
            statusMessage = "Biometrics not enrolled in Simulator. Go to Features > Face ID (or Touch ID) > Enrolled."
        } else {
            statusMessage = "Biometrics is not available on this device."
        }
        return false

    }

    func sendPasswordResetIfPossible() async {
        guard let email = Auth.auth().currentUser?.email, !email.isEmpty else {
            statusMessage = "No email found for this account."
            return
        }

        isSendingPasswordReset = true
        defer { isSendingPasswordReset = false }

        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            statusMessage = "Password reset link sent to \(email)."
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}

#Preview {
    BiometricsPasswordView()
}
