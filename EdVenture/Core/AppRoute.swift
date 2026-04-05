import Foundation

// Centralized typed routes to avoid stringly-typed navigation bugs.
enum AppRoute: Hashable {
    case login
    case register
    case forgotPassword
    case otp
    case home
    case lessons
    case discovery
    case rank
    case settings
    case biometricsSettings
    case lessonDetail(String)
    case profile
    case editProfile
}
