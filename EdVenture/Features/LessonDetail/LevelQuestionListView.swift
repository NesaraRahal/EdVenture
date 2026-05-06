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
        }
        .navigationBarHidden(true)
        .task(id: "\(lessonId)-\(level)") {
            await vm.load(lessonId: lessonId, level: level)
        }
    }

    private var topBar: some View {
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
                .foregroundColor(.white.opacity(0.92))
                .padding(.horizontal, 18)
                .frame(height: 44)
                .background(Color.white.opacity(0.1))
                .clipShape(Capsule())
            }

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
                        onSelectQuestion?(index)
                    }
                )
            }
        }
    }
}

struct LevelQuestionListItem: Identifiable {
    let id: String
    let title: String
    let xp: Int
    let status: LevelQuestionStatus
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
        switch item.status {
        case .completed: return Color(hex: "0EB060")
        case .inProgress: return Color(hex: "75DFFF")
        case .pending: return Color.white.opacity(0.55)
        case .failed: return Color(hex: "F6CC2E")
        }
    }

    private var statusText: String {
        switch item.status {
        case .completed: return "COMPLETED"
        case .inProgress: return "IN PROGRESS"
        case .pending: return "PENDING"
        case .failed: return "FAILED"
        }
    }

    private var statusIcon: String {
        switch item.status {
        case .completed: return "checkmark.circle.fill"
        case .inProgress: return "play.circle.fill"
        case .pending: return "circle"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }

    private var primaryActionTitle: String {
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

                Image(systemName: "play.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "0A0F0D"))
                    .frame(width: 36, height: 36)
                    .background(accent.opacity(item.status == .pending ? 0.12 : 0.9))
                    .clipShape(Circle())
            }

            HStack(spacing: 10) {
                Button(action: onReplay) {
                    Text(primaryActionTitle)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "0A0F0D"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color(hex: "0EB060"))
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
}

@MainActor
final class LevelQuestionListViewModel: ObservableObject {
    @Published var items: [LevelQuestionListItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lessonTitle: String = "Lesson"
    @Published var completedCount: Int = 0
    @Published var pendingCount: Int = 0

    private let store = EVQuizStore()
    private let db = Firestore.firestore()

    func load(lessonId: String, level: Int) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            guard let uid = Auth.auth().currentUser?.uid else {
                errorMessage = "Please sign in to view questions."
                return
            }

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
            let progress = await loadQuestionProgress(lessonId: lessonId)

            var completed = 0
            var failedCount = 0
            let mapped = questions.enumerated().map { _, question in
                let status: LevelQuestionStatus
                if progress.completed.contains(question.id) {
                    status = .completed
                    completed += 1
                } else if progress.attempted.contains(question.id) {
                    // attempted but not completed -> failed (eligible for replay)
                    status = .failed
                    failedCount += 1
                } else {
                    status = .pending
                }

                return LevelQuestionListItem(
                    id: question.id,
                    title: stripPromptPrefix(question.prompt),
                    xp: question.xpSuggested,
                    status: status
                )
            }

            items = mapped
            completedCount = completed
            pendingCount = max(mapped.count - completed - failedCount, 0)
        } catch {
            errorMessage = error.localizedDescription
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
}

#Preview {
    LevelQuestionListView(lessonId: "astronomy", level: 1, totalLevels: 10)
}
