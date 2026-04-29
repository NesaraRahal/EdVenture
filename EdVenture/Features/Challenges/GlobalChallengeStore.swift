import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

struct GlobalChallenge: Identifiable, Hashable {
    let id: String
    let title: String
    let tag: String
    let subtitle: String
    let description: String
    let lessonId: String
    let xpReward: Int
    let bonusXP: Int
    let questionCount: Int
    let timeLimitSeconds: Int
    let correctAnswersTarget: Int
    let wrongAnswerPenalty: Int
    let isActive: Bool
    let startAt: Date?
    let endAt: Date?
    let gradientColors: [String]
    let strategyTips: [String]

    init(id: String,
         title: String,
         tag: String,
         subtitle: String,
         description: String,
         lessonId: String,
         xpReward: Int,
         bonusXP: Int,
         questionCount: Int,
         timeLimitSeconds: Int,
         correctAnswersTarget: Int,
         wrongAnswerPenalty: Int,
         isActive: Bool,
         startAt: Date? = nil,
         endAt: Date? = nil,
         gradientColors: [String],
         strategyTips: [String]) {
        self.id = id
        self.title = title
        self.tag = tag
        self.subtitle = subtitle
        self.description = description
        self.lessonId = lessonId
        self.xpReward = xpReward
        self.bonusXP = bonusXP
        self.questionCount = questionCount
        self.timeLimitSeconds = timeLimitSeconds
        self.correctAnswersTarget = correctAnswersTarget
        self.wrongAnswerPenalty = wrongAnswerPenalty
        self.isActive = isActive
        self.startAt = startAt
        self.endAt = endAt
        self.gradientColors = gradientColors
        self.strategyTips = strategyTips
    }

    init?(id: String, data: [String: Any]) {
        guard
            let title = data["title"] as? String,
            let tag = data["tag"] as? String,
            let subtitle = data["subtitle"] as? String,
            let description = data["description"] as? String,
            let lessonId = data["lessonId"] as? String
        else { return nil }

        self.id = id
        self.title = title
        self.tag = tag
        self.subtitle = subtitle
        self.description = description
        self.lessonId = lessonId
        self.xpReward = data["xpReward"] as? Int ?? 100
        self.bonusXP = data["bonusXP"] as? Int ?? 0
        self.questionCount = data["questionCount"] as? Int ?? 10
        self.timeLimitSeconds = data["timeLimitSeconds"] as? Int ?? 300
        self.correctAnswersTarget = data["correctAnswersTarget"] as? Int ?? questionCount
        self.wrongAnswerPenalty = data["wrongAnswerPenalty"] as? Int ?? 0
        self.isActive = data["isActive"] as? Bool ?? true
        self.startAt = (data["startAt"] as? Timestamp)?.dateValue()
        self.endAt = (data["endAt"] as? Timestamp)?.dateValue()
        self.gradientColors = data["gradientColors"] as? [String] ?? ["4FC3A1", "3B82C4", "6C63D8"]
        self.strategyTips = data["strategyTips"] as? [String] ?? [
            "Answer quickly, but don't sacrifice accuracy.",
            "Use the first 10 seconds to scan the question for its keyword.",
            "Skip and return if a question feels too risky.",
            "Consistency beats guessing; protect your accuracy bonus."
        ]
    }

    var isCurrentlyActive: Bool {
        let now = Date()
        if !isActive { return false }
        if let startAt, startAt > now { return false }
        if let endAt, endAt < now { return false }
        return true
    }

    var rewardSummary: String {
        let total = xpReward + bonusXP
        return "\(total) XP"
    }

    var timeLimitSummary: String {
        let minutes = max(1, timeLimitSeconds / 60)
        return "\(minutes)m"
    }

    var rankRuleSummary: String {
        "Ranked by accuracy first, then completion time."
    }

    var gradient: [String] {
        gradientColors.count >= 3 ? gradientColors : ["4FC3A1", "3B82C4", "6C63D8"]
    }
}

struct GlobalChallengeLeaderboardEntry: Identifiable, Hashable {
    let id: String
    let userId: String
    let displayName: String
    let correctCount: Int
    let totalQuestions: Int
    let accuracyPercent: Int
    let timeSpentSeconds: Int
    let earnedXP: Int
    let rankingScore: Int
    let completedAt: Date
    let profileImageUrl: String?
    let profileImageBase64: String?

    init(id: String,
         userId: String,
         displayName: String,
         correctCount: Int,
         totalQuestions: Int,
         accuracyPercent: Int,
         timeSpentSeconds: Int,
         earnedXP: Int,
         rankingScore: Int,
         completedAt: Date,
         profileImageUrl: String? = nil,
         profileImageBase64: String? = nil) {
        self.id = id
        self.userId = userId
        self.displayName = displayName
        self.correctCount = correctCount
        self.totalQuestions = totalQuestions
        self.accuracyPercent = accuracyPercent
        self.timeSpentSeconds = timeSpentSeconds
        self.earnedXP = earnedXP
        self.rankingScore = rankingScore
        self.completedAt = completedAt
        self.profileImageUrl = profileImageUrl
        self.profileImageBase64 = profileImageBase64
    }

    init?(id: String, data: [String: Any]) {
        guard let userId = data["userId"] as? String else { return nil }
        self.init(
            id: id,
            userId: userId,
            displayName: data["displayName"] as? String ?? "Learner",
            correctCount: data["correctCount"] as? Int ?? 0,
            totalQuestions: data["totalQuestions"] as? Int ?? 0,
            accuracyPercent: data["accuracyPercent"] as? Int ?? 0,
            timeSpentSeconds: data["timeSpentSeconds"] as? Int ?? 0,
            earnedXP: data["earnedXP"] as? Int ?? 0,
            rankingScore: data["rankingScore"] as? Int ?? 0,
            completedAt: (data["completedAt"] as? Timestamp)?.dateValue() ?? Date(),
            profileImageUrl: data["profileImagePath"] as? String
                ?? data["profileImageURL"] as? String
                ?? data["profileImageUrl"] as? String,
            profileImageBase64: data["profileImageBase64"] as? String
        )
    }

    func withProfileImage(source: String?, base64: String?) -> GlobalChallengeLeaderboardEntry {
        GlobalChallengeLeaderboardEntry(
            id: id,
            userId: userId,
            displayName: displayName,
            correctCount: correctCount,
            totalQuestions: totalQuestions,
            accuracyPercent: accuracyPercent,
            timeSpentSeconds: timeSpentSeconds,
            earnedXP: earnedXP,
            rankingScore: rankingScore,
            completedAt: completedAt,
            profileImageUrl: source,
            profileImageBase64: base64
        )
    }
}

final class GlobalChallengeStore {
    private let db = Firestore.firestore()

    static let seededChallenges: [GlobalChallenge] = [
        GlobalChallenge(
            id: "weekly-neuro-sync-drift",
            title: "NEURO-SYNC\nDRIFT",
            tag: "TIMED CHALLENGE",
            subtitle: "Synchronize your neural pathways in this high-intensity cognitive race.",
            description: "Answer the week’s curated quiz set with accuracy and speed to climb the global board.",
            lessonId: "astronomy",
            xpReward: 120,
            bonusXP: 80,
            questionCount: 10,
            timeLimitSeconds: 420,
            correctAnswersTarget: 8,
            wrongAnswerPenalty: 0,
            isActive: true,
            gradientColors: ["4FC3A1", "3B82C4", "6C63D8"],
            strategyTips: [
                "Keep your accuracy above 80% to stay competitive.",
                "Complete the full set before the weekly reset.",
                "Answer quickly, but protect your streak bonus.",
                "Use the first pass to lock in easy points, then move on."
            ]
        ),
        GlobalChallenge(
            id: "weekly-quantum-leap",
            title: "QUANTUM\nLEAP",
            tag: "DAILY QUEST",
            subtitle: "Push your limits across logic, memory and spatial reasoning.",
            description: "A global accuracy sprint where every correct answer pushes you higher in the weekly rankings.",
            lessonId: "mathematics",
            xpReward: 100,
            bonusXP: 60,
            questionCount: 8,
            timeLimitSeconds: 360,
            correctAnswersTarget: 7,
            wrongAnswerPenalty: 0,
            isActive: true,
            gradientColors: ["F59E0B", "EF4444", "8B5CF6"],
            strategyTips: [
                "Accuracy outranks raw speed on the leaderboard.",
                "Skip any question that risks a wrong answer penalty.",
                "Use momentum: keep your streak alive.",
                "Finish with enough time left to secure a top rank."
            ]
        ),
        GlobalChallenge(
            id: "weekly-flash-facts",
            title: "FLASH\nFACTS",
            tag: "SPEED RUN",
            subtitle: "60 seconds. 20 questions. How fast can your brain fire?",
            description: "A speed-focused event with XP bonuses for rapid, accurate answers and a global race clock.",
            lessonId: "computer_science",
            xpReward: 90,
            bonusXP: 90,
            questionCount: 20,
            timeLimitSeconds: 300,
            correctAnswersTarget: 15,
            wrongAnswerPenalty: 0,
            isActive: true,
            gradientColors: ["10B981", "059669", "0EB060"],
            strategyTips: [
                "Short answers win this event.",
                "Move fast, but don’t sacrifice clean accuracy.",
                "The final ranking favors correct answers first.",
                "Use the easiest questions to build a lead."
            ]
        )
    ]

    func fallbackChallenge(id: String) -> GlobalChallenge {
        if let seeded = Self.seededChallenges.first(where: { $0.id == id }) {
            return seeded
        }
        return Self.seededChallenges.first!
    }

    func challengeQuestions(for challenge: GlobalChallenge) -> [EVQuizQuestion] {
        GlobalChallengeQuestionBank.questions(for: challenge.id)
    }

    func loadActiveChallenges() async throws -> [GlobalChallenge] {
        let snapshot = try await db.collection("globalChallenges").getDocuments()
        let loaded = snapshot.documents.compactMap { doc in
            GlobalChallenge(id: doc.documentID, data: doc.data())
        }
        .filter { $0.isCurrentlyActive }
        .sorted { lhs, rhs in
            if lhs.startAt == rhs.startAt {
                return lhs.id < rhs.id
            }
            return (lhs.startAt ?? .distantPast) > (rhs.startAt ?? .distantPast)
        }

        return loaded.isEmpty ? Self.seededChallenges : loaded
    }

    func loadChallenge(id: String) async throws -> GlobalChallenge? {
        let snapshot = try await db.collection("globalChallenges").document(id).getDocument()
        guard let data = snapshot.data() else {
            return fallbackChallenge(id: id)
        }
        return GlobalChallenge(id: snapshot.documentID, data: data) ?? fallbackChallenge(id: id)
    }

    func loadLeaderboard(challengeId: String, limit: Int = 10) async throws -> [GlobalChallengeLeaderboardEntry] {
        let snapshot = try await db.collection("globalChallenges")
            .document(challengeId)
            .collection("leaderboard")
            .getDocuments()

        let baseEntries = snapshot.documents.compactMap { doc in
            GlobalChallengeLeaderboardEntry(id: doc.documentID, data: doc.data())
        }

        let uidList = baseEntries.map(\.userId)
        let profilesByUid = await loadProfileAssetsByUid(uids: uidList)

        let enriched = baseEntries.map { entry in
            guard let asset = profilesByUid[entry.userId] else { return entry }
            let hasSource = (entry.profileImageUrl?.isEmpty == false)
            let hasBase64 = (entry.profileImageBase64?.isEmpty == false)
            if hasSource || hasBase64 { return entry }
            return entry.withProfileImage(source: asset.source, base64: asset.base64)
        }

        return enriched
            .sorted { lhs, rhs in
                if lhs.earnedXP == rhs.earnedXP {
                    if lhs.accuracyPercent == rhs.accuracyPercent {
                        return lhs.timeSpentSeconds < rhs.timeSpentSeconds
                    }
                    return lhs.accuracyPercent > rhs.accuracyPercent
                }
                return lhs.earnedXP > rhs.earnedXP
            }
            .prefix(limit)
            .map { $0 }
    }

    private func loadProfileAssetsByUid(uids: [String]) async -> [String: (source: String?, base64: String?)] {
        guard !uids.isEmpty else { return [:] }

        var result: [String: (source: String?, base64: String?)] = [:]

        for uid in uids {
            do {
                let snapshot = try await db.collection("users").document(uid).getDocument()
                guard let data = snapshot.data() else { continue }

                let source = (data["profileImagePath"] as? String)
                    ?? (data["profileImageURL"] as? String)
                    ?? (data["profileImageUrl"] as? String)
                let base64 = data["profileImageBase64"] as? String

                let hasSource = source?.isEmpty == false
                let hasBase64 = base64?.isEmpty == false
                if hasSource || hasBase64 {
                    result[uid] = (source, base64)
                }
            } catch {
                continue
            }
        }

        return result
    }

    func recordCompletion(challenge: GlobalChallenge,
                          userId: String,
                          displayName: String,
                          score: Int,
                          totalQuestions: Int,
                          earnedXP: Int,
                          timeSpentSeconds: Int,
                          attemptSessionId: String) async throws {
        let correctCount = max(0, min(score, totalQuestions))
        let accuracyPercent = totalQuestions > 0 ? Int((Double(correctCount) / Double(totalQuestions)) * 100.0) : 0
        let remainingTimeBonus = max(0, challenge.timeLimitSeconds - timeSpentSeconds)
        let rankingScore = (correctCount * 10_000) + (accuracyPercent * 100) + remainingTimeBonus + earnedXP
        let completionXP = earnedXP + challenge.bonusXP
        let now = Date()

        let batch = db.batch()
        let userRef = db.collection("users").document(userId)
        let challengeRef = db.collection("globalChallenges").document(challenge.id)
        let leaderboardRef = challengeRef.collection("leaderboard").document(userId)
        let attemptsRef = challengeRef.collection("attempts").document()

        batch.setData([
            "challengeId": challenge.id,
            "userId": userId,
            "displayName": displayName,
            "correctCount": correctCount,
            "totalQuestions": totalQuestions,
            "accuracyPercent": accuracyPercent,
            "timeSpentSeconds": timeSpentSeconds,
            "earnedXP": earnedXP,
            "bonusXP": challenge.bonusXP,
            "rankingScore": rankingScore,
            "attemptSessionId": attemptSessionId,
            "completedAt": Timestamp(date: now),
            "updatedAt": Timestamp(date: now)
        ], forDocument: leaderboardRef, merge: true)

        batch.setData([
            "challengeId": challenge.id,
            "userId": userId,
            "displayName": displayName,
            "score": score,
            "totalQuestions": totalQuestions,
            "earnedXP": earnedXP,
            "bonusXP": challenge.bonusXP,
            "timeSpentSeconds": timeSpentSeconds,
            "accuracyPercent": accuracyPercent,
            "rankingScore": rankingScore,
            "attemptSessionId": attemptSessionId,
            "completedAt": Timestamp(date: now)
        ], forDocument: attemptsRef, merge: false)

        batch.setData([
            "globalChallengeXP": FieldValue.increment(Int64(completionXP)),
            "globalChallengeCompletions": FieldValue.increment(Int64(1)),
            "updatedAt": Timestamp(date: now)
        ], forDocument: userRef, merge: true)

        try await batch.commit()
    }
}
