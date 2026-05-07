import ActivityKit
import Foundation

/// Attributes for the Lesson Cooldown Live Activity displayed on lock screen and Dynamic Island
struct LessonCooldownActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        let secondsRemaining: Int
        let unlockTime: Date
        
        var displayText: String {
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
    
    /// Lesson name (e.g., "Astronomy")
    let lessonName: String
    /// Lesson icon system name (e.g., "star.fill")
    let lessonIcon: String
    /// Lesson color hex (e.g., "0EB060")
    let lessonColorHex: String
    /// Initial unlock time when activity is created
    let unlockTime: Date
}

/// Service to manage Lesson Cooldown Live Activities
@available(iOS 16.1, *)
actor LessonCooldownActivityManager {
    static let shared = LessonCooldownActivityManager()
    
    private var activeActivityId: String?
    private var updateTimer: Task<Void, Never>?
    
    deinit {
        updateTimer?.cancel()
    }
    
    /// Start a new lesson cooldown activity or update the existing one
    nonisolated func startCooldownActivity(
        lessonName: String,
        lessonIcon: String,
        lessonColorHex: String,
        unlockTime: Date
    ) async {
        // Convert lesson name to safe activity ID (used to identify/update activity)
        let activityId = lessonName.lowercased().replacingOccurrences(of: " ", with: "_")
        
        let attributes = LessonCooldownActivityAttributes(
            lessonName: lessonName,
            lessonIcon: lessonIcon,
            lessonColorHex: lessonColorHex,
            unlockTime: unlockTime
        )
        
        let initialState = LessonCooldownActivityAttributes.ContentState(
            secondsRemaining: max(0, Int(unlockTime.timeIntervalSince(Date()))),
            unlockTime: unlockTime
        )
        
        do {
            // End any existing activity first
            await endAllCooldownActivities()
            
            // Request new activity
            let activity = try Activity<LessonCooldownActivityAttributes>.request(
                attributes: attributes,
                contentState: initialState,
                pushType: nil
            )
            
            // Store activity ID for future updates
            await updateActiveActivityId(activityId)
            
            // Start background update timer
            await startUpdateTimer(activity: activity, unlockTime: unlockTime)
            
            print("✅ Started lesson cooldown activity: \(lessonName)")
        } catch {
            print("❌ Failed to start cooldown activity: \(error)")
        }
    }
    
    /// Stop all active cooldown activities
    nonisolated func endAllCooldownActivities() async {
        // Get all active activities of this type
        let activities = Activity<LessonCooldownActivityAttributes>.all
        
        for activity in activities {
            await activity.end(ActivityContent(state: activity.contentState, staleDate: Date()), dismissalPolicy: .immediate)
            print("⏹ Ended cooldown activity for: \(activity.attributes.lessonName)")
        }
        
        await updateActiveActivityId(nil)
        await cancelUpdateTimer()
    }
    
    // MARK: - Private Helpers
    
    private func updateActiveActivityId(_ id: String?) async {
        self.activeActivityId = id
    }
    
    private func startUpdateTimer(
        activity: Activity<LessonCooldownActivityAttributes>,
        unlockTime: Date
    ) async {
        // Cancel any existing timer
        await cancelUpdateTimer()
        
        updateTimer = Task {
            while !Task.isCancelled {
                // Update every 10 seconds
                try? await Task.sleep(nanoseconds: 10 * 1_000_000_000)
                
                if Task.isCancelled { break }
                
                let now = Date()
                let secondsRemaining = max(0, Int(unlockTime.timeIntervalSince(now)))
                
                // Update the activity
                let newState = LessonCooldownActivityAttributes.ContentState(
                    secondsRemaining: secondsRemaining,
                    unlockTime: unlockTime
                )
                
                await activity.update(ActivityContent(state: newState, staleDate: nil))
                
                // End activity when cooldown expires
                if secondsRemaining <= 0 {
                    await activity.end(ActivityContent(state: newState, staleDate: Date()), dismissalPolicy: .immediate)
                    await updateActiveActivityId(nil)
                    break
                }
            }
        }
    }
    
    private func cancelUpdateTimer() async {
        updateTimer?.cancel()
        updateTimer = nil
    }
}
