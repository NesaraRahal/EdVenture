import SwiftUI
import FirebaseAuth

// MARK: - ContentView
// App/ContentView.swift
// Owns the NavigationStack — all screen routing lives here.

struct ContentView: View {

    @State private var path: [AppRoute] = []
    @State private var registeredEmail = ""
    @State private var pendingLessonFilter: String?
    @State private var showTelemetryConsentPrompt = false
    @State private var isSavingTelemetryConsent = false
    @State private var telemetryConsentErrorMessage: String?
    @AppStorage("accessibility.dynamicText") private var dynamicText = true
    private let mainTabAnimation = Animation.easeInOut(duration: 0.22)

    private func goToMainTab(_ route: AppRoute) {
        if path.count == 1, path.first == route { return }
        withAnimation(mainTabAnimation) {
            path = [route]
        }
    }

    private func goToLessons(filter: String? = nil) {
        pendingLessonFilter = filter
        goToMainTab(.lessons)
    }

    private func activeMainTab(for route: AppRoute?) -> EVMainTab? {
        guard let route else { return nil }
        switch route {
        case .home:
            return .home
        case .lessons:
            return .lessons
        case .discovery:
            return .discovery
        case .rank:
            return .rank
        case .settings:
            return .settings
        default:
            return nil
        }
    }

    private func accessibilityAnnouncement(for route: AppRoute) -> String {
        switch route {
        case .login:
            return "Login screen. Enter email and password, then use sign in button. Social sign in and create account options are available below."
        case .register:
            return "Register screen. Fill in account details, create your password, then continue to verification."
        case .forgotPassword:
            return "Forgot password screen. Enter your email to receive a reset link."
        case .otp:
            return "Verification screen. Enter the code sent to your email to complete sign up."
        case .home:
            return "Home screen. Top navigation and profile avatar at the top. Main area shows active lessons, progress, and quick access to tabs."
        case .lessons:
            return "Lessons screen. Browse lessons by category, search, and open a lesson card to start learning."
        case .lessonDetail:
            return "Lesson detail screen. Overview card shows XP per question and progress stats. Curriculum list below contains lesson quiz items with play buttons."
        case .question:
            return "Question screen. Timer at top, question content in the center, answer options below, hint button, and next question button at the bottom."
        case .tutorialQuestion:
            return "Tutorial question screen. A guided demo shows wrong answer feedback, hint usage, then correct answer flow."
        case .discovery:
            return "Discovery screen. Explore recommended content and discover new lessons."
        case .rank:
            return "Rank screen. View leaderboard rankings and compare your progress with others."
        case .settings:
            return "Settings screen. Sections include preferences, accessibility, security, support, and sign out."
        case .notifications:
            return "Notifications screen. View all notifications or unread ones. Notifications include leaderboard milestones, new lessons, rewards, and lesson additions."
        case .notificationSettings:
            return "Notification settings screen. Manage push notifications and reminder preferences."
        case .termsPrivacy:
            return "Terms and privacy screen. Review policy details and manage telemetry sharing preferences."
        case .accessibilitySettings:
            return "Accessibility settings screen. Toggles available for haptic feedback, sound effects, screen reader, and dynamic text."
        case .biometricsSettings:
            return "Biometrics and password settings. Enable Face ID or Touch ID, and configure protections for app unlock and profile changes."
        case .profile:
            return "Profile screen. View avatar, profile information, activity, and edit profile actions."
        case .insights:
            return "Insights screen. View subject proficiency, consistency heatmap, weekly XP performance, and daily rhythm patterns."
        case .editProfile:
            return "Edit profile screen. Update your personal details, avatar, and save changes."
        }
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
                            onLessons:   { goToLessons() },
                            onDiscovery: { goToMainTab(.discovery) },
                            onRank:      { goToMainTab(.rank) },
                            onSettings:  { goToMainTab(.settings) },
                            onOpenLesson: { lessonId in
                                path.append(AppRoute.lessonDetail(lessonId))
                            },
                            onNotifications: { path.append(AppRoute.notifications) },
                            onProfile:   { path.append(AppRoute.profile) }
                        )

                    case .lessons:
                        LessonsView(
                            initialSelectedFilter: pendingLessonFilter,
                            onHome:      { goToMainTab(.home) },
                            onDiscovery: { goToMainTab(.discovery) },
                            onRank:      { goToMainTab(.rank) },
                            onSettings:  { goToMainTab(.settings) },
                            onNotifications: { path.append(AppRoute.notifications) },
                            onProfile:   { path.append(AppRoute.profile) }
                        )

                    case .lessonDetail(let lessonId):
                        LessonDetailView(
                            lessonId: lessonId,
                            onBack: {
                                if !path.isEmpty {
                                    path.removeLast()
                                }
                            },
                            onStartQuiz: { selectedLessonId, questionIndex in
                                path.append(AppRoute.question(lessonId: selectedLessonId, questionIndex: questionIndex))
                            }
                        )

                    case .question(let lessonId, let questionIndex):
                        LevelQuizView(
                            lessonId: lessonId,
                            questionIndex: questionIndex,
                            onBack: {
                                if !path.isEmpty {
                                    path.removeLast()
                                }
                            }
                        )

                    case .tutorialQuestion:
                        TutorialQuestionView(
                            onBack: {
                                if !path.isEmpty {
                                    path.removeLast()
                                }
                            }
                        )

                    case .accessibilitySettings:
                        AccessibilitySettingsView(
                            onBack: {
                                if !path.isEmpty {
                                    path.removeLast()
                                }
                            }
                        )
                    case .discovery:
                        DiscoveryView(
                            onHome:     { goToMainTab(.home) },
                            onLessons:  { goToMainTab(.lessons) },
                            onRank:     { goToMainTab(.rank) },
                            onSettings: { goToMainTab(.settings) },
                            onNotifications: { path.append(AppRoute.notifications) },
                            onProfile:  { path.append(AppRoute.profile) }
                        )

                    case .rank:
                        RankView(
                            onHome:      { goToMainTab(.home) },
                            onLessons:   { goToMainTab(.lessons) },
                            onDiscovery: { goToMainTab(.discovery) },
                            onSettings:  { goToMainTab(.settings) },
                            onNotifications: { path.append(AppRoute.notifications) },
                            onProfile:   { path.append(AppRoute.profile) }
                        )

                    case .settings:
                        SettingsView(
                            onSignOut: { path = [] },
                            onHome:      { goToMainTab(.home) },
                            onLessons:   { goToMainTab(.lessons) },
                            onDiscovery: { goToMainTab(.discovery) },
                            onRank:      { goToMainTab(.rank) },
                            onNotifications: { path.append(AppRoute.notifications) },
                            onNotificationSettings: { path.append(AppRoute.notificationSettings) },
                            onTermsAndPrivacy: { path.append(AppRoute.termsPrivacy) },
                            onAccessibility: { path.append(AppRoute.accessibilitySettings) },
                            onBiometricsAndPassword: { path.append(AppRoute.biometricsSettings) },
                            onProfile:   { path.append(AppRoute.profile) }
                        )

                    case .termsPrivacy:
                        TermsPrivacyView(
                            onBack: {
                                if !path.isEmpty {
                                    path.removeLast()
                                }
                            }
                        )

                    case .notificationSettings:
                        NotificationSettingsView(
                            onBack: {
                                if !path.isEmpty {
                                    path.removeLast()
                                }
                            }
                        )

                    case .notifications:
                        NotificationsView()

                    case .biometricsSettings:
                        BiometricsPasswordView(
                            onBack: {
                                if !path.isEmpty {
                                    path.removeLast()
                                }
                            }
                        )

                    case .profile:
                        ProfileView(
                            onInsights: { path.append(AppRoute.insights) },
                            onEditProfile: { path.append(AppRoute.editProfile) },
                            onBack: {
                                if !path.isEmpty {
                                    path.removeLast()
                                }
                            }
                        )

                    case .insights:
                        InsightsView(
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
                .onAppear {
                    EVAccessibilitySupport.announce(accessibilityAnnouncement(for: route))

                    if route == .home {
                        Task {
                            await evaluateTelemetryConsentPrompt()
                        }
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
        .overlay(alignment: .bottom) {
            if let tab = activeMainTab(for: path.last) {
                EVMainTabNavigationBar(
                    activeTab: tab,
                    onHome: { goToMainTab(.home) },
                    onLessons: { goToMainTab(.lessons) },
                    onDiscovery: { goToMainTab(.discovery) },
                    onRank: { goToMainTab(.rank) },
                    onSettings: { goToMainTab(.settings) }
                )
            }
        }
        .dynamicTypeSize(dynamicText ? DynamicTypeSize.xSmall ... DynamicTypeSize.accessibility5
                                     : DynamicTypeSize.xSmall ... DynamicTypeSize.large)
        .sheet(isPresented: $showTelemetryConsentPrompt) {
            EVTelemetryConsentPromptSheet(
                isSaving: isSavingTelemetryConsent,
                errorMessage: telemetryConsentErrorMessage,
                onChooseImportantOnly: {
                    Task {
                        await saveTelemetryConsent(mode: .importantOnly)
                    }
                },
                onChooseBusinessValue: {
                    Task {
                        await saveTelemetryConsent(mode: .businessValue)
                    }
                }
            )
            .interactiveDismissDisabled(true)
            .presentationDetents([.medium])
        }
        // iOS 16+ NavigationStack uses the correct push/pop
        // slide transition with velocity-matched spring by default.
        // The liquid glass morph on the nav bar is automatic when
        // .ultraThinMaterial is used consistently across screens.
    }

    private func evaluateTelemetryConsentPrompt() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard !showTelemetryConsentPrompt else { return }

        do {
            let shouldPresent = try await EVTelemetryManager.shouldPresentConsentPrompt(for: uid)
            if shouldPresent {
                telemetryConsentErrorMessage = nil
                showTelemetryConsentPrompt = true
            }
        } catch {
            telemetryConsentErrorMessage = error.localizedDescription
        }
    }

    private func saveTelemetryConsent(mode: EVTelemetryMode) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        isSavingTelemetryConsent = true
        telemetryConsentErrorMessage = nil
        defer { isSavingTelemetryConsent = false }

        do {
            try await EVTelemetryManager.savePreferences(
                for: uid,
                mode: mode,
                source: "first_register_prompt"
            )

            await EVTelemetryManager.collectImportant(
                event: "telemetry_prompt_response",
                metadata: ["mode": mode.rawValue]
            )

            if mode == .businessValue {
                await EVTelemetryManager.collectBusiness(
                    event: "telemetry_prompt_business_opt_in",
                    metadata: ["mode": mode.rawValue]
                )
            }

            showTelemetryConsentPrompt = false
        } catch {
            telemetryConsentErrorMessage = error.localizedDescription
        }
    }
}

private struct EVTelemetryConsentPromptSheet: View {
    let isSaving: Bool
    let errorMessage: String?
    let onChooseImportantOnly: () -> Void
    let onChooseBusinessValue: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "0A0F0D").ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                Text("Telemetry Preference")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Essential reliability logs are always collected. Choose whether to share additional business-value usage insights.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.white.opacity(0.64))

                Button {
                    onChooseImportantOnly()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Important Logs Only")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                        Text("Recommended for privacy-first users.")
                            .font(.system(size: 12, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 0.6)
                            )
                    )
                }
                .disabled(isSaving)

                Button {
                    onChooseBusinessValue()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Important + Business")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                        Text("Help improve features with anonymized product insights.")
                            .font(.system(size: 12, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(hex: "0EB060"))
                    )
                }
                .disabled(isSaving)

                if isSaving {
                    ProgressView()
                        .tint(Color(hex: "0EB060"))
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(Color(hex: "FF453A"))
                }
            }
            .padding(22)
        }
    }
}

#Preview {
    ContentView()
}
