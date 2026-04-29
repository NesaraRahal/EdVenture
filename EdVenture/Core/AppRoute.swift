import Foundation

// Centralized typed routes to avoid stringly-typed navigation bugs.
enum AppRoute: Hashable {
    case login
    case register
    case forgotPassword
    case otp
    case preferencesOnboarding
    case home
    case lessons
    case discovery
    case rank
    case settings
    case notifications
    case notificationSettings
    case helpCenter
    case support
    case termsPrivacy
    case biometricsSettings
    case accessibilitySettings
    case lessonDetail(String)
    case question(lessonId: String, questionIndex: Int)
    case levelSummary(lessonId: String, score: Int, total: Int, earnedXP: Int, attemptSessionId: String, totalTimeSeconds: Int)
    case reviewAnswers(lessonId: String, attemptSessionId: String, score: Int, total: Int, totalTimeSeconds: Int)
    case tutorialQuestion
    case profile
    case insights
    case editProfile
}
