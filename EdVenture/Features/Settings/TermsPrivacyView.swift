import SwiftUI
import FirebaseAuth
import Combine

struct TermsPrivacyView: View {
    var onBack: (() -> Void)?

    @StateObject private var vm = TermsPrivacyViewModel()

    var body: some View {
        ZStack {
            Color(hex: "0A0F0D").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    topBar
                        .padding(.top, 56)
                        .padding(.horizontal, 20)

                    titleSection
                        .padding(.horizontal, 20)

                    termsCard
                        .padding(.horizontal, 20)

                    privacyCard
                        .padding(.horizontal, 20)

                    telemetryCard
                        .padding(.horizontal, 20)

                    if let errorMessage = vm.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(Color(hex: "FF453A"))
                            .padding(.horizontal, 20)
                    }

                    if let saveMessage = vm.saveMessage {
                        Text(saveMessage)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(Color(hex: "0EB060"))
                            .padding(.horizontal, 20)
                    }

                    saveButton
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await vm.load()
        }
    }

    private var topBar: some View {
        HStack {
            EVBackButton(title: "Back", action: { onBack?() }, compactTitleSize: 15)

            Spacer()
        }
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Terms & Privacy")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Review legal details and control telemetry sharing.")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.white.opacity(0.58))
        }
    }

    private var termsCard: some View {
        contentCard(icon: "doc.text.fill", accent: Color(hex: "0EB060"), title: "Terms of Use") {
            VStack(alignment: .leading, spacing: 8) {
                bullet("Use EdVenture responsibly and do not abuse platform features.")
                bullet("Do not share harmful, illegal, or misleading content.")
                bullet("Your account can be restricted for policy violations.")
            }
        }
    }

    private var privacyCard: some View {
        contentCard(icon: "hand.raised.fill", accent: Color(hex: "38BDF8"), title: "Privacy") {
            VStack(alignment: .leading, spacing: 8) {
                bullet("We store profile and learning-progress data to run the app.")
                bullet("You can edit profile details and control telemetry on this screen.")
                bullet("Telemetry data is separated from your core learning records.")
            }
        }
    }

    private var telemetryCard: some View {
        contentCard(icon: "wave.3.right.circle.fill", accent: Color(hex: "F59E0B"), title: "Telemetry") {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Essential Logs")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Crash, authentication, and critical reliability logs are always collected to keep the app stable.")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.white.opacity(0.56))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Business Telemetry")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))

                    Toggle(isOn: $vm.businessTelemetryEnabled) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Allow Business-Value Data")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            Text("When enabled, anonymized usage data that helps product decisions will be collected.")
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(.white.opacity(0.56))
                        }
                    }
                    .tint(Color(hex: "0EB060"))

                    Text(vm.businessTelemetryEnabled
                         ? "Business telemetry is enabled."
                         : "Only important reliability logs are being collected.")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.white.opacity(0.62))
                }
            }
        }
    }

    private var saveButton: some View {
        Button {
            Task { await vm.savePreferences() }
        } label: {
            HStack(spacing: 10) {
                if vm.isSaving {
                    ProgressView()
                        .tint(.black)
                } else {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 15, weight: .semibold))
                }

                Text(vm.isSaving ? "Saving..." : "Save Preferences")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color(hex: "0EB060"))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(vm.isSaving)
        .buttonStyle(ScaleButtonStyle())
    }

    private func contentCard<Content: View>(icon: String,
                                            accent: Color,
                                            title: String,
                                            @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(accent)
                    .frame(width: 30, height: 30)
                    .background(accent.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.04), accent.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.6)
                )
        )
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Color(hex: "0EB060"))
                .frame(width: 6, height: 6)
                .padding(.top, 6)

            Text(text)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

@MainActor
final class TermsPrivacyViewModel: ObservableObject {
    @Published var telemetryMode: EVTelemetryMode = .importantOnly
    @Published var businessTelemetryEnabled = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var saveMessage: String?

    func load() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "Sign in is required to manage telemetry preferences."
            return
        }

        do {
            let preferences = try await EVTelemetryManager.loadPreferences(for: uid)
            telemetryMode = preferences.mode
            businessTelemetryEnabled = preferences.mode == .businessValue
            errorMessage = nil

            await EVTelemetryManager.collectImportant(
                event: "terms_privacy_opened",
                metadata: ["screen": "terms_privacy"]
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func savePreferences() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "Sign in is required to manage telemetry preferences."
            return
        }

        isSaving = true
        saveMessage = nil
        errorMessage = nil
        defer { isSaving = false }

        do {
            telemetryMode = businessTelemetryEnabled ? .businessValue : .importantOnly

            try await EVTelemetryManager.savePreferences(
                for: uid,
                mode: telemetryMode
            )

            saveMessage = "Preferences updated."

            await EVTelemetryManager.collectImportant(
                event: "telemetry_preferences_updated",
                metadata: [
                    "mode": telemetryMode.rawValue,
                    "businessTelemetryEnabled": businessTelemetryEnabled ? "true" : "false"
                ]
            )

            if businessTelemetryEnabled {
                await EVTelemetryManager.collectBusiness(
                    event: "telemetry_opt_in_business_mode",
                    metadata: ["mode": telemetryMode.rawValue]
                )
            } else {
                await EVTelemetryManager.collectImportant(
                    event: "telemetry_business_mode_disabled",
                    metadata: ["mode": telemetryMode.rawValue]
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    TermsPrivacyView()
}
