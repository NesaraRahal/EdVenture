import SwiftUI
import FirebaseFirestore
import UIKit
import Combine

struct QuestionView: View {
    let lessonId: String
    let questionIndex: Int
    var onBack: (() -> Void)?

    @State private var selectedAnswerIndex: Int?
    @State private var didSubmit = false
    @State private var showHint = false
    @State private var timeRemaining = 3599 // 1 hour in seconds
    @State private var timerActive = true
    
    @StateObject private var vm = QuestionViewModel()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color(hex: "0A0F0D").ignoresSafeArea()

            VStack(spacing: 0) {
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
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 18)
                        .frame(height: 44)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .frame(minWidth: 44, minHeight: 44)

                    Spacer()

                    NavigationLink(destination: TutorialQuestionView()) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "0EB060"))
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                        }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)

                if vm.isLoading {
                    Spacer()
                    ProgressView()
                        .tint(Color(hex: "0EB060"))
                        .scaleEffect(1.2)
                    Spacer()
                } else if let error = vm.errorMessage {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white.opacity(0.65))
                        Text(error)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    Spacer()
                } else if let question = vm.question {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            timerCard
                                .padding(.horizontal, 20)

                            questionContentCard
                                .padding(.horizontal, 20)

                            VStack(alignment: .leading, spacing: 12) {
                                Text(question.prompt)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)

                            answersGrid(question)
                                .padding(.horizontal, 20)

                            hintButton
                                .padding(.horizontal, 20)

                            if showHint {
                                hintSection(question)
                                    .padding(.horizontal, 20)
                            }

                            if didSubmit {
                                resultCard(question)
                                    .padding(.horizontal, 20)
                            }

                            nextButton
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .task(id: lessonId) {
            await vm.loadFirstRoundQuestion(lessonId: lessonId)
            resetRoundState()
        }
        .onReceive(timer) { _ in
            if timerActive && timeRemaining > 0 {
                timeRemaining -= 1
            }
        }
    }

    private func resetRoundState() {
        selectedAnswerIndex = nil
        didSubmit = false
        showHint = false
        timeRemaining = 3599
        timerActive = true
    }

    private var timerCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .center, spacing: 2) {
                Text("\(String(format: "%02d", timeRemaining / 3600))")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("HOURS")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .center, spacing: 2) {
                Text("\(String(format: "%02d", (timeRemaining % 3600) / 60))")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("MINUTES")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .center, spacing: 2) {
                Text("\(String(format: "%02d", timeRemaining % 60))")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("SECONDS")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .frame(height: 72)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color.white.opacity(0.045), Color(hex: "0EB060").opacity(0.02)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color(hex: "0EB060").opacity(0.22), lineWidth: 0.6)
                )
        )
    }

    private var questionContentCard: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.05), Color(hex: "0EB060").opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 230)
            .overlay {
                VStack(spacing: 10) {
                    Image(systemName: lessonSymbol)
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundColor(Color(hex: "0EB060"))
                    Text(lessonId.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
    }

    private var lessonSymbol: String {
        switch lessonId.lowercased() {
        case "astronomy": return "sparkles"
        case "history": return "hourglass"
        case "biology": return "leaf"
        case "physics": return "atom"
        case "literature": return "book"
        default: return "questionmark.circle"
        }
    }

    private func answersGrid(_ question: QuizQuestion) -> some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Array(question.choices.enumerated()), id: \.offset) { index, choice in
                answerButton(choice, at: index)
            }
        }
    }

    private func answerButton(_ text: String, at index: Int) -> some View {
        let isSelected = selectedAnswerIndex == index
        let isCorrect = vm.question?.correctIndex == index
        let showCorrectState = didSubmit && isCorrect
        let showWrongState = didSubmit && isSelected && !isCorrect

        return Button {
            guard !didSubmit else { return }
            selectedAnswerIndex = index
            EVAccessibilitySupport.playSound(.click)
        } label: {
            Text(text)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(showCorrectState ? Color(hex: "0EB060") : .white.opacity(0.86))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 76)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(answerBackgroundColor(isSelected: isSelected, showCorrect: showCorrectState, showWrong: showWrongState))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(answerBorderColor(isSelected: isSelected, showCorrect: showCorrectState, showWrong: showWrongState), lineWidth: 1)
                        )
                )
        }
        .disabled(didSubmit)
    }

    private func answerBackgroundColor(isSelected: Bool, showCorrect: Bool, showWrong: Bool) -> Color {
        if showCorrect { return Color(hex: "0EB060").opacity(0.18) }
        if showWrong { return Color.red.opacity(0.16) }
        if isSelected { return Color(hex: "0EB060").opacity(0.14) }
        return Color.white.opacity(0.06)
    }

    private func answerBorderColor(isSelected: Bool, showCorrect: Bool, showWrong: Bool) -> Color {
        if showCorrect { return Color(hex: "0EB060").opacity(0.6) }
        if showWrong { return Color.red.opacity(0.5) }
        if isSelected { return Color(hex: "0EB060").opacity(0.35) }
        return Color.white.opacity(0.1)
    }

    private var hintButton: some View {
        Button {
            guard !didSubmit else { return }
            showHint.toggle()
            if showHint {
                EVAccessibilitySupport.playSound(.hint)
            } else {
                EVAccessibilitySupport.playSound(.click)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 13, weight: .semibold))
                Text("GET HINT")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundColor(Color(hex: "0EB060"))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(hex: "0EB060").opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color(hex: "0EB060").opacity(0.3), lineWidth: 1)
                    )
            )
        }
            .disabled(didSubmit)
    }

    private var nextButton: some View {
        Button {
                guard let question = vm.question else { return }

                if didSubmit {
                    EVAccessibilitySupport.playSound(.next)
                    onBack?()
                    return
                }

                guard selectedAnswerIndex != nil else {
                    EVAccessibilitySupport.playSound(.click)
                    return
                }

                didSubmit = true
                timerActive = false
                showHint = false

                if selectedAnswerIndex == question.correctIndex {
                    EVAccessibilitySupport.playSound(.correct)
                } else {
                    EVAccessibilitySupport.playSound(.wrong)
                }
        } label: {
                Text(didSubmit ? "Finish Round" : "Submit Answer")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color(hex: "0EB060"))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func hintSection(_ question: QuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "0EB060"))
                Text("EXPERT HINT")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "0EB060"))
                Spacer()
                Button {
                    showHint = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

                Text("Focus on the time period, the tone of the writing, and the type of story the prompt describes. Use those clues to eliminate options that do not fit.")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(2)

            Button {
                showHint = false
            } label: {
                Text("Close Hint")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color(hex: "0EB060"))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color(hex: "0EB060").opacity(0.2), lineWidth: 0.5)
                )
        )
    }

    private func resultCard(_ question: QuizQuestion) -> some View {
        let isCorrect = selectedAnswerIndex == question.correctIndex

        return VStack(alignment: .leading, spacing: 8) {
            Text(isCorrect ? "✅ Correct" : "❌ Wrong")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(isCorrect ? Color(hex: "0EB060") : Color.red.opacity(0.9))

            Text(question.explanation)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.white.opacity(0.82))
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke((isCorrect ? Color(hex: "0EB060") : Color.red).opacity(0.28), lineWidth: 0.7)
                )
        )
    }
}

@MainActor
final class QuestionViewModel: ObservableObject {
    @Published var question: QuizQuestion?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    func loadFirstRoundQuestion(lessonId: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let firstId = "\(lessonId)_L01_Q01"
            let firstSnapshot = try await db
                .collection("lessons")
                .document(lessonId)
                .collection("questions")
                .document(firstId)
                .getDocument()

            if let data = firstSnapshot.data(),
               let parsed = QuizQuestion(id: firstSnapshot.documentID, data: data) {
                question = parsed
                return
            }

            let fallback = try await db
                .collection("lessons")
                .document(lessonId)
                .collection("questions")
                .order(by: "level")
                .order(by: "order")
                .limit(to: 1)
                .getDocuments()

            guard let doc = fallback.documents.first,
                  let parsed = QuizQuestion(id: doc.documentID, data: doc.data()) else {
                errorMessage = "No questions found for this lesson."
                question = nil
                return
            }

            question = parsed
        } catch {
            errorMessage = error.localizedDescription
            question = nil
        }
    }
}

struct QuizQuestion: Identifiable {
    let id: String
    let prompt: String
    let choices: [String]
    let correctIndex: Int
    let explanation: String

    init?(id: String, data: [String: Any]) {
        guard
            let prompt = data["prompt"] as? String,
            let choices = data["choices"] as? [String],
            let correctIndex = data["correctIndex"] as? Int,
            let explanation = data["explanation"] as? String,
            !choices.isEmpty,
            choices.indices.contains(correctIndex)
        else {
            return nil
        }

        self.id = id
        self.prompt = prompt
        self.choices = choices
        self.correctIndex = correctIndex
        self.explanation = explanation
    }
}

#Preview {
    QuestionView(lessonId: "astronomy", questionIndex: 0)
}
