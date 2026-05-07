import SwiftUI

struct AccessibilitySettingsView: View {
    var onBack: (() -> Void)?

    @AppStorage("accessibility.hapticFeedback") private var hapticFeedback = true
    @AppStorage("accessibility.soundEffects") private var soundEffects = true
    @AppStorage("accessibility.screenReader") private var screenReader = true
    @AppStorage("accessibility.dynamicText") private var dynamicText = true

    var body: some View {
        ZStack {
            Color(hex: "0A0F0D").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    topBar
                        .padding(.horizontal, 20)
                        .padding(.top, 52)

                    sectionTitle("Haptic")
                        .padding(.top, 26)
                    toggleCard(
                        icon: "bell.badge.fill",
                        title: "Haptic Feedback",
                        description: "Provides tactile feedback when you interact with buttons, toggles, and other controls.",
                        isOn: $hapticFeedback
                    )

                    sectionTitle("Sound")
                        .padding(.top, 24)
                    toggleCard(
                        icon: "speaker.wave.2.fill",
                        title: "Sound Effects",
                        description: "Plays audio cues for actions. Make sure your device is not in silent mode.",
                        isOn: $soundEffects
                    )

                    sectionTitle("Vision Assistance")
                        .padding(.top, 24)
                    toggleCard(
                        icon: "eye.fill",
                        title: "Screen Reader",
                        description: "When enabled, the app will read aloud key screen content, navigation actions, and lesson details to assist users with vision impairments.",
                        isOn: $screenReader
                    )

                    sectionTitle("Text & Display")
                        .padding(.top, 24)
                    toggleCard(
                        icon: "textformat.size",
                        title: "Dynamic Text",
                        description: "Allow larger text scaling based on system text size preferences.",
                        isOn: $dynamicText
                    )
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            EVAccessibilitySupport.announce("Accessibility settings")
        }
        .onChange(of: hapticFeedback) { enabled in
            if enabled {
                EVAccessibilitySupport.playTapFeedback()
            }
            EVAccessibilitySupport.announce(enabled ? "Haptic feedback enabled" : "Haptic feedback disabled")
        }
        .onChange(of: soundEffects) { enabled in
            if enabled {
                EVAccessibilitySupport.playTapFeedback()
            }
            EVAccessibilitySupport.announce(enabled ? "Sound effects enabled" : "Sound effects disabled")
        }
        .onChange(of: screenReader) { enabled in
            EVAccessibilitySupport.announce(
                enabled
                ? "Screen reader enabled. I will now read important content aloud."
                : "Screen reader disabled.",
                force: true
            )
        }
        .onChange(of: dynamicText) { enabled in
            EVAccessibilitySupport.announce(enabled ? "Dynamic text enabled" : "Dynamic text disabled")
        }
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            EVBackButton(title: "Back", action: { onBack?() }, compactTitleSize: 16)

            Text("Accessibility")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(.white)

            Spacer()
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 42, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
    }

    private func toggleCard(icon: String,
                            title: String,
                            description: String,
                            isOn: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(hex: "0EB060").opacity(0.14))
                    .frame(width: 78, height: 78)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundColor(Color(hex: "0EB060"))
                    )

                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .tint(Color(hex: "0EB060"))
            }
            .padding(.horizontal, 16)
            .frame(height: 104)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.05), Color(hex: "0EB060").opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.6)
                    )
            )

            Text(description)
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
                .padding(.horizontal, 6)
                .padding(.bottom, 6)
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    AccessibilitySettingsView()
}
