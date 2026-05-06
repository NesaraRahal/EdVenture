import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

struct LevelSummaryView: View {
    let lessonId: String
    let level: Int
    let totalLevels: Int
    let score: Int
    let totalQuestions: Int
    let earnedXP: Int
    let totalTimeSeconds: Int

    var onBackToLesson: (() -> Void)?
    var onReviewAnswers: (() -> Void)?
    var onProgressToNextLevel: (() -> Void)?
    var onReturnHome: (() -> Void)?

    @StateObject private var vm = LevelSummaryViewModel()

    private var lessonDisplayName: String {
        lessonId.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private var scoreRatio: Double {
        guard totalQuestions > 0 else { return 0 }
        return min(max(Double(score) / Double(totalQuestions), 0), 1)
    }

    private var scoreText: String {
        "\(score)/\(totalQuestions)"
    }

    private var timeDisplay: String {
        let safe = max(totalTimeSeconds, 0)
        let minutes = safe / 60
        let seconds = safe % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        ZStack {
            Color(hex: "050B09").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    topBar
                        .padding(.top, 52)
                        .padding(.horizontal, 20)

                    scoreRingCard
                        .padding(.horizontal, 20)

                    metricsRow
                        .padding(.horizontal, 20)

                    rankProgressCard
                        .padding(.horizontal, 20)

                    actionButtons
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await vm.load(lessonId: lessonId, level: level)
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                onBackToLesson?()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(height: 44)
                .padding(.horizontal, 18)
                .background(Color.white.opacity(0.12))
                .clipShape(Capsule())
            }

            Spacer()

            Text("Summary")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }

    private var scoreRingCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 16)
                    .frame(width: 236, height: 236)

                Circle()
                    .trim(from: 0, to: scoreRatio)
                    .stroke(
                        Color(hex: "45E38C"),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 236, height: 236)
                    .shadow(color: Color(hex: "45E38C").opacity(0.42), radius: 10, x: 0, y: 0)

                VStack(spacing: 4) {
                    Text(scoreText)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("SCORE ACHIEVED")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.45))
                        .tracking(1.1)
                }
            }

            VStack(spacing: 8) {
                Text(summaryHeadline)
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Text("You completed \(lessonDisplayName) with strong focus and consistency.")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var metricsRow: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                metricCard(
                    icon: "bolt.fill",
                    title: "XP EARNED",
                    value: "+\(earnedXP)",
                    accent: Color(hex: "45E38C"),
                    subtitle: "THIS LEVEL"
                )

                metricCard(
                    icon: "trophy.fill",
                    title: "GLOBAL RANK",
                    value: vm.rankDisplay,
                    accent: Color(hex: "38BDF8"),
                    subtitle: vm.percentileDisplay
                )
            }

            HStack(spacing: 12) {
                metricCard(
                    icon: "timer",
                    title: "TIME",
                    value: timeDisplay,
                    accent: Color(hex: "38BDF8"),
                    subtitle: "ELAPSED"
                )
            }
        }
    }

    private var rankProgressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label {
                    Text("RANK PROGRESS")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(0.8)
                } icon: {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "45E38C"))
                }

                Spacer()

                Text("LVL \(vm.level)")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(hex: "45E38C"))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 14)

                    Capsule()
                        .fill(Color(hex: "45E38C"))
                        .frame(width: geo.size.width * vm.progressToNextLevel, height: 14)
                }
            }
            .frame(height: 14)

            HStack {
                Text(vm.currentRankTitle.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(1.0)

                Spacer()

                Text("\(vm.xpToNextTitle) XP TO \(vm.nextRankTitle.uppercased())")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(0.8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.04), Color(hex: "45E38C").opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.7)
                )
        )
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                if level < totalLevels, !vm.isCooldownActive {
                    onProgressToNextLevel?()
                } else if level >= totalLevels {
                    onBackToLesson?()
                }
            } label: {
                Text(vm.cooldownButtonTitle(level: level, totalLevels: totalLevels))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(vm.isCooldownActive ? Color.white.opacity(0.24) : Color(hex: "0EB060"))
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(color: Color(hex: "0EB060").opacity(vm.isCooldownActive ? 0.12 : 0.32), radius: 12, y: 3)
            }
            .buttonStyle(.plain)
            .disabled(vm.isCooldownActive && level < totalLevels)

            if vm.isCooldownActive {
                Text("Next level unlocks in \(vm.cooldownDisplay)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }

            Button {
                onReviewAnswers?()
            } label: {
                Text("Review Answers")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)

            Button {
                onReturnHome?()
            } label: {
                Text("Return to Home")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func metricCard(icon: String,
                            title: String,
                            value: String,
                            accent: Color,
                            subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(accent)
                    .frame(width: 28, height: 28)
                    .background(accent.opacity(0.14))
                    .clipShape(Circle())

                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.58))
                    .tracking(0.8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(accent)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 138)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.04), accent.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.7)
                )
        )
    }

    private var summaryHeadline: String {
        switch scoreRatio {
        case 0.9...: return "Brilliant Performance!"
        case 0.75..<0.9: return "Great Momentum!"
        case 0.5..<0.75: return "Solid Effort!"
        default: return "Keep Going!"
        }
    }
}

@MainActor
final class LevelSummaryViewModel: ObservableObject {
    @Published var rankDisplay: String = "#--"
    @Published var percentileDisplay: String = "TOP --%"
    @Published var level: Int = 1
    @Published var progressToNextLevel: Double = 0.0
    @Published var currentRankTitle: String = "Amateur"
    @Published var nextRankTitle: String = "Adept"
    @Published var xpToNextTitle: Int = 100
    @Published var cooldownRemainingSeconds: Int?

    private let db = Firestore.firestore()
    private var cooldownTimer: AnyCancellable?

    var isCooldownActive: Bool {
        cooldownRemainingSeconds != nil
    }

    var cooldownDisplay: String {
        guard let cooldownRemainingSeconds else { return "" }
        let hours = cooldownRemainingSeconds / 3600
        let minutes = (cooldownRemainingSeconds % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    func cooldownButtonTitle(level: Int, totalLevels: Int) -> String {
        if level >= totalLevels {
            return "Back to Lesson"
        }
        if let cooldownRemainingSeconds {
            let hours = cooldownRemainingSeconds / 3600
            let minutes = (cooldownRemainingSeconds % 3600) / 60
            return "Unlocks in \(hours)h \(minutes)m"
        }
        return "Progress to Next Level"
    }

    func load(lessonId: String, level: Int) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        do {
            let userDoc = try await db.collection("users").document(uid).getDocument()
            let userData = userDoc.data() ?? [:]
            let totalXP = userData["totalXP"] as? Int ?? 0
            let isPro = userData["isPro"] as? Bool ?? false

            self.level = max(1, totalXP / 100 + 1)
            let levelXP = totalXP % 100
            progressToNextLevel = min(max(Double(levelXP) / 100.0, 0.0), 1.0)

            let rankMeta = rankMeta(for: totalXP)
            currentRankTitle = rankMeta.current
            nextRankTitle = rankMeta.next
            xpToNextTitle = rankMeta.xpToNext

            let activeLessonDoc = try await db.collection("users")
                .document(uid)
                .collection("activeLessons")
                .document(lessonId)
                .getDocument()
            let activeData = activeLessonDoc.data() ?? [:]
            let lastLevelCompletedAt = (activeData["lastLevelCompletedAt"] as? Timestamp)?.dateValue()
            
            // Pro users bypass cooldown
            if isPro {
                cooldownRemainingSeconds = nil
            } else {
                cooldownRemainingSeconds = cooldownSecondsRemaining(lastLevelCompletedAt: lastLevelCompletedAt, now: Date())
            }
            startCooldownTimer(lessonId: lessonId, level: level)

            let leaderboardSnapshot = try await db
                .collection("leaderboards")
                .document("global")
                .collection("entries")
                .order(by: "totalXP", descending: true)
                .limit(to: 200)
                .getDocuments()

            if let index = leaderboardSnapshot.documents.firstIndex(where: { $0.documentID == uid }) {
                let rank = index + 1
                rankDisplay = "#\(rank)"
                let percentile = max(1, Int((Double(rank) / Double(max(leaderboardSnapshot.documents.count, 1))) * 100.0))
                percentileDisplay = "TOP \(percentile)%"
            }
        } catch {
            // Keep graceful defaults.
        }
    }

    private func startCooldownTimer(lessonId: String, level: Int) {
        cooldownTimer?.cancel()
        guard cooldownRemainingSeconds != nil else { return }

        cooldownTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                Task {
                    guard let uid = Auth.auth().currentUser?.uid else { return }
                    let activeLessonDoc = try? await self.db.collection("users")
                        .document(uid)
                        .collection("activeLessons")
                        .document(lessonId)
                        .getDocument()
                    let activeData = activeLessonDoc?.data() ?? [:]
                    let lastLevelCompletedAt = (activeData["lastLevelCompletedAt"] as? Timestamp)?.dateValue()
                    let remaining = self.cooldownSecondsRemaining(lastLevelCompletedAt: lastLevelCompletedAt, now: Date())
                    self.cooldownRemainingSeconds = remaining
                    if remaining == nil {
                        self.cooldownTimer?.cancel()
                        self.cooldownTimer = nil
                    }
                }
            }
    }

    private func cooldownSecondsRemaining(lastLevelCompletedAt: Date?, now: Date) -> Int? {
        guard let lastLevelCompletedAt else { return nil }
        let unlockAt = lastLevelCompletedAt.addingTimeInterval(24 * 60 * 60)
        guard now < unlockAt else { return nil }
        return max(0, Int(unlockAt.timeIntervalSince(now)))
    }

    private func rankMeta(for xp: Int) -> (current: String, next: String, xpToNext: Int) {
        switch xp {
        case ..<100:
            return ("Amateur", "Adept", 100 - xp)
        case ..<200:
            return ("Adept", "Polymath", 200 - xp)
        case ..<400:
            return ("Polymath", "Scholar", 400 - xp)
        case ..<700:
            return ("Scholar", "Strategist", 700 - xp)
        case ..<1100:
            return ("Strategist", "Sage", 1100 - xp)
        case ..<1600:
            return ("Sage", "Grandmaster", 1600 - xp)
        case ..<2300:
            return ("Grandmaster", "Legend", 2300 - xp)
        default:
            return ("Legend", "Legend", 0)
        }
    }
}

#Preview {
    LevelSummaryView(lessonId: "astronomy", level: 1, totalLevels: 10, score: 9, totalQuestions: 10, earnedXP: 500, totalTimeSeconds: 760)
}
