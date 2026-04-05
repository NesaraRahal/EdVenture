import SwiftUI
import Firebase

class AppDelegate: NSObject, UIApplicationDelegate {
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
    return true
  }
}

@main
struct EdVentureApp: App {
    
    // Register AppDelegate for Firebase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }
    }
}
