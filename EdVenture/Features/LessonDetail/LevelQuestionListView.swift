import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

struct LevelQuestionListView: View {
    let lessonId: String
    let level: Int
    let totalLevels: Int
    var onBack: (() -> Void)?
    var onSelectQuestion: ((Int) -> Void)?
    var onReplayFailedQuestion: ((EVQuizQuestion) -> Void)?
    var onReviewQuestion: ((String) -> Void)?

    @StateObject private var vm = LevelQuestionListViewModel()

    var body: some View {
        ZStack {
            Color(hex: "0A0F0D").ignoresSafeArea()

            if vm.isLoading {
                ProgressView()
                    .tint(Color(hex: "0EB060"))
                    .scaleEffect(1.2)
            } else if let errorMessage = vm.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white.opacity(0.65))
                    Text(errorMessage)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        topBar
                            .padding(.horizontal, 20)
                            .padding(.top, 52)

                        headerCard
                            .padding(.horizontal, 20)

                        questionList
                            .padding(.horizontal, 20)
                            .padding(.bottom, 28)
                    }
                }
            }

            if let lockMessage = vm.lockMessage {
                lockOverlay(lockMessage)
            }
        }
        .navigationBarHidden(true)
        .task(id: "\(lessonId)-\(level)") {
            await vm.load(lessonId: lessonId, level: level)
        }
    }

    private var topBar: some View {
        HStack {
            EVBackButton(title: "Back", action: { onBack?() }, compactTitleSize: 16)

            Spacer()

            Text("Level \(level)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            Text("\(level)/\(max(totalLevels, 1))")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
                .frame(width: 60, alignment: .trailing)
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(vm.lessonTitle)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("Choose a question to review or continue.")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.white.opacity(0.6))

            if let remaining = vm.nextCooldownText() {
                HStack(spacing: 8) {
                    Image(systemName: "lock.clock.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "F6CC2E"))
                    Text("Question cooldown")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.75))
                    Spacer()
                    Text(remaining)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(Color(hex: "F6CC2E"))
                }
                .padding(.horizontal, 12)
                .frame(height: 34)
                .background(Color(hex: "F6CC2E").opacity(0.12))
                .clipShape(Capsule())
            }
            HStack(spacing: 14) {
                statChip(title: "COMPLETED", value: "\(vm.completedCount)", color: Color(hex: "0EB060"))
                statChip(title: "PENDING", value: "\(vm.pendingCount)", color: Color(hex: "75DFFF"))
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.6)
                )
        )
    }

    private func statChip(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.45))
                .tracking(1.2)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var questionList: some View {
        VStack(spacing: 12) {
            ForEach(Array(vm.items.enumerated()), id: \.element.id) { index, item in
                LevelQuestionRow(
                    item: item,
                    index: index + 1,
                    onReview: {
                        if item.status == .completed {
                            onReviewQuestion?(item.id)
                        }
                    },
                    onReplay: {
                        if item.cooldownRemainingSeconds != nil {
                            vm.showCurrentLockMessage(for: item.id)
                        } else if item.status == .failed, let question = vm.questionSnapshot(for: item.id) {
                            onReplayFailedQuestion?(question)
                        } else {
                            onSelectQuestion?(index)
                        }
                    }
                )
            }
        }
    }

    private func lockOverlay(_ message: String) -> some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(Color(hex: "F6CC2E"))
                Text("Question Locked")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(message)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                if let lockedQuestionId = vm.lockedQuestionId,
                   let remaining = vm.lockRemainingText(for: lockedQuestionId) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.clock.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "F6CC2E"))
                        Text("Try again in")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.78))
                        Text(remaining)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "F6CC2E"))
                            .monospacedDigit()
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 34)
                    .background(Color(hex: "F6CC2E").opacity(0.12))
                    .clipShape(Capsule())
                }
                Button {
                    vm.lockMessage = nil
                    vm.lockedQuestionId = nil
                } label: {
                    Text("OK")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color(hex: "0EB060"))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(hex: "1A2420"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color(hex: "F6CC2E").opacity(0.25), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 24)
        }
    }
}

struct LevelQuestionListItem: Identifiable {
    let id: String
    let title: String
    let xp: Int
    let status: LevelQuestionStatus
    var cooldownRemainingSeconds: Int?
}

enum LevelQuestionStatus {
    case completed
    case inProgress
    case pending
    case failed
}


private struct LevelQuestionRow: View {
    let item: LevelQuestionListItem
    let index: Int
    let onReview: () -> Void
    let onReplay: () -> Void

    private var accent: Color {
        if item.cooldownRemainingSeconds != nil { return Color(hex: "F6CC2E") }
        switch item.status {
        case .completed: return Color(hex: "0EB060")
        case .inProgress: return Color(hex: "75DFFF")
        case .pending: return Color.white.opacity(0.55)
        case .failed: return Color(hex: "F6CC2E")
        }
    }

    private var statusText: String {
        if item.cooldownRemainingSeconds != nil { return "COOLDOWN" }
        switch item.status {
        case .completed: return "COMPLETED"
        case .inProgress: return "IN PROGRESS"
        case .pending: return "PENDING"
        case .failed: return "FAILED"
        }
    }

    private var statusIcon: String {
        if item.cooldownRemainingSeconds != nil { return "lock.clock.fill" }
        switch item.status {
        case .completed: return "checkmark.circle.fill"
        case .inProgress: return "play.circle.fill"
        case .pending: return "circle"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }

    private var primaryActionTitle: String {
        if item.cooldownRemainingSeconds != nil { return "Locked" }
        switch item.status {
        case .completed:
            return "Replay"
        case .inProgress:
            return "Continue"
        case .pending:
            return "Play"
        case .failed:
            return "Replay"
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                Text(String(format: "%02d", index))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(accent)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        Image(systemName: statusIcon)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(accent)
                        Text(statusText)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(accent)
                            .tracking(0.9)
                            .lineLimit(1)
                        Text("\(item.xp) XP")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.45))
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: item.cooldownRemainingSeconds != nil ? "lock.fill" : "play.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "0A0F0D"))
                    .frame(width: 36, height: 36)
                    .background(accent.opacity(item.status == .pending ? 0.12 : 0.9))
                    .clipShape(Circle())
            }

            HStack(spacing: 10) {
                Button(action: onReplay) {
                    HStack(spacing: 6) {
                        if let seconds = item.cooldownRemainingSeconds {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text(primaryActionTitle)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                            Text(formatCooldown(seconds))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .monospacedDigit()
                        } else {
                            Text(primaryActionTitle)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                    }
                    .foregroundColor(Color(hex: "0A0F0D"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(item.cooldownRemainingSeconds != nil ? Color(hex: "F6CC2E") : Color(hex: "0EB060"))
                    .clipShape(Capsule())
                }

                if item.status == .completed {
                    Button(action: onReview) {
                        Text("Review")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.6)
                )
        )
    }

    private func formatCooldown(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

@MainActor
final class LevelQuestionListViewModel: ObservableObject {
    @Published var items: [LevelQuestionListItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lessonTitle: String = "Lesson"
    @Published var completedCount: Int = 0
    @Published var pendingCount: Int = 0
    @Published var lockMessage: String?
    @Published var lockedQuestionId: String?
    @Published var isProUser: Bool = false

    private let store = EVQuizStore()
    private let db = Firestore.firestore()
    private var cooldownTimer: AnyCancellable?
    private var loadedQuestionsById: [String: EVQuizQuestion] = [:]
    private var retryQuestionsById: [String: EVQuizQuestion] = [:]
    private var questionCooldowns: [String: Date] = [:]
    private var currentTime: Date = Date()

    deinit {
        cooldownTimer?.cancel()
    }

    func load(lessonId: String, level: Int) async {
        isLoading = true
        errorMessage = nil
        lockMessage = nil
        lockedQuestionId = nil
        loadedQuestionsById = [:]
        retryQuestionsById = [:]
        questionCooldowns = [:]
        stopCooldownTimer()
        defer { isLoading = false }

        do {
            guard let uid = Auth.auth().currentUser?.uid else {
                errorMessage = "Please sign in to view questions."
                return
            }

            let userDoc = try await db.collection("users").document(uid).getDocument()
            let userData = userDoc.data() ?? [:]
            isProUser = userData["isPro"] as? Bool ?? false

            let lessonDoc = try await db.collection("lessons").document(lessonId).getDocument()
            if let data = lessonDoc.data() {
                let title = (data["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                lessonTitle = title?.isEmpty == false ? title! : lessonId.replacingOccurrences(of: "_", with: " ").capitalized
            } else {
                lessonTitle = lessonId.replacingOccurrences(of: "_", with: " ").capitalized
            }

            let questions = try await store.loadLevelQuestionSet(userId: uid, lessonId: lessonId, level: level)
            guard !questions.isEmpty else {
                errorMessage = "No questions found for this level yet."
                items = []
                completedCount = 0
                pendingCount = 0
                return
            }

            let session = try await store.loadSession(userId: uid, lessonId: lessonId, level: level, totalQuestions: questions.count)
            loadedQuestionsById = Dictionary(uniqueKeysWithValues: questions.map { ($0.id, $0) })
            retryQuestionsById = Dictionary(uniqueKeysWithValues: session.retryQuestions.map { ($0.question.id, $0.question) })
            questionCooldowns = session.questionCooldowns.filter { $0.value > Date() }
            currentTime = Date()
            startCooldownTimerIfNeeded()

            let progress = await loadQuestionProgress(lessonId: lessonId)

            var completed = 0
            var failedCount = 0
            let mapped = questions.enumerated().map { _, question in
                let cooldown = questionCooldowns[question.id]
                let remaining = cooldown.map { max(0, Int(ceil($0.timeIntervalSince(currentTime)))) }
                let status: LevelQuestionStatus
                if progress.completed.contains(question.id) {
                    status = .completed
                    completed += 1
                } else if remaining != nil {
                    status = .failed
                    failedCount += 1
                } else if progress.attempted.contains(question.id) {
                    status = .failed
                    failedCount += 1
                } else {
                    status = .pending
                }

                return LevelQuestionListItem(
                    id: question.id,
                    title: stripPromptPrefix(question.prompt),
                    xp: question.xpSuggested,
                    status: status,
                    cooldownRemainingSeconds: remaining
                )
            }

            items = mapped
            completedCount = completed
            pendingCount = max(mapped.count - completed - failedCount, 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func showCurrentLockMessage(for questionId: String) {
        lockedQuestionId = questionId
        lockMessage = "This question is on cooldown."
    }

    func nextCooldownText() -> String? {
        guard let expiry = questionCooldowns.values.min(), expiry > currentTime else { return nil }
        return formatCooldown(max(0, Int(ceil(expiry.timeIntervalSince(currentTime)))))
    }

    func lockRemainingText(for questionId: String?) -> String? {
        guard let questionId, let expiry = questionCooldowns[questionId], expiry > currentTime else { return nil }
        return formatCooldown(max(0, Int(ceil(expiry.timeIntervalSince(currentTime)))))
    }

    func questionSnapshot(for questionId: String) -> EVQuizQuestion? {
        retryQuestionsById[questionId] ?? loadedQuestionsById[questionId]
    }

    private func startCooldownTimerIfNeeded() {
        cooldownTimer?.cancel()

        guard !questionCooldowns.isEmpty else { return }

        cooldownTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] now in
                self?.tickCooldowns(now: now)
            }
    }

    private func stopCooldownTimer() {
        cooldownTimer?.cancel()
        cooldownTimer = nil
    }

    private func tickCooldowns(now: Date) {
        currentTime = now
        questionCooldowns = questionCooldowns.filter { $0.value > now }
        if questionCooldowns.isEmpty {
            lockedQuestionId = nil
            stopCooldownTimer()
        }
        items = items.map { item in
            var updated = item
            updated.cooldownRemainingSeconds = questionCooldowns[item.id].map { max(0, Int(ceil($0.timeIntervalSince(now)))) }
            return updated
        }
    }

    private func stripPromptPrefix(_ prompt: String) -> String {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()
        let prefixes = [
            "which concept matches the description:",
            "which concept matches this description:",
            "which concept matches the description",
            "which concept matches this description",
            "which concept matches"
        ]

        for prefix in prefixes {
            if lower.hasPrefix(prefix) {
                let start = trimmed.index(trimmed.startIndex, offsetBy: prefix.count)
                let remainder = trimmed[start...]
                return remainder.trimmingCharacters(in: CharacterSet(charactersIn: ": ").union(.whitespacesAndNewlines))
            }
        }
        return trimmed
    }

    private func loadQuestionProgress(lessonId: String) async -> (completed: Set<String>, attempted: Set<String>) {
        guard let uid = Auth.auth().currentUser?.uid else { return ([], []) }

        do {
            let snapshot = try await db.collection("users")
                .document(uid)
                .collection("activeLessons")
                .document(lessonId)
                .collection("questions")
                .getDocuments()

            var completed: Set<String> = []
            var attempted: Set<String> = []

            for doc in snapshot.documents {
                let data = doc.data()
                let isCompleted = data["isCompleted"] as? Bool ?? false
                attempted.insert(doc.documentID)
                if isCompleted {
                    completed.insert(doc.documentID)
                }
            }

            return (completed, attempted)
        } catch {
            return ([], [])
        }
    }

    private func formatCooldown(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

#Preview {
    LevelQuestionListView(lessonId: "astronomy", level: 1, totalLevels: 10)
}
