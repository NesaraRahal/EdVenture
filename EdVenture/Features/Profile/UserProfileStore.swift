import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Combine
import UIKit

struct UserProfile {
    var fullName: String
    var username: String
    var email: String
    var phone: String
    var bio: String
    var interests: [String]
    var profileImagePath: String
    var profileImageURL: String
    var profileImageBase64: String
    var dailyGoalMinutes: Int
    var dailyProgressSeconds: Int
    var isEmailVerified: Bool
    var isPro: Bool
    var proPurchasedAt: Date?
    // Stats
    var currentStreak: Int
    var totalXP: Int
    var accuracyPercent: Int
    var quizzesCompleted: Int
    var strongestSubject: String

    static let empty = UserProfile(
        fullName: "",
        username: "",
        email: "",
        phone: "",
        bio: "",
        interests: [],
        profileImagePath: "",
        profileImageURL: "",
        profileImageBase64: "",
        dailyGoalMinutes: 10,
        dailyProgressSeconds: 0,
        isEmailVerified: false,
        isPro: false,
        proPurchasedAt: nil,
        currentStreak: 0,
        totalXP: 0,
        accuracyPercent: 0,
        quizzesCompleted: 0,
        strongestSubject: ""
    )

    init(fullName: String,
         username: String,
         email: String,
         phone: String,
         bio: String,
         interests: [String],
         profileImagePath: String,
         profileImageURL: String,
         profileImageBase64: String,
         dailyGoalMinutes: Int,
         dailyProgressSeconds: Int,
            isEmailVerified: Bool,
            isPro: Bool = false,
            proPurchasedAt: Date? = nil,
            currentStreak: Int = 0,
            totalXP: Int = 0,
            accuracyPercent: Int = 0,
            quizzesCompleted: Int = 0,
            strongestSubject: String = "") {
        self.fullName = fullName
        self.username = username
        self.email = email
        self.phone = phone
        self.bio = bio
        self.interests = interests
        self.profileImagePath = profileImagePath
        self.profileImageURL = profileImageURL
        self.profileImageBase64 = profileImageBase64
        self.dailyGoalMinutes = dailyGoalMinutes
        self.dailyProgressSeconds = dailyProgressSeconds
        self.isEmailVerified = isEmailVerified
        self.isPro = isPro
        self.proPurchasedAt = proPurchasedAt
        self.currentStreak = currentStreak
        self.totalXP = totalXP
        self.accuracyPercent = accuracyPercent
        self.quizzesCompleted = quizzesCompleted
        self.strongestSubject = strongestSubject
    }

    init(data: [String: Any], fallbackEmail: String, fallbackUsername: String, verified: Bool) {
        self.fullName = data["fullName"] as? String ?? fallbackUsername
        self.username = data["username"] as? String ?? fallbackUsername
        self.email = data["email"] as? String ?? fallbackEmail
        self.phone = data["phone"] as? String ?? ""
        self.bio = data["bio"] as? String ?? ""
        self.interests = data["interests"] as? [String] ?? []
        self.profileImagePath = data["profileImagePath"] as? String ?? ""
        self.profileImageURL = data["profileImageURL"] as? String ?? ""
        self.profileImageBase64 = data["profileImageBase64"] as? String ?? ""
        self.dailyGoalMinutes = data["dailyGoalMinutes"] as? Int ?? 10
        self.dailyProgressSeconds = data["dailyProgressSeconds"] as? Int ?? 0
        self.isEmailVerified = data["isEmailVerified"] as? Bool ?? verified
        self.isPro = data["isPro"] as? Bool ?? false
        self.proPurchasedAt = (data["proPurchasedAt"] as? Timestamp)?.dateValue()
        self.currentStreak = data["currentStreak"] as? Int
            ?? data["currentQuizStreak"] as? Int
            ?? 0
        self.totalXP = data["totalXP"] as? Int ?? 0
        self.accuracyPercent = data["accuracyPercent"] as? Int ?? 0
        self.quizzesCompleted = data["quizzesCompleted"] as? Int ?? 0
        self.strongestSubject = data["strongestSubject"] as? String ?? ""
    }

    var dictionary: [String: Any] {
        [
            "fullName": fullName,
            "username": username,
            "email": email,
            "phone": phone,
            "bio": bio,
            "interests": interests,
            "profileImagePath": profileImagePath,
            "profileImageURL": profileImageURL,
            "profileImageBase64": profileImageBase64,
            "dailyGoalMinutes": dailyGoalMinutes,
            "dailyProgressSeconds": dailyProgressSeconds,
            "isEmailVerified": isEmailVerified,
            "isPro": isPro,
            "proPurchasedAt": proPurchasedAt.map { Timestamp(date: $0) } as Any,
            "updatedAt": Timestamp(date: Date())
        ]
    }
}

struct ProfileLevelProgress {
    let level: Int
    let title: String
    let xpInLevel: Int
    let xpToNext: Int
    let levelXP: Int

    var progressRatio: Double {
        guard levelXP > 0 else { return 0 }
        return min(max(Double(xpInLevel) / Double(levelXP), 0), 1)
    }

    static let empty = ProfileLevelProgress(level: 1, title: "Polymath", xpInLevel: 0, xpToNext: 500, levelXP: 500)

    static func from(totalXP: Int) -> ProfileLevelProgress {
        let xpPerLevel = 500
        let safeXP = max(0, totalXP)
        let level = (safeXP / xpPerLevel) + 1
        let xpInLevel = safeXP % xpPerLevel
        let xpToNext = max(0, xpPerLevel - xpInLevel)
        let title = rankTitle(for: level)
        return ProfileLevelProgress(level: level, title: title, xpInLevel: xpInLevel, xpToNext: xpToNext, levelXP: xpPerLevel)
    }

    private static func rankTitle(for level: Int) -> String {
        switch level {
        case 1...4:
            return "Explorer"
        case 5...8:
            return "Scholar"
        case 9...12:
            return "Polymath"
        case 13...16:
            return "Luminary"
        default:
            return "Legend"
        }
    }
}

struct ProfileAchievementItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let colorHex: String
    let isLocked: Bool
}

struct ProfileRecentActivity: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let time: String
    let score: String
    let tag: String
    let colorHex: String
}

@MainActor
final class UserProfileViewModel: ObservableObject {
    @Published var profile: UserProfile = .empty
    @Published var levelProgress: ProfileLevelProgress = .empty
    @Published var recentActivities: [ProfileRecentActivity] = []
    @Published var achievements: [ProfileAchievementItem] = []
    @Published var accuracyTrendText: String = "--"
    @Published var accuracyTrendColorHex: String = "7EF5A8"
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var saveMessage: String?

    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let calendar = Calendar.current
    private let lessonNames: [String: String] = [
        "astronomy": "Astronomy",
        "computer_science": "Computer Science",
        "philosophy": "Philosophy",
        "biology": "Biology",
        "mathematics": "Mathematics"
    ]

    func loadProfile() async {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "User is not signed in."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await user.reload()

            let email = user.email ?? ""
            let username = user.displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
                .nonEmpty ?? email.components(separatedBy: "@").first ?? "Learner"

            let docRef = db.collection("users").document(user.uid)
            let snapshot = try await docRef.getDocument()

            if let data = snapshot.data() {
                profile = UserProfile(
                    data: data,
                    fallbackEmail: email,
                    fallbackUsername: username,
                    verified: user.isEmailVerified
                )
            } else {
                profile = UserProfile(
                    fullName: username,
                    username: username,
                    email: email,
                    phone: "",
                    bio: "",
                    interests: ["General Knowledge"],
                    profileImagePath: "",
                    profileImageURL: "",
                    profileImageBase64: "",
                    dailyGoalMinutes: 10,
                    dailyProgressSeconds: 0,
                    isEmailVerified: user.isEmailVerified
                )

                var seedData = profile.dictionary
                seedData["createdAt"] = Timestamp(date: Date())
                try await docRef.setData(seedData, merge: true)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
        
        // Calculate stats from quiz attempts
        await calculateStats(userId: user.uid)
    }

    func saveProfile() async {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "User is not signed in."
            return
        }

        let trimmedName = profile.fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUsername = profile.username.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            errorMessage = "Full name is required."
            return
        }

        guard !trimmedUsername.isEmpty else {
            errorMessage = "Username is required."
            return
        }

        isSaving = true
        errorMessage = nil
        saveMessage = nil

        do {
            profile.fullName = trimmedName
            profile.username = trimmedUsername
            profile.email = user.email ?? profile.email
            profile.isEmailVerified = user.isEmailVerified

            try await db.collection("users").document(user.uid)
                .setData(profile.dictionary, merge: true)

            let change = user.createProfileChangeRequest()
            change.displayName = profile.username
            try await change.commitChanges()

            saveMessage = "Profile updated successfully."
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    func uploadProfileImage(_ image: UIImage) async {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "User is not signed in."
            return
        }

        guard let data = image.jpegData(compressionQuality: 0.8) else {
            errorMessage = "Failed to process selected image."
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            let fileName = "\(user.uid)_\(Int(Date().timeIntervalSince1970)).jpg"
            let ref = storage.reference().child("profileImages/\(fileName)")
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"

            try await uploadImageData(data, to: ref, metadata: metadata)

            let path = ref.fullPath
            profile.profileImagePath = path

            let url = try? await fetchDownloadURL(for: ref)
            let urlString = url?.absoluteString ?? profile.profileImageURL
            profile.profileImageURL = urlString

            try await db.collection("users").document(user.uid).setData([
                "profileImagePath": path,
                "profileImageURL": urlString,
                "profileImageBase64": "",
                "updatedAt": Timestamp(date: Date())
            ], merge: true)
        } catch {
            // Fallback: persist a compressed base64 avatar directly in Firestore
            // so profile photos still work if Storage is misconfigured.
            if let fallbackData = image.jpegData(compressionQuality: 0.45) {
                let base64 = fallbackData.base64EncodedString()
                profile.profileImageBase64 = base64
                profile.profileImagePath = ""
                profile.profileImageURL = ""

                do {
                    try await db.collection("users").document(user.uid).setData([
                        "profileImageBase64": base64,
                        "profileImagePath": "",
                        "profileImageURL": "",
                        "updatedAt": Timestamp(date: Date())
                    ], merge: true)
                    errorMessage = nil
                } catch {
                    errorMessage = error.localizedDescription
                }
            } else {
                errorMessage = error.localizedDescription
            }
        }

        isSaving = false
    }

    private func uploadImageData(_ data: Data,
                                 to ref: StorageReference,
                                 metadata: StorageMetadata) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ref.putData(data, metadata: metadata) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func fetchDownloadURL(for ref: StorageReference) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            ref.downloadURL { url, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "UserProfileViewModel",
                        code: -2,
                        userInfo: [NSLocalizedDescriptionKey: "Download URL is unavailable."]
                    ))
                }
            }
        }
    }

    private func calculateStats(userId: String) async {
        do {
            let attemptsSnapshot = try await db.collection("users")
                .document(userId)
                .collection("quizAttempts")
                .order(by: "answeredAt", descending: true)
                .limit(to: 300)
                .getDocuments()

            let attempts = attemptsSnapshot.documents.compactMap(parseAttempt)
            let totalAttempts = attempts.count
            let totalCorrect = attempts.filter { $0.isCorrect }.count
            let totalXP = attempts.reduce(0) { $0 + max(0, $1.earnedXP) }
            let accuracy = totalAttempts > 0 ? (totalCorrect * 100) / totalAttempts : 0

            let strongest = strongestSubjectInfo(from: attempts)
            let quizzesCompleted = uniqueSessionCount(from: attempts)
            let currentStreak = currentDailyStreak(from: attempts)

            profile.totalXP = max(profile.totalXP, totalXP)
            profile.accuracyPercent = accuracy
            profile.quizzesCompleted = quizzesCompleted
            profile.currentStreak = currentStreak
            profile.strongestSubject = strongest.name

            levelProgress = ProfileLevelProgress.from(totalXP: profile.totalXP)
            let trend = accuracyTrend(from: attempts, lessonId: strongest.id)
            accuracyTrendText = trend.text
            accuracyTrendColorHex = trend.colorHex
            achievements = buildAchievements(from: attempts, currentStreak: currentStreak)
            recentActivities = buildRecentActivities(from: attempts)

            try await db.collection("users").document(userId).setData([
                "totalXP": profile.totalXP,
                "accuracyPercent": accuracy,
                "quizzesCompleted": quizzesCompleted,
                "currentStreak": currentStreak,
                "strongestSubject": strongest.name,
                "statsUpdatedAt": Timestamp(date: Date())
            ], merge: true)
        } catch {
            print("Failed to calculate stats: \(error.localizedDescription)")
        }
    }

    private func parseAttempt(_ doc: QueryDocumentSnapshot) -> ProfileQuizAttempt? {
        let data = doc.data()
        guard let timestamp = data["answeredAt"] as? Timestamp else { return nil }

        return ProfileQuizAttempt(
            answeredAt: timestamp.dateValue(),
            lessonId: (data["lessonId"] as? String ?? "general").lowercased(),
            isCorrect: data["isCorrect"] as? Bool ?? false,
            earnedXP: data["earnedXP"] as? Int ?? 0,
            timeSpentSeconds: data["timeSpentSeconds"] as? Int ?? 0,
            attemptSessionId: data["attemptSessionId"] as? String ?? doc.documentID
        )
    }

    private func strongestSubjectInfo(from attempts: [ProfileQuizAttempt]) -> (id: String?, name: String) {
        var lessonBuckets: [String: (correct: Int, total: Int)] = [:]
        for attempt in attempts {
            var bucket = lessonBuckets[attempt.lessonId, default: (0, 0)]
            bucket.total += 1
            if attempt.isCorrect { bucket.correct += 1 }
            lessonBuckets[attempt.lessonId] = bucket
        }

        var bestLesson = ""
        var bestAccuracy = 0
        for (lessonId, stats) in lessonBuckets {
            guard stats.total >= 4 else { continue }
            let percent = Int((Double(stats.correct) / Double(stats.total) * 100).rounded())
            if percent > bestAccuracy {
                bestAccuracy = percent
                bestLesson = lessonId
            }
        }

        guard !bestLesson.isEmpty else { return (nil, "") }
        let name = lessonNames[bestLesson] ?? bestLesson.replacingOccurrences(of: "_", with: " ").capitalized
        return (bestLesson, name)
    }

    private func uniqueSessionCount(from attempts: [ProfileQuizAttempt]) -> Int {
        Set(attempts.map { $0.attemptSessionId }).count
    }

    private func currentDailyStreak(from attempts: [ProfileQuizAttempt]) -> Int {
        guard !attempts.isEmpty else { return 0 }

        let days = Set(attempts.map { dayKey($0.answeredAt) })
        let today = dayKey(Date())
        let yesterday = dayKey(calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date())

        var currentDay = days.contains(today) ? today : (days.contains(yesterday) ? yesterday : nil)
        guard let startDay = currentDay else { return 0 }

        var streak = 0
        var cursorDate = dateFromDayKey(startDay)
        while let date = cursorDate {
            let key = dayKey(date)
            if days.contains(key) {
                streak += 1
                cursorDate = calendar.date(byAdding: .day, value: -1, to: date)
            } else {
                break
            }
        }
        return streak
    }

    private func accuracyTrend(from attempts: [ProfileQuizAttempt], lessonId: String?) -> (text: String, colorHex: String) {
        let filtered = lessonId.map { id in attempts.filter { $0.lessonId == id } } ?? attempts
        guard !filtered.isEmpty else { return ("No trend yet", "FFFFFF") }

        let now = Date()
        guard let last7Start = calendar.date(byAdding: .day, value: -6, to: now),
              let prev7Start = calendar.date(byAdding: .day, value: -13, to: now) else {
            return ("No trend yet", "FFFFFF")
        }

        let last7 = filtered.filter { $0.answeredAt >= last7Start }
        let prev7 = filtered.filter { $0.answeredAt < last7Start && $0.answeredAt >= prev7Start }

        guard last7.count >= 4, prev7.count >= 4 else { return ("Needs 2 weeks", "FFFFFF") }

        let lastAccuracy = accuracyPercent(for: last7)
        let prevAccuracy = accuracyPercent(for: prev7)
        let delta = lastAccuracy - prevAccuracy

        if delta == 0 {
            return ("Stable", "71F8AA")
        }

        let sign = delta >= 0 ? "+" : ""
        let text = "\(sign)\(delta)% accuracy"
        let colorHex = delta >= 0 ? "71F8AA" : "FF6B6B"
        return (text, colorHex)
    }

    private func accuracyPercent(for attempts: [ProfileQuizAttempt]) -> Int {
        guard !attempts.isEmpty else { return 0 }
        let correct = attempts.filter { $0.isCorrect }.count
        return Int((Double(correct) / Double(attempts.count) * 100).rounded())
    }

    private func buildAchievements(from attempts: [ProfileQuizAttempt], currentStreak: Int) -> [ProfileAchievementItem] {
        let avgTime = averageTime(for: attempts)
        let nightOwl = percentAfterEight(for: attempts) >= 60 && attempts.count >= 8
        let speedDemon = avgTime > 0 && avgTime <= 45
        let topicMaster = hasTopicMastery(from: attempts)

        return [
            ProfileAchievementItem(icon: "rosette", title: "7-DAY STREAK", colorHex: "F6CC2E", isLocked: currentStreak < 7),
            ProfileAchievementItem(icon: "speedometer", title: "SPEED DEMON", colorHex: "7EF5A8", isLocked: !speedDemon),
            ProfileAchievementItem(icon: "graduationcap.fill", title: "TOPIC MASTER", colorHex: "75DFFF", isLocked: !topicMaster),
            ProfileAchievementItem(icon: "moon", title: "NIGHT OWL", colorHex: nightOwl ? "A58BFF" : "FFFFFF", isLocked: !nightOwl)
        ]
    }

    private func averageTime(for attempts: [ProfileQuizAttempt]) -> Int {
        guard !attempts.isEmpty else { return 0 }
        let total = attempts.reduce(0) { $0 + max(0, $1.timeSpentSeconds) }
        return total / max(attempts.count, 1)
    }

    private func percentAfterEight(for attempts: [ProfileQuizAttempt]) -> Int {
        guard !attempts.isEmpty else { return 0 }
        let afterEight = attempts.filter { calendar.component(.hour, from: $0.answeredAt) >= 20 }.count
        return Int((Double(afterEight) / Double(attempts.count) * 100).rounded())
    }

    private func hasTopicMastery(from attempts: [ProfileQuizAttempt]) -> Bool {
        var totals: [String: (correct: Int, total: Int)] = [:]
        for attempt in attempts {
            var bucket = totals[attempt.lessonId, default: (0, 0)]
            bucket.total += 1
            if attempt.isCorrect { bucket.correct += 1 }
            totals[attempt.lessonId] = bucket
        }

        for stats in totals.values where stats.total >= 6 {
            let percent = Int((Double(stats.correct) / Double(stats.total) * 100).rounded())
            if percent >= 85 { return true }
        }
        return false
    }

    private func buildRecentActivities(from attempts: [ProfileQuizAttempt]) -> [ProfileRecentActivity] {
        guard !attempts.isEmpty else { return [] }

        var sessions: [String: ProfileSessionSummary] = [:]
        for attempt in attempts {
            var summary = sessions[attempt.attemptSessionId] ?? ProfileSessionSummary(lessonId: attempt.lessonId)
            summary.total += 1
            if attempt.isCorrect { summary.correct += 1 }
            if summary.lastAnsweredAt == nil || attempt.answeredAt > summary.lastAnsweredAt! {
                summary.lastAnsweredAt = attempt.answeredAt
            }
            sessions[attempt.attemptSessionId] = summary
        }

        let sorted = sessions.values
            .compactMap { summary -> ProfileActivitySortable? in
                guard let last = summary.lastAnsweredAt else { return nil }
                let percent = summary.total > 0 ? Int((Double(summary.correct) / Double(summary.total) * 100).rounded()) : 0
                let colorHex = scoreColorHex(for: percent)
                let label = scoreLabel(for: percent)
                let lessonName = lessonNames[summary.lessonId] ?? summary.lessonId.replacingOccurrences(of: "_", with: " ").capitalized
                let title = "\(lessonName) Quiz"
                let time = relativeTimeDescription(from: last)
                let activity = ProfileRecentActivity(
                    icon: iconName(for: summary.lessonId),
                    title: title,
                    time: time,
                    score: "\(percent)%",
                    tag: label,
                    colorHex: colorHex
                )
                return ProfileActivitySortable(activity: activity, sortDate: last)
            }
            .sorted { $0.sortDate > $1.sortDate }

        return Array(sorted.prefix(4)).map { $0.activity }
    }

    private func iconName(for lessonId: String) -> String {
        switch lessonId.lowercased() {
        case "astronomy": return "sparkles"
        case "biology": return "leaf"
        case "philosophy": return "brain.head.profile"
        case "mathematics": return "function"
        case "computer_science": return "chevron.left.forwardslash.chevron.right"
        default: return "book.fill"
        }
    }

    private func scoreLabel(for percent: Int) -> String {
        switch percent {
        case 100: return "PERFECT"
        case 85...99: return "GREAT"
        case 70...84: return "SOLID"
        case 50...69: return "KEEP GOING"
        default: return "STARTED"
        }
    }

    private func scoreColorHex(for percent: Int) -> String {
        switch percent {
        case 90...100: return "7EF5A8"
        case 75...89: return "75DFFF"
        case 60...74: return "F6CC2E"
        default: return "FF6B6B"
        }
    }

    private func relativeTimeDescription(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func dateFromDayKey(_ key: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: key)
    }

    private func dayKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}

private struct ProfileQuizAttempt {
    let answeredAt: Date
    let lessonId: String
    let isCorrect: Bool
    let earnedXP: Int
    let timeSpentSeconds: Int
    let attemptSessionId: String
}

private struct ProfileSessionSummary {
    let lessonId: String
    var total: Int = 0
    var correct: Int = 0
    var lastAnsweredAt: Date? = nil
}

private struct ProfileActivitySortable {
    let activity: ProfileRecentActivity
    let sortDate: Date
}
