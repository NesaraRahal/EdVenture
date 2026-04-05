import Foundation
import LocalAuthentication

@MainActor
enum EVBiometricAuth {
    static func authorize(reason: String) async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            do {
                return try await context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: reason
                )
            } catch {
                return false
            }
        }

        // Fallback to device authentication (passcode / watch) where available.
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            do {
                return try await context.evaluatePolicy(
                    .deviceOwnerAuthentication,
                    localizedReason: reason
                )
            } catch {
                return false
            }
        }

        return false
    }
}
