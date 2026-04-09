import SwiftUI

struct NotificationSettingsView: View {
    @AppStorage("notifications.pushEnabled") private var pushEnabled = true
    @AppStorage("notifications.dailyReminders") private var dailyReminders = true
    @AppStorage("notifications.streakReminders") private var streakReminders = true
    @AppStorage("notifications.weeklySummary") private var weeklySummary = true
    @AppStorage("notifications.newContentAlerts") private var newContentAlerts = false

    @State private var showPermissionAlert = false

    var onBack: (() -> Void)?

    var body: some View {
        ZStack {
            Color(hex: "0A0F0D").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                        .padding(.top, 52)

                    pushCard

                    Text("Notification Types")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    VStack(spacing: 0) {
                        notificationRow(icon: "calendar", title: "Daily Learning Reminders", isOn: $dailyReminders, showDivider: true)
                        notificationRow(icon: "flame", title: "Streak Reminders", isOn: $streakReminders, showDivider: true)
                        notificationRow(icon: "chart.bar", title: "Weekly Progress Summary", isOn: $weeklySummary, showDivider: true)
                        notificationRow(icon: "megaphone", title: "New Content Alerts", isOn: $newContentAlerts, showDivider: false)
                    }
                    .background(cardBackground)

                    Spacer(minLength: 26)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await applyPreferences(requestAuthorizationIfNeeded: false)
            }
        }
        .onChange(of: pushEnabled) { _ in
            Task {
                await applyPreferences(requestAuthorizationIfNeeded: true)
            }
        }
        .onChange(of: dailyReminders) { _ in
            Task {
                await applyPreferences(requestAuthorizationIfNeeded: false)
            }
        }
        .onChange(of: streakReminders) { _ in
            Task {
                await applyPreferences(requestAuthorizationIfNeeded: false)
            }
        }
        .onChange(of: weeklySummary) { _ in
            Task {
                await applyPreferences(requestAuthorizationIfNeeded: false)
            }
        }
        .onChange(of: newContentAlerts) { _ in
            Task {
                await applyPreferences(requestAuthorizationIfNeeded: false)
            }
        }
        .alert("Notifications Permission Required", isPresented: $showPermissionAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Enable notifications in iOS Settings to receive reminders and alerts.")
        }
    }

    private func applyPreferences(requestAuthorizationIfNeeded: Bool) async {
        let prefs = EVNotificationPreferences(
            pushEnabled: pushEnabled,
            dailyReminders: dailyReminders,
            streakReminders: streakReminders,
            weeklySummary: weeklySummary,
            newContentAlerts: newContentAlerts
        )

        let result = await EVNotificationService.shared.applyPreferences(
            prefs,
            requestAuthorizationIfNeeded: requestAuthorizationIfNeeded
        )

        switch result {
        case .success:
            break
        case .permissionDenied:
            if pushEnabled {
                pushEnabled = false
            }
            showPermissionAlert = true
        case .permissionNotDetermined:
            break
        }
    }

    private var header: some View {
        HStack {
            Button(action: { onBack?() }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                }
                .foregroundColor(Color(hex: "0A0F0D"))
                .padding(.horizontal, 18)
                .frame(height: 50)
                .background(Color.white.opacity(0.82))
                .clipShape(Capsule())
            }

            Spacer()

            Text("Notifications")
                .font(.system(size: 35, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer()
                .frame(width: 98)
        }
    }

    private var pushCard: some View {
        HStack(spacing: 14) {
            iconBadge(systemName: "bell.badge")

            VStack(alignment: .leading, spacing: 6) {
                Text("Push Notifications")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Enable to receive notifications on your device")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(2)
            }

            Spacer(minLength: 10)

            Toggle("", isOn: $pushEnabled)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "0EB060")))
                .scaleEffect(1.1)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(cardBackground)
    }

    @ViewBuilder
    private func notificationRow(
        icon: String,
        title: String,
        isOn: Binding<Bool>,
        showDivider: Bool
    ) -> some View {
        HStack(spacing: 14) {
            iconBadge(systemName: icon)

            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.92))
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 12)

            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "0EB060")))
                .scaleEffect(1.1)
        }
        .padding(.horizontal, 18)
        .frame(minHeight: 96)

        if showDivider {
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 0.8)
                .padding(.leading, 88)
                .padding(.trailing, 18)
        }
    }

    private func iconBadge(systemName: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(hex: "0EB060").opacity(0.12))
                .frame(width: 56, height: 56)
            Image(systemName: systemName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(Color(hex: "0EB060"))
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.05), Color(hex: "0EB060").opacity(0.03)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
            )
    }
}

#Preview {
    NotificationSettingsView()
}
