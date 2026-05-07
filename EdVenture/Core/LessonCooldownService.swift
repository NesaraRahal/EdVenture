import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

/// Model representing a lesson with its cooldown status
struct LessonCooldownStatus {
    let lessonId: String
    let lessonName: String
    let lessonIcon: String
    let lessonColorHex: String
    let cooldownExpiresAt: Date?
    let secondsRemaining: Int?
    
    var isCooldownActive: Bool {
        guard let secondsRemaining else { return false }
        return secondsRemaining > 0
    }
    
    var displayString: String {
        guard let secondsRemaining else { return "Ready" }
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

/// Service for tracking and querying cooldown status across all lessons
@MainActor
class LessonCooldownService: NSObject, ObservableObject {
    @Published var allLessonCooldowns: [LessonCooldownStatus] = []
    @Published var leastUrgentCooldown: LessonCooldownStatus?
    
    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    private var updateTimer: Timer?
    
    static let shared = LessonCooldownService()
    
    override private init() {
        super.init()
    }
    
    deinit {
        stopListening()
    }
    
    /// Start listening to all active lessons for a user
    func startListening(for userId: String, isPro: Bool) {
        stopListening()
        
        guard !isPro else {
            // Pro users have no cooldowns
            allLessonCooldowns = []
            leastUrgentCooldown = nil
            return
        }
        
        // Listen to user's active lessons
        let listener = db.collection("users")
            .document(userId)
            .collection("activeLessons")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error = error {
                    print("❌ Error listening to active lessons: \(error)")
                    return
                }
                
                Task { @MainActor in
                    await self.updateCooldownStatuses(snapshot?.documents ?? [])
                }
            }
        
        listeners.append(listener)
        
        // Start timer to update countdown displays
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.recalculateCooldowns()
            }
        }
    }
    
    /// Stop listening to lesson updates
    func stopListening() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    /// Update cooldown statuses from Firestore snapshot
    private func updateCooldownStatuses(_ documents: [DocumentSnapshot]) async {
        var cooldowns: [LessonCooldownStatus] = []
        
        for doc in documents {
            let data = doc.data() ?? [:]
            let lessonId = doc.documentID
            let lessonName = resolveLessonName(lessonId)
            let lessonIcon = resolveLessonIcon(lessonId)
            let lessonColorHex = resolveLessonColor(lessonId)
            
            let lastLevelCompletedAt = (data["lastLevelCompletedAt"] as? Timestamp)?.dateValue()
            let cooldownExpiresAt = lastLevelCompletedAt?.addingTimeInterval(24 * 60 * 60)
            let secondsRemaining = cooldownSecondsRemaining(expiresAt: cooldownExpiresAt, now: Date())
            
            let status = LessonCooldownStatus(
                lessonId: lessonId,
                lessonName: lessonName,
                lessonIcon: lessonIcon,
                lessonColorHex: lessonColorHex,
                cooldownExpiresAt: cooldownExpiresAt,
                secondsRemaining: secondsRemaining
            )
            
            if status.isCooldownActive {
                cooldowns.append(status)
            }
        }
        
        // Sort by least urgent (least time remaining = highest priority)
        cooldowns.sort { ($0.secondsRemaining ?? 0) < ($1.secondsRemaining ?? 0) }
        
        allLessonCooldowns = cooldowns
        leastUrgentCooldown = cooldowns.first
    }
    
    /// Recalculate all cooldown timers (called every second)
    private func recalculateCooldowns() {
        let now = Date()
        var updated = false
        
        for i in 0..<allLessonCooldowns.count {
            guard let expiresAt = allLessonCooldowns[i].cooldownExpiresAt else { continue }
            
            let secondsRemaining = cooldownSecondsRemaining(expiresAt: expiresAt, now: now)
            
            if allLessonCooldowns[i].secondsRemaining != secondsRemaining {
                allLessonCooldowns[i] = LessonCooldownStatus(
                    lessonId: allLessonCooldowns[i].lessonId,
                    lessonName: allLessonCooldowns[i].lessonName,
                    lessonIcon: allLessonCooldowns[i].lessonIcon,
                    lessonColorHex: allLessonCooldowns[i].lessonColorHex,
                    cooldownExpiresAt: expiresAt,
                    secondsRemaining: secondsRemaining
                )
                updated = true
            }
        }
        
        // Remove expired cooldowns
        allLessonCooldowns.removeAll { !$0.isCooldownActive }
        
        if updated || !allLessonCooldowns.isEmpty {
            leastUrgentCooldown = allLessonCooldowns.first
        } else {
            leastUrgentCooldown = nil
        }
    }
    
    // MARK: - Private Helpers
    
    private func cooldownSecondsRemaining(expiresAt: Date?, now: Date) -> Int? {
        guard let expiresAt else { return nil }
        guard now < expiresAt else { return nil }
        return max(0, Int(expiresAt.timeIntervalSince(now)))
    }
    
    private func resolveLessonName(_ lessonId: String) -> String {
        lessonId.replacingOccurrences(of: "_", with: " ").capitalized
    }
    
    private func resolveLessonIcon(_ lessonId: String) -> String {
        switch lessonId.lowercased() {
        case "astronomy":
            return "star.fill"
        case "biology":
            return "leaf.fill"
        case "philosophy":
            return "brain.head.profile"
        case "mathematics":
            return "sum"
        case "computer_science":
            return "laptopcomputer"
        default:
            return "book.fill"
        }
    }
    
    private func resolveLessonColor(_ lessonId: String) -> String {
        switch lessonId.lowercased() {
        case "astronomy":
            return "9B59B6" // Purple
        case "biology":
            return "27AE60" // Green
        case "philosophy":
            return "E74C3C" // Red
        case "mathematics":
            return "3498DB" // Blue
        case "computer_science":
            return "F39C12" // Orange
        default:
            return "0EB060" // Default green
        }
    }
}
