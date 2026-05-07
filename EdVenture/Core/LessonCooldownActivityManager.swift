import ActivityKit
import Foundation

/// Service to manage Lesson Cooldown Live Activities
@available(iOS 16.1, *)
actor LessonCooldownActivityManager {
    static let shared = LessonCooldownActivityManager()
    
    private var activeActivityId: String?
    private var updateTimer: Task<Void, Never>?
    private var activityInstance: Activity<LessonCooldownActivityAttributes>?
    private var activityLessonId: String?
    
    deinit {
        updateTimer?.cancel()
    }
    
    /// Start a new lesson cooldown activity or update the existing one
    func startCooldownActivity(
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
            // If an activity already exists for the same lesson, just update its state
            if let existing = activityInstance, activityLessonId == activityId {
                await existing.update(ActivityContent(state: initialState, staleDate: nil))
                // restart timer with new unlockTime
                await startUpdateTimer(activity: existing, unlockTime: unlockTime)
                return
            }

            // End any existing activity first
            if let existing = activityInstance {
                await existing.end(ActivityContent(state: initialState, staleDate: Date()), dismissalPolicy: .immediate)
                activityInstance = nil
                activityLessonId = nil
            }

            // Request new activity
            let activity = try Activity<LessonCooldownActivityAttributes>.request(
                attributes: attributes,
                contentState: initialState,
                pushType: nil
            )

            // Store activity instance for future updates
            activityInstance = activity
            activityLessonId = activityId

            // Store activity ID for reference
            await updateActiveActivityId(activityId)

            // Start background update timer
            await startUpdateTimer(activity: activity, unlockTime: unlockTime)

            print("✅ Started lesson cooldown activity: \(lessonName)")
        } catch {
            print("❌ Failed to start cooldown activity: \(error)")
        }
    }
    
    /// Stop all active cooldown activities
    func endAllCooldownActivities() async {
        // End the stored activity instance if present
        if let existing = activityInstance {
            await existing.end(ActivityContent(state: existing.contentState, staleDate: Date()), dismissalPolicy: .immediate)
            print("⏹ Ended cooldown activity for: \(existing.attributes.lessonName)")
            activityInstance = nil
            activityLessonId = nil
        }

        // Also attempt to end any other activities of this type (best-effort)
        let activities = Activity<LessonCooldownActivityAttributes>.activities
        for activity in activities {
            await activity.end(ActivityContent(state: activity.contentState, staleDate: Date()), dismissalPolicy: .immediate)
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

    /// Returns a concise snapshot of the current active activity (for debugging)
    func getActiveActivityInfo() async -> (lessonName: String?, secondsRemaining: Int?) {
        if let existing = activityInstance {
            return (existing.attributes.lessonName, existing.contentState.secondsRemaining)
        }
        return (nil, nil)
    }
}
