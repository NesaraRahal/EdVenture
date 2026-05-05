import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UIKit
import Combine

struct LessonDetailView: View {
    let lessonId: String
    var onBack: (() -> Void)?
    var onStartQuiz: ((_ lessonId: String, _ level: Int, _ questionIndex: Int, _ totalLevels: Int) -> Void)?

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

    private let db = Firestore.firestore()
    private let quizStore = EVQuizStore()

    func load(lessonId: String) async {
        isLoading = true
        errorMessage = nil
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

            let icon = resolveIcon(iconRaw)

            var progress: Double = 0
            var completedLevels: Set<Int> = []
            var highestUnlockedLevel = 1
            var currentLevel = 1
            if let uid = Auth.auth().currentUser?.uid {
                let active = try await db.collection("users").document(uid)
                    .collection("activeLessons").document(lessonId).getDocument()
                let activeData = active.data() ?? [:]
                progress = min(max(activeData["progress"] as? Double ?? 0, 0), 1)
                completedLevels = Set(activeData["completedLevels"] as? [Int] ?? [])
                highestUnlockedLevel = max(activeData["highestUnlockedLevel"] as? Int ?? 1, 1)
                currentLevel = max(activeData["currentLevel"] as? Int ?? 1, 1)
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

            currentLevel = min(max(currentLevel, 1), totalLevels)
            let completed = min(completedLevels.count, totalLevels)
            let pending = max(highestUnlockedLevel - completed, 0)
            let locked = max(totalLevels - highestUnlockedLevel, 0)
            let adjustedProgress = totalLevels > 0
                ? min(max(Double(completed) / Double(totalLevels), 0), 1)
                : 0

            lesson = LessonDetail(
                id: lessonId,
                title: (title?.isEmpty == false ? title! : "Untitled"),
                icon: icon,
                colorHex: (colorHex?.isEmpty == false ? colorHex! : "0EB060"),
                xpReward: xpReward,
                totalLevels: totalLevels,
                progress: completedLevels.isEmpty ? progress : adjustedProgress,
                completedCount: completed,
                pendingCount: pending,
                lockedCount: locked
            )

            items = buildCurriculumItems(
                totalLevels: totalLevels,
                completedLevels: completedLevels,
                highestUnlockedLevel: highestUnlockedLevel,
                currentLevel: currentLevel,
                xpReward: xpReward,
                lessonTitle: lesson?.title ?? "Lesson"
            )
        } catch {
            errorMessage = error.localizedDescription
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

    private func resolveIcon(_ icon: String?) -> String {
        let candidate = (icon?.isEmpty == false ? icon! : "book.fill")
        return UIImage(systemName: candidate) == nil ? "book.fill" : candidate
    }

    private func buildCurriculumItems(totalLevels: Int,
                                      completedLevels: Set<Int>,
                                      highestUnlockedLevel: Int,
                                      currentLevel: Int,
                                      xpReward: Int,
                                      lessonTitle: String) -> [LessonCurriculumItem] {
        let displayCount = min(max(totalLevels, 1), 10)
        let safeCurrentLevel = min(max(currentLevel, 1), displayCount)
        let safeHighestUnlocked = min(max(highestUnlockedLevel, 1), displayCount)

        return (1...displayCount).map { level in
            let status: LessonItemStatus
            if completedLevels.contains(level) {
                status = .completed
            } else if level == safeCurrentLevel {
                status = .inProgress
            } else if level <= safeHighestUnlocked {
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

    var isLocked: Bool { status == .locked }

    var statusColor: Color {
        switch status {
        case .completed: return Color(hex: "0EB060")
        case .inProgress: return Color(hex: "75DFFF")
        case .pending: return .white.opacity(0.55)
        case .locked: return .white.opacity(0.25)
        }
    }

    var buttonIcon: String {
        switch status {
        case .locked: return "lock.fill"
        default: return "play.fill"
        }
    }

    var buttonTint: Color {
        switch status {
        case .completed: return Color(hex: "0EB060")
        case .inProgress: return Color(hex: "0A0F0D")
        case .pending: return .white.opacity(0.65)
        case .locked: return .white.opacity(0.3)
        }
    }

    var buttonBackground: Color {
        switch status {
        case .completed: return Color(hex: "0EB060").opacity(0.15)
        case .inProgress: return Color(hex: "0EB060")
        case .pending: return Color.white.opacity(0.06)
        case .locked: return Color.white.opacity(0.04)
        }
    }
}

enum LessonItemStatus {
    case completed
    case inProgress
    case pending
    case locked
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
        case .locked:
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
        case .locked:
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
        case .locked:
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
        case .locked:
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

            Text("Level \(item.level)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(item.isLocked ? 0.35 : 0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}

#Preview {
    LessonDetailView(lessonId: "astronomy")
}
