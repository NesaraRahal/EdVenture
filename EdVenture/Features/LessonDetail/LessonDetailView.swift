import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UIKit
import Combine

struct LessonDetailView: View {
    let lessonId: String
    var onBack: (() -> Void)?
    var onStartQuiz: ((_ lessonId: String, _ level: Int, _ questionIndex: Int, _ totalLevels: Int) -> Void)?
    var onOpenPurchase: (() -> Void)?

    @StateObject private var vm = LessonDetailViewModel()

    var body: some View {
        ZStack {
            Color(hex: "0A0F0D").ignoresSafeArea()

            if vm.isLoading {
                ProgressView()
                    .tint(Color(hex: "0EB060"))
                    .scaleEffect(1.2)
            } else if let error = vm.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white.opacity(0.65))
                    Text(error)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            } else if let lesson = vm.lesson {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        topBar
                            .padding(.horizontal, 20)
                            .padding(.top, 52)

                        backButton
                            .padding(.horizontal, 20)
                            .padding(.top, 18)

                        overviewCard(lesson)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)

                        curriculumSection(lesson)
                            .padding(.horizontal, 20)
                            .padding(.top, 28)
                            .padding(.bottom, 24)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .task(id: lessonId) {
            await vm.load(lessonId: lessonId)
        }
        .onAppear {
            // Refresh when view appears (after returning from payment, etc.)
            Task {
                await vm.load(lessonId: lessonId)
            }
        }
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 8) {
                Image("EdVentureLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                Text("EdVenture")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "0EB060"))
            }

            Spacer()

            HStack(spacing: 10) {
                EVLiquidGlassIconButton(systemName: "bell.fill") {}
                EVProfileAvatarView(
                    size: 38,
                    iconSize: 15,
                    iconOpacity: 0.7,
                    ringColor: Color.white.opacity(0.15),
                    ringWidth: 0.5
                )
            }
        }
    }

    private var backButton: some View {
        HStack {
            Button {
                onBack?()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white.opacity(0.95))
                .padding(.horizontal, 20)
                .frame(height: 44)
                .background(Color.white.opacity(0.14))
                .clipShape(Capsule())
            }
            .frame(minWidth: 44, minHeight: 44)

            Spacer()
        }
    }

    private func overviewCard(_ lesson: LessonDetail) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(hex: lesson.colorHex).opacity(0.18))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: lesson.icon)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(Color(hex: lesson.colorHex))
                    )

                VStack(alignment: .leading, spacing: 5) {
                    Text(lesson.title)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("\(lesson.xpReward) XP per question")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "0EB060"))
                }

                Spacer()

                NavigationLink(destination: TutorialQuestionView()) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(hex: "0EB060"))
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 6)
                    Capsule()
                        .fill(Color(hex: "0EB060"))
                        .frame(width: max(0.06, lesson.progress) * 300, height: 6)
                }
                Text("Progress \(Int((lesson.progress * 100).rounded()))%")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }

            HStack(spacing: 12) {
                detailStat(title: "COMPLETED", value: "\(lesson.completedCount)", accent: Color(hex: "0EB060"))
                detailStat(title: "PENDING", value: "\(lesson.pendingCount)", accent: Color(hex: "75DFFF"))
                detailStat(title: "LOCKED", value: "\(lesson.lockedCount)", accent: .white.opacity(0.45))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.045), Color(hex: "0EB060").opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color(hex: "0EB060").opacity(0.22), lineWidth: 0.6)
                )
        )
    }

    private func curriculumSection(_ lesson: LessonDetail) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("LEVEL MAP")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .tracking(2)

                if let cooldownSeconds = vm.cooldownDisplaySeconds, !vm.isPro {
                    cooldownCountdownView(cooldownSeconds)
                }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 5), spacing: 14) {
                ForEach(vm.items) { item in
                    Button {
                        guard !item.isLocked else { return }
                        Task {
                            let ready = await vm.preloadLevelQuestions(lessonId: lesson.id, level: item.level)
                            if ready {
                                onStartQuiz?(lesson.id, item.level, 0, lesson.totalLevels)
                            }
                        }
                    } label: {
                        LevelNode(item: item)
                    }
                    .buttonStyle(.plain)
                    .disabled(item.isLocked)
                }
            }

            HStack(spacing: 12) {
                Label("Completed", systemImage: "checkmark.circle.fill")
                    .foregroundColor(Color(hex: "0EB060"))
                Label("Current", systemImage: "play.fill")
                    .foregroundColor(Color(hex: "75DFFF"))
                Label("Locked", systemImage: "lock.fill")
                    .foregroundColor(.white.opacity(0.45))
            }
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .padding(.top, 6)
        }
    }

    private func cooldownCountdownView(_ cooldownSeconds: Int) -> some View {
        let hours = cooldownSeconds / 3600
        let minutes = (cooldownSeconds % 3600) / 60
        let seconds = cooldownSeconds % 60
        let totalSeconds: Double = 24 * 60 * 60
        let progressPercent = 1.0 - (Double(cooldownSeconds) / totalSeconds)

        return VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text("Next Level Cooldown")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(0.5)

                Text(String(format: "%02d:%02d:%02d", hours, minutes, seconds))
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: "0EB060"))
            }

            VStack(spacing: 4) {
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 6)
                    Capsule()
                        .fill(Color(hex: "0EB060"))
                        .frame(width: max(0, progressPercent) * 300, height: 6)
                }
                HStack {
                    Text("Time elapsed")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                    Spacer()
                    Text(String(format: "%.0f%%", progressPercent * 100))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            HStack(spacing: 12) {
                Button {
                    // If Pro, proceed to next level. Otherwise, open purchase flow
                    if vm.isPro {
                        // Pro users can proceed immediately - for now just dismiss
                        // In real scenario, this would trigger level progression
                        onBack?()
                    } else {
                        onOpenPurchase?()
                    }
                } label: {
                    Text(vm.isPro ? "Proceed to Next" : "Unlock now")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "0A0F0D"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Color(hex: "0EB060"))
                        .clipShape(Capsule())
                }

                Button {
                    onOpenPurchase?()
                } label: {
                    Text("Manage Payment")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(hex: "0EB060").opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(hex: "0EB060").opacity(0.2), lineWidth: 0.6)
                )
        )
    }

    private func detailStat(title: String, value: String, accent: Color) -> some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.35))
                .tracking(2)
            Text(value)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(accent)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 150)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.05), lineWidth: 0.6)
                )
        )
    }
}

@MainActor
final class LessonDetailViewModel: ObservableObject {
    @Published var lesson: LessonDetail?
    @Published var items: [LessonCurriculumItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var cooldownDisplaySeconds: Int?
    @Published var isPro = false

    private let db = Firestore.firestore()
    private let quizStore = EVQuizStore()
    private let activityService = LessonCooldownActivityService.shared
    private var cooldownTimer: AnyCancellable?
    private var lastLoadedLessonId: String?
    private var cachedLessonTitle = "Lesson"
    private var cachedIcon = "book.fill"
    private var cachedColorHex = "0EB060"
    private var cachedXpReward = 50
    private var cachedTotalLevels = 1
    private var cachedCompletedLevels: Set<Int> = []
    private var cachedHighestUnlockedLevel = 1
    private var cachedCurrentLevel = 1
    private var cachedProgress: Double = 0
    private var cachedLastLevelCompletedAt: Date?
    private var cachedIsPro = false

    deinit {
        cooldownTimer?.cancel()
    }

    func load(lessonId: String) async {
        isLoading = true
        errorMessage = nil
        lastLoadedLessonId = lessonId
        defer { isLoading = false }

        do {
            let lessonSnapshot = try await db.collection("lessons").document(lessonId).getDocument()
            guard let data = lessonSnapshot.data() else {
                errorMessage = "Lesson not found."
                return
            }

            let title = (data["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let iconRaw = (data["icon"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let colorHex = (data["color"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let xpReward = data["xpReward"] as? Int ?? 50
            let totalLevels = max(data["totalLevels"] as? Int ?? 10, 1)

            var progress: Double = 0
            var completedLevels: Set<Int> = []
            var highestUnlockedLevel = 1
            var currentLevel = 1
            var lastLevelCompletedAt: Date?
            var isPro = false
            
            if let uid = Auth.auth().currentUser?.uid {
                let userDoc = try await db.collection("users").document(uid).getDocument()
                let userData = userDoc.data() ?? [:]
                isPro = userData["isPro"] as? Bool ?? false
                
                let active = try await db.collection("users").document(uid)
                    .collection("activeLessons").document(lessonId).getDocument()
                let activeData = active.data() ?? [:]
                progress = min(max(activeData["progress"] as? Double ?? 0, 0), 1)
                completedLevels = Set(activeData["completedLevels"] as? [Int] ?? [])
                highestUnlockedLevel = max(activeData["highestUnlockedLevel"] as? Int ?? 1, 1)
                currentLevel = max(activeData["currentLevel"] as? Int ?? 1, 1)
                lastLevelCompletedAt = (activeData["lastLevelCompletedAt"] as? Timestamp)?.dateValue()
            }

            if completedLevels.isEmpty, progress > 0 {
                let completedFromProgress = Int((progress * Double(totalLevels)).rounded(.down))
                if completedFromProgress > 0 {
                    completedLevels = Set(1...min(completedFromProgress, totalLevels))
                }
            }

            if completedLevels.isEmpty {
                highestUnlockedLevel = max(highestUnlockedLevel, 1)
            } else {
                highestUnlockedLevel = max(highestUnlockedLevel, min(totalLevels, completedLevels.count + 1))
            }

            cachedLessonTitle = (title?.isEmpty == false ? title! : "Untitled")
            cachedIcon = resolveIcon(iconRaw)
            cachedColorHex = (colorHex?.isEmpty == false ? colorHex! : "0EB060")
            cachedXpReward = xpReward
            cachedTotalLevels = totalLevels
            cachedCompletedLevels = completedLevels
            cachedHighestUnlockedLevel = highestUnlockedLevel
            cachedCurrentLevel = min(max(currentLevel, 1), totalLevels)
            cachedProgress = completedLevels.isEmpty ? progress : min(max(Double(completedLevels.count) / Double(totalLevels), 0), 1)
            cachedLastLevelCompletedAt = lastLevelCompletedAt
            cachedIsPro = isPro
            await MainActor.run {
                self.isPro = isPro
            }

            rebuildLessonState(now: Date())
            startCooldownTimerIfNeeded()
            
            // Start live activity if cooldown is active
            if !isPro, let lastLevelCompletedAt = lastLevelCompletedAt {
                let unlockAt = lastLevelCompletedAt.addingTimeInterval(24 * 60 * 60)
                if Date() < unlockAt {
                    activityService.startCooldownActivity(
                        lessonId: lessonId,
                        lessonTitle: cachedLessonTitle,
                        icon: cachedIcon,
                        colorHex: cachedColorHex,
                        unlockAt: unlockAt
                    )
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            stopCooldownTimer()
        }
    }

    func preloadLevelQuestions(lessonId: String, level: Int) async -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "Please sign in to load questions."
            return false
        }

        do {
            _ = try await quizStore.loadLevelQuestionSet(userId: uid, lessonId: lessonId, level: level)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func startCooldownTimerIfNeeded() {
        cooldownTimer?.cancel()

        guard isCooldownActive(now: Date()) else { return }

        cooldownTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.rebuildLessonState(now: Date())
                if self?.isCooldownActive(now: Date()) != true {
                    self?.stopCooldownTimer()
                }
            }
    }

    private func stopCooldownTimer() {
        cooldownTimer?.cancel()
        cooldownTimer = nil
    }

    private func isCooldownActive(now: Date) -> Bool {
        guard !cachedIsPro else { return false }
        guard let lastLevelCompletedAt = cachedLastLevelCompletedAt else { return false }
        let unlockAt = lastLevelCompletedAt.addingTimeInterval(24 * 60 * 60)
        return now < unlockAt
    }

    private func cooldownSecondsRemaining(now: Date) -> Int? {
        guard let lastLevelCompletedAt = cachedLastLevelCompletedAt else { return nil }
        let unlockAt = lastLevelCompletedAt.addingTimeInterval(24 * 60 * 60)
        guard now < unlockAt else { return nil }
        return max(0, Int(unlockAt.timeIntervalSince(now)))
    }

    private func rebuildLessonState(now: Date) {
        cooldownDisplaySeconds = isCooldownActive(now: now) ? cooldownSecondsRemaining(now: now) : nil
        
        // Update activity state if cooldown is active
        if isCooldownActive(now: now), let lastLevelCompletedAt = cachedLastLevelCompletedAt {
            let unlockAt = lastLevelCompletedAt.addingTimeInterval(24 * 60 * 60)
            activityService.updateActivityState(forLessonId: lastLoadedLessonId ?? "", unlockAt: unlockAt)
        }

        let completed = min(cachedCompletedLevels.count, cachedTotalLevels)
        let isCooldownActive = isCooldownActive(now: now)
        let cooldownAdjustment = isCooldownActive ? 1 : 0
        let pending = max(cachedHighestUnlockedLevel - completed - cooldownAdjustment, 0)
        let locked = max(cachedTotalLevels - cachedHighestUnlockedLevel + cooldownAdjustment, 0)

        lesson = LessonDetail(
            id: lastLoadedLessonId ?? "",
            title: cachedLessonTitle,
            icon: cachedIcon,
            colorHex: cachedColorHex,
            xpReward: cachedXpReward,
            totalLevels: cachedTotalLevels,
            progress: cachedProgress,
            completedCount: completed,
            pendingCount: pending,
            lockedCount: locked
        )

        items = buildCurriculumItems(
            totalLevels: cachedTotalLevels,
            completedLevels: cachedCompletedLevels,
            highestUnlockedLevel: cachedHighestUnlockedLevel,
            currentLevel: cachedCurrentLevel,
            xpReward: cachedXpReward,
            lessonTitle: cachedLessonTitle,
            lastLevelCompletedAt: cachedLastLevelCompletedAt,
            now: now,
            isPro: cachedIsPro
        )
    }

    private func resolveIcon(_ icon: String?) -> String {
        let candidate = (icon?.isEmpty == false ? icon! : "book.fill")
        return UIImage(systemName: candidate) == nil ? "book.fill" : candidate
    }

    private func buildCurriculumItems(totalLevels: Int,
                                      completedLevels: Set<Int>,
                                      highestUnlockedLevel: Int,
                                      currentLevel: Int,
                                      xpReward: Int,
                                      lessonTitle: String,
                                      lastLevelCompletedAt: Date?,
                                      now: Date,
                                      isPro: Bool) -> [LessonCurriculumItem] {
        let displayCount = min(max(totalLevels, 1), 10)
        let safeCurrentLevel = min(max(currentLevel, 1), displayCount)
        let safeHighestUnlocked = min(max(highestUnlockedLevel, 1), displayCount)
        let unlockAt = lastLevelCompletedAt?.addingTimeInterval(24 * 60 * 60)

        return (1...displayCount).map { level in
            let status: LessonItemStatus
            if completedLevels.contains(level) {
                status = .completed
            } else if level == safeHighestUnlocked {
                // This is the next unlockable level
                if isPro {
                    // Pro users skip cooldown - next level unlocks immediately
                    status = .pending
                } else if let unlockAt, now < unlockAt {
                    // Regular users see cooldown on next level
                    status = .lockedByCooldown(secondsRemaining: max(0, Int(unlockAt.timeIntervalSince(now))))
                } else {
                    // Cooldown expired
                    status = .pending
                }
            } else if level == safeCurrentLevel {
                status = .inProgress
            } else if level < safeHighestUnlocked {
                status = .pending
            } else {
                status = .locked
            }

            return LessonCurriculumItem(
                id: "L\(level)",
                level: level,
                title: "\(lessonTitle) • Level \(level)",
                meta: "\(xpReward) XP • 10 QUESTIONS",
                status: status
            )
        }
    }
}

struct LessonDetail {
    let id: String
    let title: String
    let icon: String
    let colorHex: String
    let xpReward: Int
    let totalLevels: Int
    let progress: Double
    let completedCount: Int
    let pendingCount: Int
    let lockedCount: Int
}

struct LessonCurriculumItem: Identifiable {
    let id: String
    let level: Int
    let title: String
    let meta: String
    let status: LessonItemStatus

    var isLocked: Bool {
        switch status {
        case .locked, .lockedByCooldown:
            return true
        default:
            return false
        }
    }

    var statusColor: Color {
        switch status {
        case .completed: return Color(hex: "0EB060")
        case .inProgress: return Color(hex: "75DFFF")
        case .pending: return .white.opacity(0.55)
        case .locked, .lockedByCooldown: return .white.opacity(0.25)
        }
    }

    var buttonIcon: String {
        switch status {
        case .locked, .lockedByCooldown: return "lock.fill"
        default: return "play.fill"
        }
    }

    var buttonTint: Color {
        switch status {
        case .completed: return Color(hex: "0EB060")
        case .inProgress: return Color(hex: "0A0F0D")
        case .pending: return .white.opacity(0.65)
        case .locked, .lockedByCooldown: return .white.opacity(0.3)
        }
    }

    var buttonBackground: Color {
        switch status {
        case .completed: return Color(hex: "0EB060").opacity(0.15)
        case .inProgress: return Color(hex: "0EB060")
        case .pending: return Color.white.opacity(0.06)
        case .locked, .lockedByCooldown: return Color.white.opacity(0.04)
        }
    }
}

enum LessonItemStatus: Equatable {
    case completed
    case inProgress
    case pending
    case locked
    case lockedByCooldown(secondsRemaining: Int)
}

private struct LevelNode: View {
    let item: LessonCurriculumItem

    private var circleFill: Color {
        switch item.status {
        case .completed:
            return Color(hex: "0EB060").opacity(0.18)
        case .inProgress:
            return Color(hex: "75DFFF").opacity(0.18)
        case .pending:
            return Color.white.opacity(0.06)
        case .locked, .lockedByCooldown:
            return Color.white.opacity(0.04)
        }
    }

    private var circleStroke: Color {
        switch item.status {
        case .completed:
            return Color(hex: "0EB060").opacity(0.5)
        case .inProgress:
            return Color(hex: "75DFFF").opacity(0.5)
        case .pending:
            return Color.white.opacity(0.12)
        case .locked, .lockedByCooldown:
            return Color.white.opacity(0.08)
        }
    }

    private var iconName: String {
        switch item.status {
        case .completed:
            return "checkmark"
        case .inProgress:
            return "play.fill"
        case .pending:
            return "circle.fill"
        case .locked, .lockedByCooldown:
            return "lock.fill"
        }
    }

    private var iconColor: Color {
        switch item.status {
        case .completed:
            return Color(hex: "0EB060")
        case .inProgress:
            return Color(hex: "75DFFF")
        case .pending:
            return .white.opacity(0.65)
        case .locked, .lockedByCooldown:
            return .white.opacity(0.35)
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(circleFill)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(circleStroke, lineWidth: 1)
                    )

                Text("\(item.level)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(item.isLocked ? 0.35 : 0.95))

                if item.status != .pending {
                    Image(systemName: iconName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(iconColor)
                        .offset(x: 18, y: 18)
                }
            }

            VStack(spacing: 2) {
                Text("Level \(item.level)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(item.isLocked ? 0.35 : 0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}

#Preview {
    LessonDetailView(lessonId: "astronomy")
}
