import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UIKit
import Combine

struct LessonDetailView: View {
    let lessonId: String
    var onBack: (() -> Void)?
    var onStartQuiz: ((_ lessonId: String, _ questionIndex: Int) -> Void)?

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
        VStack(alignment: .leading, spacing: 14) {
            Text("CURRICULUM")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .tracking(2)

            ForEach(Array(vm.items.enumerated()), id: \.element.id) { index, item in
                Button {
                    guard !item.isLocked else { return }
                    // One-round gameplay starts from first question for now.
                    onStartQuiz?(lesson.id, 0)
                } label: {
                    HStack(spacing: 14) {
                        Text(String(format: "%02d", index + 1))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(item.statusColor)
                            .frame(width: 48, alignment: .leading)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.title)
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(item.isLocked ? .white.opacity(0.35) : .white)
                                .lineLimit(2)

                            Text(item.meta)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(item.statusColor)
                        }

                        Spacer()

                        Image(systemName: item.buttonIcon)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(item.buttonTint)
                            .frame(width: 56, height: 56)
                            .background(item.buttonBackground)
                            .clipShape(Circle())
                    }
                    .padding(.horizontal, 18)
                    .frame(minHeight: 94)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.white.opacity(0.035))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(item.isLocked ? Color.white.opacity(0.04) : Color.white.opacity(0.08), lineWidth: 0.6)
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(item.isLocked)
            }
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
            if let uid = Auth.auth().currentUser?.uid {
                let active = try await db.collection("users").document(uid)
                    .collection("activeLessons").document(lessonId).getDocument()
                progress = min(max(active.data()?["progress"] as? Double ?? 0, 0), 1)
            }

            let completed = min(Int((progress * Double(totalLevels)).rounded(.down)), totalLevels)
            let pending = min(max(totalLevels - completed, 0), 3)
            let locked = max(totalLevels - completed - pending, 0)

            lesson = LessonDetail(
                id: lessonId,
                title: (title?.isEmpty == false ? title! : "Untitled"),
                icon: icon,
                colorHex: (colorHex?.isEmpty == false ? colorHex! : "0EB060"),
                xpReward: xpReward,
                totalLevels: totalLevels,
                progress: progress,
                completedCount: completed,
                pendingCount: pending,
                lockedCount: locked
            )

            items = buildCurriculumItems(totalLevels: totalLevels, completed: completed, pending: pending, xpReward: xpReward, lessonTitle: lesson?.title ?? "Lesson")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func resolveIcon(_ icon: String?) -> String {
        let candidate = (icon?.isEmpty == false ? icon! : "book.fill")
        return UIImage(systemName: candidate) == nil ? "book.fill" : candidate
    }

    private func buildCurriculumItems(totalLevels: Int,
                                      completed: Int,
                                      pending: Int,
                                      xpReward: Int,
                                      lessonTitle: String) -> [LessonCurriculumItem] {
        let displayCount = min(max(totalLevels, 4), 12)

        return (1...displayCount).map { index in
            let status: LessonItemStatus
            if index <= completed {
                status = .completed
            } else if index <= completed + pending {
                status = index == completed + 1 ? .inProgress : .pending
            } else {
                status = .locked
            }

            return LessonCurriculumItem(
                id: "\(index)",
                title: "\(lessonTitle) Quiz \(index)",
                meta: "\(xpReward) XP • \(index <= 2 ? "1" : "3") MIN",
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

#Preview {
    LessonDetailView(lessonId: "astronomy")
}
