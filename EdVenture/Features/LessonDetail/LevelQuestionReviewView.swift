import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

struct LevelQuestionReviewView: View {
    let lessonId: String
    let questionId: String
    var onBack: (() -> Void)?

    @StateObject private var vm = LevelQuestionReviewViewModel()

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
            } else if let question = vm.question {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        topBar
                            .padding(.horizontal, 20)
                            .padding(.top, 52)

                        questionCard(question)
                            .padding(.horizontal, 20)

                        answerList(question)
                            .padding(.horizontal, 20)

                        explanationCard(question)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 28)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .task(id: "\(lessonId)-\(questionId)") {
            await vm.load(lessonId: lessonId, questionId: questionId)
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

            Text("Review")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            Color.clear
                .frame(width: 60, height: 44)
        }
    }

    private func questionCard(_ question: EVQuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Question")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "0EB060"))
                .tracking(1.2)

            Text(question.prompt)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineSpacing(2)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.6)
                )
        )
    }

    private func answerList(_ question: EVQuizQuestion) -> some View {
        VStack(spacing: 12) {
            ForEach(Array(question.choices.enumerated()), id: \.offset) { index, choice in
                let isCorrect = index == question.correctIndex
                let isSelected = index == vm.selectedIndex
                HStack(spacing: 12) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : (isSelected ? "circle.fill" : "circle"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isCorrect ? Color(hex: "0EB060") : (isSelected ? Color(hex: "75DFFF") : .white.opacity(0.35)))
                    Text(choice)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    if isSelected {
                        Text("Your Answer")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "75DFFF"))
                            .tracking(0.8)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color(hex: "75DFFF").opacity(0.16))
                            .clipShape(Capsule())
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isCorrect ? Color(hex: "0EB060").opacity(0.12) : (isSelected ? Color(hex: "75DFFF").opacity(0.12) : Color.white.opacity(0.04)))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(isCorrect ? Color(hex: "0EB060").opacity(0.5) : (isSelected ? Color(hex: "75DFFF").opacity(0.4) : Color.white.opacity(0.08)), lineWidth: 0.6)
                        )
                )
            }
        }
    }

    private func explanationCard(_ question: EVQuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Explanation")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "75DFFF"))
                .tracking(1.2)

            Text(question.explanation)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.white.opacity(0.75))
                .lineSpacing(3)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.6)
                )
        )
    }
}

@MainActor
final class LevelQuestionReviewViewModel: ObservableObject {
    @Published var question: EVQuizQuestion?
    @Published var selectedIndex: Int? = nil
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    func load(lessonId: String, questionId: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            if let attempt = try await loadLatestAttempt(lessonId: lessonId, questionId: questionId) {
                question = attempt.question
                selectedIndex = attempt.selectedIndex
                return
            }

            let snapshot = try await db.collection("lessons")
                .document(lessonId)
                .collection("questions")
                .document(questionId)
                .getDocument()

            guard let data = snapshot.data(),
                  let parsed = EVQuizQuestion(id: questionId, data: data) else {
                errorMessage = "Question not found."
                return
            }

            question = parsed
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadLatestAttempt(lessonId: String, questionId: String) async throws -> (question: EVQuizQuestion, selectedIndex: Int?)? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }

        let snapshot = try await db.collection("users")
            .document(uid)
            .collection("quizAttempts")
            .whereField("lessonId", isEqualTo: lessonId)
            .whereField("questionId", isEqualTo: questionId)
            .getDocuments()

        let latest = snapshot.documents.max { lhs, rhs in
            let left = (lhs.data()["answeredAt"] as? Timestamp)?.dateValue() ?? Date.distantPast
            let right = (rhs.data()["answeredAt"] as? Timestamp)?.dateValue() ?? Date.distantPast
            return left < right
        }

        guard let doc = latest else { return nil }
        let data = doc.data()

        let prompt = data["questionPrompt"] as? String
        let choices = data["questionChoices"] as? [String]
        let explanation = data["questionExplanation"] as? String
        let correctIndex = data["correctIndex"] as? Int

        if let prompt,
           let choices,
           let explanation,
           let correctIndex {
            let parsed = EVQuizQuestion(
                id: questionId,
                lessonId: lessonId,
                level: data["level"] as? Int ?? 1,
                order: data["questionIndex"] as? Int ?? 1,
                difficulty: 1,
                xpMin: 0,
                xpMax: 0,
                xpSuggested: 0,
                prompt: prompt,
                choices: choices,
                correctIndex: correctIndex,
                explanation: explanation,
                tags: [],
                isActive: true
            )
            let selected = data["selectedIndex"] as? Int
            return (parsed, selected)
        }

        return nil
    }
}

#Preview {
    LevelQuestionReviewView(lessonId: "astronomy", questionId: "astronomy_L01_Q01")
}
