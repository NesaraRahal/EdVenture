import ActivityKit
import Foundation

/// ActivityKit attributes and state for displaying lesson cooldown timers
/// on lock screen and dynamic island
@available(iOS 16.1, *)
struct LessonCooldownActivityAttributes: ActivityAttributes {
    /// Dynamic stateful properties about your activity go here
    public struct ContentState: Codable, Hashable {
        let secondsRemaining: Int
        let unlockTime: Date
    }

    // Fixed non-changing properties about your activity go here
    let lessonName: String
    let lessonIcon: String
    let lessonColorHex: String
    let unlockTime: Date
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
