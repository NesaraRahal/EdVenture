import ActivityKit
import Foundation

/// Shared Activity Attributes for Lesson Cooldown (placed in Shared target)
@available(iOS 16.1, *)
public struct LessonCooldownActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public let secondsRemaining: Int
        public let unlockTime: Date

        public init(secondsRemaining: Int, unlockTime: Date) {
            self.secondsRemaining = secondsRemaining
            self.unlockTime = unlockTime
        }

        public var displayText: String {
            let hours = secondsRemaining / 3600
            let minutes = (secondsRemaining % 3600) / 60

            if hours > 0 {
                return "\(hours)h \(minutes)m to go"
            } else if minutes > 0 {
                return "\(minutes)m to go"
            } else {
                return "Ready now!"
            }
        }
    }

    public let lessonName: String
    public let lessonIcon: String
    public let lessonColorHex: String
    public let unlockTime: Date

    public init(lessonName: String, lessonIcon: String, lessonColorHex: String, unlockTime: Date) {
        self.lessonName = lessonName
        self.lessonIcon = lessonIcon
        self.lessonColorHex = lessonColorHex
        self.unlockTime = unlockTime
    }
}
