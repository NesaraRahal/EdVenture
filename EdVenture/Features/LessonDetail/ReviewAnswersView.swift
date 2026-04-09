import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

struct ReviewAnswersView: View {
    let lessonId: String
    let attemptSessionId: String
    let score: Int
    let totalQuestions: Int
    let totalTimeSeconds: Int

    var onBack: (() -> Void)?

    @StateObject private var vm = ReviewAnswersViewModel()

    private var scorePercentText: String {
        guard totalQuestions > 0 else { return "0%" }
        let percent = Int((Double(score) / Double(totalQuestions)) * 100.0)
        return "\(percent)%"
    }

    private var timeText: String {
        let safe = max(totalTimeSeconds, 0)
        let minutes = safe / 60
        let seconds = safe % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        ZStack {
            Color(hex: "050B09").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header
                        .padding(.top, 52)
                        .padding(.horizontal, 20)

                    summaryMetrics
                        .padding(.horizontal, 20)

                    if vm.isLoading {
                        ProgressView()
                            .tint(Color(hex: "0EB060"))
                            .frame(maxWidth: .infinity, minHeight: 120)
                    } else if let errorMessage = vm.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(Color(hex: "FF453A"))
                            .padding(.horizontal, 20)
                    } else {
                        VStack(spacing: 14) {
                            ForEach(vm.items) { item in
                                answerCard(item)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 26)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .task(id: attemptSessionId) {
            await vm.load(lessonId: lessonId, attemptSessionId: attemptSessionId)
        }
    }

    private var header: some View {
        HStack {
            Button {
                onBack?()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(height: 44)
                .padding(.horizontal, 16)
                .background(Color.white.opacity(0.12))
                .clipShape(Capsule())
            }

            Spacer()

            Text("Summary")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }

    private var summaryMetrics: some View {
        HStack(spacing: 12) {
            metricBox(title: "SCORE", value: scorePercentText, accent: Color(hex: "0EB060"))
            metricBox(title: "TIME", value: timeText, accent: Color(hex: "38BDF8"))
        }
    }

    private func metricBox(title: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
                .tracking(1)
            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(accent)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.6)
                )
        )
    }

    private func answerCard(_ item: ReviewAnswerItem) -> some View {
        let good = item.isCorrect
        let border = good ? Color(hex: "0EB060").opacity(0.6) : Color(hex: "FF5A52").opacity(0.6)

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Q\(item.order + 1)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(good ? Color(hex: "71F3A6") : Color(hex: "FF7470"))
                Spacer()
                Image(systemName: good ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(good ? Color(hex: "71F3A6") : Color(hex: "FF7470"))
            }

            Text(item.prompt)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)

            if item.isCorrect {
                answerPill(
                    title: "YOUR CHOICE & CORRECT",
                    value: item.selectedChoiceText,
                    accent: Color(hex: "71F3A6"),
                    background: Color(hex: "71F3A6").opacity(0.11)
                )
            } else {
                answerPill(
                    title: "YOUR CHOICE",
                    value: item.selectedChoiceText,
                    accent: Color(hex: "FF7470"),
                    background: Color(hex: "FF7470").opacity(0.11)
                )

                answerPill(
                    title: "CORRECT ANSWER",
                    value: item.correctChoiceText,
                    accent: Color(hex: "71F3A6"),
                    background: Color(hex: "71F3A6").opacity(0.1)
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(border, lineWidth: 0.8)
                )
        )
    }

    private func answerPill(title: String,
                            value: String,
                            accent: Color,
                            background: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(accent)
                .tracking(1)
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(background)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(accent.opacity(0.35), lineWidth: 0.8)
                )
        )
    }
}

struct ReviewAnswerItem: Identifiable {
    let id: String
    let order: Int
    let prompt: String
    let selectedChoiceText: String
    let correctChoiceText: String
    let isCorrect: Bool
}

@MainActor
final class ReviewAnswersViewModel: ObservableObject {
    @Published var items: [ReviewAnswerItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    func load(lessonId: String, attemptSessionId: String) async {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "Please sign in to review answers."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let attemptSnapshot = try await db
                .collection("users")
                .document(uid)
                .collection("quizAttempts")
                .whereField("lessonId", isEqualTo: lessonId)
                .whereField("attemptSessionId", isEqualTo: attemptSessionId)
                .getDocuments()

            let sortedAttempts = attemptSnapshot.documents
                .sorted {
                    let left = ($0.data()["questionIndex"] as? Int) ?? 0
                    let right = ($1.data()["questionIndex"] as? Int) ?? 0
                    return left < right
                }

            var mapped: [ReviewAnswerItem] = []
            for attempt in sortedAttempts {
                let data = attempt.data()
                let questionId = data["questionId"] as? String ?? ""
                let questionIndex = data["questionIndex"] as? Int ?? 0
                let selectedIndex = data["selectedIndex"] as? Int ?? -1
                let correctIndex = data["correctIndex"] as? Int ?? 0
                let isCorrect = data["isCorrect"] as? Bool ?? false

                let questionDoc = try await db
                    .collection("lessons")
                    .document(lessonId)
                    .collection("questions")
                    .document(questionId)
                    .getDocument()

                let qData = questionDoc.data() ?? [:]
                let prompt = qData["prompt"] as? String ?? "Question"
                let choices = qData["choices"] as? [String] ?? []

                let selectedText: String
                if selectedIndex >= 0, choices.indices.contains(selectedIndex) {
                    selectedText = choices[selectedIndex]
                } else {
                    selectedText = "No answer selected"
                }

                let correctText: String
                if choices.indices.contains(correctIndex) {
                    correctText = choices[correctIndex]
                } else {
                    correctText = "Unavailable"
                }

                mapped.append(
                    ReviewAnswerItem(
                        id: attempt.documentID,
                        order: questionIndex,
                        prompt: prompt,
                        selectedChoiceText: selectedText,
                        correctChoiceText: correctText,
                        isCorrect: isCorrect
                    )
                )
            }

            items = mapped
            if mapped.isEmpty {
                errorMessage = "No answer review data found for this attempt yet."
            }
        } catch {
            errorMessage = error.localizedDescription
            items = []
        }
    }
}

#Preview {
    ReviewAnswersView(
        lessonId: "astronomy",
        attemptSessionId: "session-preview",
        score: 8,
        totalQuestions: 10,
        totalTimeSeconds: 760
    )
}
