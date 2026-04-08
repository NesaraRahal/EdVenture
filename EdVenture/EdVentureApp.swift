import SwiftUI
import Firebase
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        if FirebaseApp.app() == nil {
            if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
                 let options = FirebaseOptions(contentsOfFile: path) {
                FirebaseApp.configure(options: options)
            } else if let path = Bundle.main.path(forResource: "GoogleService-Info-3", ofType: "plist"),
                                let options = FirebaseOptions(contentsOfFile: path) {
                FirebaseApp.configure(options: options)
            } else {
                assertionFailure("Firebase config plist not found in app bundle.")
            }
        }

        UNUserNotificationCenter.current().delegate = self
    return true
  }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound, .badge])
    }
}

@main
struct EdVentureApp: App {
    
    // Register AppDelegate for Firebase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        // Initialize API keys on app launch
        Task {
            await MainActor.run {
                APIConfigurationService.shared.setupAPIKeys()
            }

            let prefs = EVNotificationPreferences.fromDefaults()
            _ = await EVNotificationService.shared.applyPreferences(
                prefs,
                requestAuthorizationIfNeeded: false
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
