import ActivityKit
import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

/// Service to manage lesson cooldown live activities for lock screen + dynamic island
@MainActor
final class LessonCooldownActivityService: ObservableObject {
    static let shared = LessonCooldownActivityService()
    
    @Published var activeCooldowns: [ActiveCooldownLesson] = []
    @Published var minCooldownLesson: ActiveCooldownLesson?
    
    private var updateTimer: AnyCancellable?
    private var activities: [String: Activity<LessonCooldownActivityAttributes>] = [:]
    private let db = Firestore.firestore()
    
    private init() {
        startUpdateTimer()
    }
    
    deinit {
        Task { @MainActor [weak self] in
            self?.updateTimer?.cancel()
            for (lessonId, activity) in self?.activities ?? [:] {
                await activity.end(nil, dismissalPolicy: .default)
                self?.activities.removeValue(forKey: lessonId)
            }
        }
    }
    
    /// Start a live activity for a lesson cooldown
    func startCooldownActivity(
        lessonId: String,
        lessonTitle: String,
        icon: String,
        colorHex: String,
        unlockAt: Date
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("⚠️ Live activities not enabled on this device")
            return
        }
        
        if let existing = activities[lessonId] {
            Task {
                await existing.end(nil, dismissalPolicy: .immediate)
            }
        }
        
        let secondsRemaining = max(0, Int(unlockAt.timeIntervalSinceNow))
        let progressPercent = 1.0 - (Double(secondsRemaining) / (24.0 * 60.0 * 60.0))
        
        let attributes = LessonCooldownActivityAttributes(
            lessonId: lessonId,
            lessonTitle: lessonTitle,
            icon: icon,
            colorHex: colorHex
        )
        
        let contentState = LessonCooldownActivityAttributes.ContentState(
            lessonName: lessonTitle,
            lessonIcon: icon,
            lessonColor: colorHex,
            hoursRemaining: secondsRemaining / 3600,
            minutesRemaining: (secondsRemaining % 3600) / 60,
            secondsRemaining: secondsRemaining % 60,
            unlockAt: unlockAt,
            progressPercent: max(0, progressPercent)
        )
        
        do {
            let activity = try Activity<LessonCooldownActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )
            
            activities[lessonId] = activity
            print("✅ Started live activity for lesson: \(lessonTitle) (ID: \(activity.id))")
            updateActiveCooldowns()
        } catch {
            print("❌ Failed to start activity: \(error.localizedDescription)")
        }
    }
    
    /// End activity for a specific lesson
    func endActivity(forLessonId lessonId: String) {
        if let activity = activities[lessonId] {
            Task {
                await activity.end(nil, dismissalPolicy: .default)
                activities.removeValue(forKey: lessonId)
                print("✅ Ended activity for lesson: \(lessonId)")
            }
        }
    }
    
    /// End all cooldown activities
    func endAllActivities() {
        for (lessonId, activity) in activities {
            Task {
                await activity.end(nil, dismissalPolicy: .default)
                activities.removeValue(forKey: lessonId)
            }
        }
    }
    
    /// Update activity state periodically
    func updateActivityState(forLessonId lessonId: String, unlockAt: Date) {
        guard let activity = activities[lessonId] else { return }
        
        let secondsRemaining = max(0, Int(unlockAt.timeIntervalSinceNow))
        
        if secondsRemaining <= 0 {
            endActivity(forLessonId: lessonId)
            return
        }
        
        let progressPercent = 1.0 - (Double(secondsRemaining) / (24.0 * 60.0 * 60.0))
        
        let contentState = LessonCooldownActivityAttributes.ContentState(
            lessonName: activity.attributes.lessonTitle,
            lessonIcon: activity.attributes.icon,
            lessonColor: activity.attributes.colorHex,
            hoursRemaining: secondsRemaining / 3600,
            minutesRemaining: (secondsRemaining % 3600) / 60,
            secondsRemaining: secondsRemaining % 60,
            unlockAt: unlockAt,
            progressPercent: max(0, progressPercent)
        )
        
        Task {
            await activity.update(ActivityContent(state: contentState, staleDate: nil))
        }
    }
    
    /// Query and load all active cooldowns for current user
    func loadActiveCooldownsForUser() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            activeCooldowns = []
            return
        }
        
        do {
            let lessonSnapshot = try await db.collection("lessons").getDocuments()
            var cooldowns: [ActiveCooldownLesson] = []
            
            for lessonDoc in lessonSnapshot.documents {
                let lessonId = lessonDoc.documentID
                let title = lessonDoc.data()["title"] as? String ?? "Unknown"
                let icon = lessonDoc.data()["icon"] as? String ?? "book.fill"
                let colorHex = lessonDoc.data()["color"] as? String ?? "0EB060"
                
                let activeLessonDoc = try await db.collection("users")
                    .document(uid)
                    .collection("activeLessons")
                    .document(lessonId)
                    .getDocument()
                
                guard let activeData = activeLessonDoc.data() else { continue }
                
                if let lastCompletedTimestamp = activeData["lastLevelCompletedAt"] as? Timestamp {
                    let lastCompletedAt = lastCompletedTimestamp.dateValue()
                    let unlockAt = lastCompletedAt.addingTimeInterval(24 * 60 * 60)
                    let secondsRemaining = max(0, Int(unlockAt.timeIntervalSinceNow))
                    
                    if secondsRemaining > 0 {
                        let cooldown = ActiveCooldownLesson(
                            id: lessonId,
                            title: title,
                            icon: icon,
                            colorHex: colorHex,
                            unlockAt: unlockAt,
                            secondsRemaining: secondsRemaining
                        )
                        cooldowns.append(cooldown)
                    }
                }
            }
            
            activeCooldowns = cooldowns.sorted { $0.secondsRemaining < $1.secondsRemaining }
            updateMinCooldownLesson()
        } catch {
            print("❌ Failed to load cooldowns: \(error.localizedDescription)")
            activeCooldowns = []
        }
    }
    
    private func updateMinCooldownLesson() {
        minCooldownLesson = activeCooldowns.min { $0.secondsRemaining < $1.secondsRemaining }
    }
    
    private func updateActiveCooldowns() {
        let activeLessonIds = Set(activities.keys)
        activeCooldowns = activeCooldowns.filter { activeLessonIds.contains($0.id) }
        updateMinCooldownLesson()
    }
    
    private func startUpdateTimer() {
        updateTimer = Timer.publish(every: 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.loadActiveCooldownsForUser()
                    for (lessonId, _) in self?.activities ?? [:] {
                        if let lesson = self?.activeCooldowns.first(where: { $0.id == lessonId }) {
                            self?.updateActivityState(forLessonId: lessonId, unlockAt: lesson.unlockAt)
                        }
                    }
                }
            }
    }
}
