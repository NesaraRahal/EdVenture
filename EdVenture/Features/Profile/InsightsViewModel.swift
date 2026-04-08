import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

struct InsightsSubjectProficiency: Identifiable {
    let id: String
    let name: String
    let value: Int
}

struct InsightsWeeklyXP: Identifiable {
    let id: String
    let day: String
    let value: CGFloat
}

@MainActor
final class InsightsViewModel: ObservableObject {
    @Published var consistencyCells: [Double] = Array(repeating: 0, count: 180)
    @Published var proficiencyRows: [InsightsSubjectProficiency] = []
    @Published var weeklyXP: [InsightsWeeklyXP] = []
    @Published var rhythmType: String = "Balanced learner"
    @Published var afterEightPercent: Int = 0
    @Published var peakFocusTime: String = "--:--"
    @Published var isLoading = false

    private let db = Firestore.firestore()
    private let calendar = Calendar.current
    private let lessonOrder = ["astronomy", "computer_science", "philosophy", "biology", "mathematics"]
    private let lessonNames: [String: String] = [
        "astronomy": "Astronomy",
        "computer_science": "Computer Science",
        "philosophy": "Philosophy",
        "biology": "Biology",
        "mathematics": "Mathematics"
    ]

    func loadInsights() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            resetToEmpty()
            return
        }

        isLoading = true
        defer { isLoading = false }

        let today = calendar.startOfDay(for: Date())
        guard let start180 = calendar.date(byAdding: .day, value: -179, to: today),
              let start7 = calendar.date(byAdding: .day, value: -6, to: today)
        else {
            resetToEmpty()
            return
        }

        do {
            let snapshot = try await db
                .collection("users")
                .document(uid)
                .collection("quizAttempts")
                .whereField("answeredAt", isGreaterThanOrEqualTo: Timestamp(date: start180))
                .order(by: "answeredAt", descending: false)
                .getDocuments()

            let attempts = snapshot.documents.compactMap(parseAttempt)

            buildConsistency(attempts: attempts, start: start180)
            buildSubjectProficiency(attempts: attempts)
            buildWeeklyXP(attempts: attempts, start7: start7)
            buildDailyRhythm(attempts: attempts)
        } catch {
            resetToEmpty()
        }
    }

    private func parseAttempt(_ doc: QueryDocumentSnapshot) -> QuizAttempt? {
        let data = doc.data()
        guard let timestamp = data["answeredAt"] as? Timestamp else { return nil }

        return QuizAttempt(
            answeredAt: timestamp.dateValue(),
            lessonId: (data["lessonId"] as? String ?? "general").lowercased(),
            isCorrect: data["isCorrect"] as? Bool ?? false,
            earnedXP: data["earnedXP"] as? Int ?? 0
        )
    }

    private func buildConsistency(attempts: [QuizAttempt], start: Date) {
        var countsByDay: [Date: Int] = [:]
        for attempt in attempts {
            let day = calendar.startOfDay(for: attempt.answeredAt)
            countsByDay[day, default: 0] += 1
        }

        let maxCount = countsByDay.values.max() ?? 0
        consistencyCells = (0..<180).map { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start),
                  maxCount > 0
            else {
                return 0
            }

            let count = countsByDay[date, default: 0]
            let normalized = Double(count) / Double(maxCount)
            return min(max(normalized, 0), 1)
        }
    }

    private func buildSubjectProficiency(attempts: [QuizAttempt]) {
        var totals: [String: (total: Int, correct: Int)] = [:]

        for attempt in attempts {
            var bucket = totals[attempt.lessonId, default: (0, 0)]
            bucket.total += 1
            if attempt.isCorrect { bucket.correct += 1 }
            totals[attempt.lessonId] = bucket
        }

        let prioritizedLessons = lessonOrder + totals.keys.filter { !lessonOrder.contains($0) }
        proficiencyRows = prioritizedLessons
            .prefix(4)
            .map { lessonId in
                let bucket = totals[lessonId, default: (0, 0)]
                let percent = bucket.total > 0 ? Int((Double(bucket.correct) / Double(bucket.total) * 100).rounded()) : 0
                return InsightsSubjectProficiency(
                    id: lessonId,
                    name: lessonNames[lessonId] ?? lessonId.replacingOccurrences(of: "_", with: " ").capitalized,
                    value: percent
                )
            }
    }

    private func buildWeeklyXP(attempts: [QuizAttempt], start7: Date) {
        var xpByDay: [Date: Int] = [:]
        for attempt in attempts where attempt.answeredAt >= start7 {
            let day = calendar.startOfDay(for: attempt.answeredAt)
            xpByDay[day, default: 0] += max(0, attempt.earnedXP)
        }

        var days: [(label: String, xp: Int)] = []
        for offset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: start7) else { continue }
            let label = weekdayLabel(from: date)
            days.append((label, xpByDay[calendar.startOfDay(for: date), default: 0]))
        }

        let maxXP = max(days.map(\.xp).max() ?? 0, 1)
        weeklyXP = days.map { point in
            InsightsWeeklyXP(
                id: point.label,
                day: point.label,
                value: CGFloat(Double(point.xp) / Double(maxXP))
            )
        }
    }

    private func buildDailyRhythm(attempts: [QuizAttempt]) {
        guard !attempts.isEmpty else {
            rhythmType = "Balanced learner"
            afterEightPercent = 0
            peakFocusTime = "--:--"
            return
        }

        var afterEightCount = 0
        var hourBuckets: [Int: Int] = [:]

        for attempt in attempts {
            let hour = calendar.component(.hour, from: attempt.answeredAt)
            hourBuckets[hour, default: 0] += 1
            if hour >= 20 { afterEightCount += 1 }
        }

        let total = attempts.count
        let percent = Int((Double(afterEightCount) / Double(total) * 100).rounded())
        afterEightPercent = max(0, min(100, percent))

        if afterEightPercent >= 60 {
            rhythmType = "Night owl"
        } else if afterEightPercent <= 25 {
            rhythmType = "Early bird"
        } else {
            rhythmType = "Balanced learner"
        }

        if let topHour = hourBuckets.max(by: { $0.value < $1.value })?.key,
           let date = calendar.date(from: DateComponents(hour: topHour, minute: 0)) {
            let formatter = DateFormatter()
            formatter.dateFormat = "hh:mm a"
            peakFocusTime = formatter.string(from: date)
        } else {
            peakFocusTime = "--:--"
        }
    }

    private func weekdayLabel(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    private func resetToEmpty() {
        consistencyCells = Array(repeating: 0, count: 180)
        proficiencyRows = lessonOrder.prefix(4).map { lessonId in
            InsightsSubjectProficiency(
                id: lessonId,
                name: lessonNames[lessonId] ?? lessonId.capitalized,
                value: 0
            )
        }
        weeklyXP = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"].map {
            InsightsWeeklyXP(id: $0, day: $0, value: 0)
        }
        rhythmType = "Balanced learner"
        afterEightPercent = 0
        peakFocusTime = "--:--"
    }
}

private struct QuizAttempt {
    let answeredAt: Date
    let lessonId: String
    let isCorrect: Bool
    let earnedXP: Int
}
