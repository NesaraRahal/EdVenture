import Foundation
import FirebaseAuth
import FirebaseFirestore

struct EVQuizQuestion: Identifiable, Hashable {
    let id: String
    let lessonId: String
    let level: Int
    let order: Int
    let difficulty: Int
    let xpMin: Int
    let xpMax: Int
    let xpSuggested: Int
    let prompt: String
    let choices: [String]
    let correctIndex: Int
    let explanation: String
    let tags: [String]
    let isActive: Bool

    init?(id: String, data: [String: Any]) {
        guard
            let lessonId = data["lessonId"] as? String,
            let level = data["level"] as? Int,
            let order = data["order"] as? Int,
            let difficulty = data["difficulty"] as? Int,
            let xpMin = data["xpMin"] as? Int,
            let xpMax = data["xpMax"] as? Int,
            let xpSuggested = data["xpSuggested"] as? Int,
            let prompt = data["prompt"] as? String,
            let choices = data["choices"] as? [String],
            let correctIndex = data["correctIndex"] as? Int,
            let explanation = data["explanation"] as? String
        else { return nil }

        self.id = id
        self.lessonId = lessonId
        self.level = level
        self.order = order
        self.difficulty = difficulty
        self.xpMin = xpMin
        self.xpMax = xpMax
        self.xpSuggested = xpSuggested
        self.prompt = prompt
        self.choices = choices
        self.correctIndex = correctIndex
        self.explanation = explanation
        self.tags = data["tags"] as? [String] ?? []
        self.isActive = data["isActive"] as? Bool ?? true

        guard choices.indices.contains(correctIndex) else { return nil }
    }

    init(id: String,
         lessonId: String,
         level: Int,
         order: Int,
         difficulty: Int,
         xpMin: Int,
         xpMax: Int,
         xpSuggested: Int,
         prompt: String,
         choices: [String],
         correctIndex: Int,
         explanation: String,
         tags: [String] = [],
         isActive: Bool = true) {
        precondition(choices.indices.contains(correctIndex), "correctIndex must point to a valid choice")

        self.id = id
        self.lessonId = lessonId
        self.level = level
        self.order = order
        self.difficulty = difficulty
        self.xpMin = xpMin
        self.xpMax = xpMax
        self.xpSuggested = xpSuggested
        self.prompt = prompt
        self.choices = choices
        self.correctIndex = correctIndex
        self.explanation = explanation
        self.tags = tags
        self.isActive = isActive
    }
}

struct EVQuizSessionState {
    let lessonId: String
    let level: Int
    var unlockedCount: Int
    var consecutiveWins: Int
    var correctInWindow: Int
    var windowStartsAt: Date
    var lockedUntil: Date?
    var totalXP: Int
    var attemptedCount: Int
    var currentQuestionIndex: Int
    var completedQuestionIDs: [String]

    static func initial(lessonId: String, level: Int, totalQuestions: Int) -> EVQuizSessionState {
        EVQuizSessionState(
            lessonId: lessonId,
            level: level,
            unlockedCount: max(totalQuestions, 1),
            consecutiveWins: 0,
            correctInWindow: 0,
            windowStartsAt: Date(),
            lockedUntil: nil,
            totalXP: 0,
            attemptedCount: 0,
            currentQuestionIndex: 0,
            completedQuestionIDs: []
        )
    }

    var nextQuestionIndex: Int {
        currentQuestionIndex + 1
    }

    var isLocked: Bool {
        if let lockedUntil {
            return lockedUntil > Date()
        }
        return false
    }

    func withLoadedWindow(now: Date = Date()) -> EVQuizSessionState {
        var copy = self
        if copy.windowStartsAt.addingTimeInterval(3600) <= now {
            copy.windowStartsAt = now
            copy.correctInWindow = 0
        }
        if let lockedUntil, lockedUntil <= now {
            copy.lockedUntil = nil
        }
        return copy
    }

    mutating func applyCorrectAnswer(questionId: String,
                                     xpEarned: Int,
                                     totalQuestions: Int,
                                     now: Date = Date()) {
        attemptedCount += 1
        totalXP += xpEarned
        consecutiveWins += 1
        correctInWindow += 1
        completedQuestionIDs.append(questionId)

        unlockedCount = max(totalQuestions, 1)
    }

    mutating func applyWrongAnswer(now: Date = Date()) {
        attemptedCount += 1
        consecutiveWins = 0
        lockedUntil = nil
    }

    var dictionary: [String: Any] {
        [
            "lessonId": lessonId,
            "level": level,
            "unlockedCount": unlockedCount,
            "consecutiveWins": consecutiveWins,
            "correctInWindow": correctInWindow,
            "windowStartsAt": Timestamp(date: windowStartsAt),
            "lockedUntil": lockedUntil.map { Timestamp(date: $0) } as Any,
            "totalXP": totalXP,
            "attemptedCount": attemptedCount,
            "currentQuestionIndex": currentQuestionIndex,
            "completedQuestionIDs": completedQuestionIDs,
            "updatedAt": Timestamp(date: Date())
        ]
    }
}

struct EVQuizRoundResult {
    let isCorrect: Bool
    let earnedXP: Int
    let nextUnlockedCount: Int
    let lockUntil: Date?
    let updatedSession: EVQuizSessionState
}

final class EVQuizStore {
    private let db = Firestore.firestore()

    func loadLevelQuestions(lessonId: String, level: Int) async throws -> [EVQuizQuestion] {
        let snapshot = try await db
            .collection("lessons")
            .document(lessonId)
            .collection("questions")
            .getDocuments()

        let questions = snapshot.documents.compactMap { doc in
            var data = doc.data()

            // Backward compatibility: older question docs in this project
            // may not contain lessonId/order/difficulty fields.
            if data["lessonId"] == nil {
                data["lessonId"] = lessonId
            }

            if let (parsedLevel, parsedOrder) = parseLevelOrder(from: doc.documentID) {
                if data["level"] == nil {
                    data["level"] = parsedLevel
                }
                if data["order"] == nil {
                    data["order"] = parsedOrder
                }
                if data["difficulty"] == nil {
                    data["difficulty"] = (parsedLevel - 1) * 10 + parsedOrder
                }
            }

            return EVQuizQuestion(id: doc.documentID, data: data)
        }
        .filter { question in
            question.level == level && question.isActive
        }

        return questions.shuffledByDifficulty()
    }

    private func parseLevelOrder(from questionId: String) -> (level: Int, order: Int)? {
        // Expected format: <lesson>_L01_Q01
        let pattern = #"_L(\d+)_Q(\d+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let range = NSRange(questionId.startIndex..<questionId.endIndex, in: questionId)
        guard let match = regex.firstMatch(in: questionId, options: [], range: range),
              let levelRange = Range(match.range(at: 1), in: questionId),
              let orderRange = Range(match.range(at: 2), in: questionId),
              let level = Int(questionId[levelRange]),
              let order = Int(questionId[orderRange])
        else {
            return nil
        }

        return (level, order)
    }

    func loadSession(userId: String, lessonId: String, level: Int, totalQuestions: Int) async throws -> EVQuizSessionState {
        let ref = db.collection("users").document(userId).collection("quizSessions").document(lessonId)
        let snapshot = try await ref.getDocument()

        guard let data = snapshot.data() else {
            return EVQuizSessionState.initial(lessonId: lessonId, level: level, totalQuestions: totalQuestions)
        }

        let unlockedCount = data["unlockedCount"] as? Int ?? max(totalQuestions, 1)
        let consecutiveWins = data["consecutiveWins"] as? Int ?? 0
        let correctInWindow = data["correctInWindow"] as? Int ?? 0
        let windowStartsAt = (data["windowStartsAt"] as? Timestamp)?.dateValue() ?? Date()
        let lockedUntil = (data["lockedUntil"] as? Timestamp)?.dateValue()
        let totalXP = data["totalXP"] as? Int ?? 0
        let attemptedCount = data["attemptedCount"] as? Int ?? 0
        let currentQuestionIndex = data["currentQuestionIndex"] as? Int ?? 0
        let completedQuestionIDs = data["completedQuestionIDs"] as? [String] ?? []

        return EVQuizSessionState(
            lessonId: lessonId,
            level: level,
            unlockedCount: min(totalQuestions, max(1, unlockedCount)),
            consecutiveWins: consecutiveWins,
            correctInWindow: correctInWindow,
            windowStartsAt: windowStartsAt,
            lockedUntil: lockedUntil,
            totalXP: totalXP,
            attemptedCount: attemptedCount,
            currentQuestionIndex: min(max(0, currentQuestionIndex), max(totalQuestions - 1, 0)),
            completedQuestionIDs: completedQuestionIDs
        ).withLoadedWindow()
    }

    func persistSession(userId: String, session: EVQuizSessionState) async throws {
        try await db.collection("users").document(userId)
            .collection("quizSessions").document(session.lessonId)
            .setData(session.dictionary, merge: true)
    }

    func submitRound(userId: String,
                     displayName: String,
                     session: EVQuizSessionState,
                     question: EVQuizQuestion,
                     selectedIndex: Int,
                     attemptSessionId: String,
                     timeSpentSeconds: Int,
                     questionIndex: Int,
                     totalQuestions: Int) async throws -> EVQuizRoundResult {
        var updatedSession = session.withLoadedWindow()
        let now = Date()
        let isCorrect = selectedIndex == question.correctIndex
        let earnedXP = isCorrect ? question.xpSuggested : 0

        if isCorrect {
            updatedSession.applyCorrectAnswer(
                questionId: question.id,
                xpEarned: earnedXP,
                totalQuestions: max(totalQuestions, 1),
                now: now
            )
        } else {
            updatedSession.applyWrongAnswer(now: now)
        }

        updatedSession.currentQuestionIndex = max(0, questionIndex)
        let safeTimeSpent = max(0, timeSpentSeconds)

        let userRef = db.collection("users").document(userId)
        let (dailyGoalMinutes, updatedDailyProgressSeconds, didReachDailyGoalNow, isDailyGoalCompleted) = try await computeDailyGoalUpdate(
            userRef: userRef,
            incrementSeconds: safeTimeSpent,
            now: now
        )
        let sessionRef = userRef.collection("quizSessions").document(session.lessonId)
        let attemptRef = userRef.collection("quizAttempts").document()
        let activeLessonRef = userRef.collection("activeLessons").document(session.lessonId)
        let questionProgressRef = userRef
            .collection("activeLessons")
            .document(session.lessonId)
            .collection("questions")
            .document(question.id)
        let leaderboardRef = db.collection("leaderboards").document("global").collection("entries").document(userId)
        let streakValue: Any = isCorrect ? FieldValue.increment(Int64(1)) : 0
        let uniqueCompleted = Set(updatedSession.completedQuestionIDs)
        let completedCount = uniqueCompleted.count
        let normalizedTotal = max(totalQuestions, 1)
        let progress = min(Double(completedCount) / Double(normalizedTotal), 1.0)
        let levelCompleted = completedCount >= normalizedTotal

        let batch = db.batch()
        batch.setData([
            "totalXP": FieldValue.increment(Int64(earnedXP)),
            "quizXP": FieldValue.increment(Int64(earnedXP)),
            "totalPlaySeconds": FieldValue.increment(Int64(safeTimeSpent)),
            "totalQuizRounds": FieldValue.increment(Int64(1)),
            "dailyGoalMinutes": dailyGoalMinutes,
            "dailyProgressDate": dayKey(now),
            "dailyProgressSeconds": updatedDailyProgressSeconds,
            "dailyGoalCompleted": isDailyGoalCompleted,
            "dailyGoalCompletedAt": isDailyGoalCompleted ? Timestamp(date: now) : FieldValue.delete(),
            "currentQuizStreak": streakValue,
            "updatedAt": Timestamp(date: now)
        ], forDocument: userRef, merge: true)

        batch.setData(updatedSession.dictionary, forDocument: sessionRef, merge: true)
        batch.setData([
            "lessonId": session.lessonId,
            "progress": progress,
            "completedQuestionIDs": Array(uniqueCompleted),
            "completedQuestionsCount": completedCount,
            "totalQuestions": normalizedTotal,
            "isCompleted": levelCompleted,
            "lastQuestionIndex": questionIndex,
            "updatedAt": Timestamp(date: now),
            "completedAt": levelCompleted ? Timestamp(date: now) : FieldValue.delete()
        ], forDocument: activeLessonRef, merge: true)
        batch.setData([
            "questionId": question.id,
            "questionIndex": questionIndex,
            "isCompleted": isCorrect,
            "answeredAt": Timestamp(date: now),
            "updatedAt": Timestamp(date: now)
        ], forDocument: questionProgressRef, merge: true)
        batch.setData([
            "attemptSessionId": attemptSessionId,
            "lessonId": session.lessonId,
            "level": session.level,
            "questionId": question.id,
            "questionIndex": questionIndex,
            "selectedIndex": selectedIndex,
            "correctIndex": question.correctIndex,
            "isCorrect": isCorrect,
            "earnedXP": earnedXP,
            "timeSpentSeconds": safeTimeSpent,
            "answeredAt": Timestamp(date: now),
            "createdAt": Timestamp(date: now)
        ], forDocument: attemptRef, merge: false)
        batch.setData([
            "uid": userId,
            "displayName": displayName,
            "totalXP": FieldValue.increment(Int64(earnedXP)),
            "quizXP": FieldValue.increment(Int64(earnedXP)),
            "totalPlaySeconds": FieldValue.increment(Int64(safeTimeSpent)),
            "totalQuizRounds": FieldValue.increment(Int64(1)),
            "lastLessonId": session.lessonId,
            "lastLevel": session.level,
            "streak": updatedSession.consecutiveWins,
            "updatedAt": Timestamp(date: now)
        ], forDocument: leaderboardRef, merge: true)
        try await batch.commit()

        if didReachDailyGoalNow {
            await EVNotificationService.shared.sendDailyGoalCompletedNotification(goalMinutes: dailyGoalMinutes)
        }

        await EVNotificationService.shared.updateDailyGoalReminder(
            goalMinutes: dailyGoalMinutes,
            progressSeconds: updatedDailyProgressSeconds,
            completed: isDailyGoalCompleted
        )

        return EVQuizRoundResult(
            isCorrect: isCorrect,
            earnedXP: earnedXP,
            nextUnlockedCount: updatedSession.unlockedCount,
            lockUntil: updatedSession.lockedUntil,
            updatedSession: updatedSession
        )
    }

    private func computeDailyGoalUpdate(userRef: DocumentReference,
                                        incrementSeconds: Int,
                                        now: Date) async throws -> (Int, Int, Bool, Bool) {
        let snapshot = try await userRef.getDocument()
        let data = snapshot.data() ?? [:]

        let goalMinutes = max(1, data["dailyGoalMinutes"] as? Int ?? 10)
        let today = dayKey(now)
        let storedDay = data["dailyProgressDate"] as? String ?? today
        let priorProgress = storedDay == today ? (data["dailyProgressSeconds"] as? Int ?? 0) : 0
        let wasCompleted = storedDay == today ? (data["dailyGoalCompleted"] as? Bool ?? false) : false

        let updatedProgress = max(0, priorProgress + incrementSeconds)
        let completed = updatedProgress >= goalMinutes * 60
        let reachedNow = !wasCompleted && completed

        return (goalMinutes, updatedProgress, reachedNow, completed)
    }

    private func dayKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

private extension Array where Element == EVQuizQuestion {
    func shuffledByDifficulty() -> [EVQuizQuestion] {
        let sorted = sorted { lhs, rhs in
            if lhs.difficulty == rhs.difficulty {
                return lhs.order < rhs.order
            }
            return lhs.difficulty < rhs.difficulty
        }

        let bucketSize = 10
        var result: [EVQuizQuestion] = []
        var index = 0

        while index < sorted.count {
            let upperBound = Swift.min(index + bucketSize, sorted.count)
            let bucket = Array(sorted[index..<upperBound])
            result.append(contentsOf: bucket.shuffled())
            index = upperBound
        }

        return result
    }
}
