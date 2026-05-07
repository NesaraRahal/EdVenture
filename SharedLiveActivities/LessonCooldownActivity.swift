import ActivityKit
import Foundation

/// ActivityKit attributes and state for displaying lesson cooldown timers
/// on lock screen and dynamic island
struct LessonCooldownActivityAttributes: ActivityAttributes {
    /// Static content that doesn't change during the activity
    public struct ContentState: Codable, Hashable {
        let lessonName: String
        let lessonIcon: String
        let lessonColor: String
        let hoursRemaining: Int
        let minutesRemaining: Int
        let secondsRemaining: Int
        let unlockAt: Date
        let progressPercent: Double
    }

    // Static attributes (doesn't change)
    let lessonId: String
    let lessonTitle: String
    let icon: String
    let colorHex: String
}

/// Model for tracking active cooldown lessons
struct ActiveCooldownLesson: Identifiable, Equatable {
    let id: String // lessonId
    let title: String
    let icon: String
    let colorHex: String
    let unlockAt: Date
    let secondsRemaining: Int
    
    var hoursRemaining: Int { secondsRemaining / 3600 }
    var minutesRemaining: Int { (secondsRemaining % 3600) / 60 }
    var secsRemaining: Int { secondsRemaining % 60 }
    
    var displayText: String {
        if secondsRemaining <= 0 {
            return "\(title) ready"
        }
        let h = hoursRemaining
        let m = minutesRemaining
        if h > 0 {
            return "\(title) \(h)h to go"
        }
        return "\(title) \(m)m to go"
    }
}
