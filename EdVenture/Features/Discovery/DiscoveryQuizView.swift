import SwiftUI

// MARK: - Discovery Quiz View
// Displays quiz questions generated from scanned educational content

struct DiscoveryQuizView: View {
    @ObservedObject var viewModel: DiscoveryViewModel
    @State private var selectedAnswerIndex: Int?
    @State private var showFeedback = false
    @State private var isCorrect = false
    @State private var currentQuestionIndex = 0
    @State private var correctCount = 0
    @State private var reviewItems: [DiscoveryReviewItem] = []
    @Environment(\.dismiss) var dismiss
    
    var currentQuestion: EVDiscoveryQuizQuestion? {
        guard currentQuestionIndex < (viewModel.educationalContent?.quizQuestions.count ?? 0) else {
            return nil
        }
        return viewModel.educationalContent?.quizQuestions[currentQuestionIndex]
    }
    
    var progress: Float {
        guard let totalQuestions = viewModel.educationalContent?.quizQuestions.count,
              totalQuestions > 0 else {
            return 0
        }
        return Float(currentQuestionIndex + 1) / Float(totalQuestions)
    }
    
    var body: some View {
        ZStack {
            Color(hex: "0A0F0D").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    EVBackButton(title: "Back", action: { dismiss() }, compactTitleSize: 15)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Question \(currentQuestionIndex + 1) of \(viewModel.educationalContent?.quizQuestions.count ?? 0)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                        
                        ProgressView(value: progress)
                            .tint(Color(hex: "0EB060"))
                            .frame(width: 80)
                    }
                }
                .padding(16)
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                // Question Content
                if let question = currentQuestion {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Question Text
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Question")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color(hex: "0EB060"))
                                
                                Text(question.question)
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .lineSpacing(2)
                            }
                            
                            // Answer Options
                            VStack(spacing: 10) {
                                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                                    quizOptionButton(
                                        index: index,
                                        text: option,
                                        isSelected: selectedAnswerIndex == index,
                                        isCorrect: showFeedback && index == question.correctAnswerIndex,
                                        isWrong: showFeedback && selectedAnswerIndex == index && index != question.correctAnswerIndex
                                    ) {
                                        if !showFeedback {
                                            selectedAnswerIndex = index
                                            submitAnswer(index, correctIndex: question.correctAnswerIndex)
                                        }
                                    }
                                }
                            }
                            
                            // Feedback Section
                            if showFeedback {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(isCorrect ? Color(hex: "0EB060") : Color(hex: "FF6B6B"))
                                        
                                        Text(isCorrect ? "Correct!" : "Incorrect")
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            .foregroundColor(isCorrect ? Color(hex: "0EB060") : Color(hex: "FF6B6B"))
                                    }
                                    
                                    Text(currentQuestion?.explanation ?? "")
                                        .font(.system(size: 14, weight: .regular, design: .rounded))
                                        .foregroundColor(.white.opacity(0.8))
                                        .lineSpacing(2)
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill((isCorrect ? Color(hex: "0EB060") : Color(hex: "FF6B6B")).opacity(0.15))
                                )
                            }
                        }
                        .padding(16)
                    }
                    
                    Spacer()
                    
                    // Next Button
                    if showFeedback {
                        Button(action: nextQuestion) {
                            HStack {
                                Text(currentQuestionIndex < (viewModel.educationalContent?.quizQuestions.count ?? 1) - 1 ? "Next Question" : "Complete Quiz")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                
                                Image(systemName: currentQuestionIndex < (viewModel.educationalContent?.quizQuestions.count ?? 1) - 1 ? "arrow.right" : "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "0EB060"))
                            .cornerRadius(12)
                        }
                        .padding(16)
                    }
                } else {
                    // Quiz Complete
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(Color(hex: "0EB060"))
                        
                        Text("Quiz Complete!")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("You've successfully answered all questions about this topic.")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        Button(action: { dismiss() }) {
                            Text("Back to Discovery")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(hex: "0EB060"))
                                .cornerRadius(12)
                        }
                        .padding(16)
                        
                        Spacer()
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Helper Views
    
    private func quizOptionButton(
        index: Int,
        text: String,
        isSelected: Bool,
        isCorrect: Bool,
        isWrong: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(
                            borderColor(isSelected: isSelected, isCorrect: isCorrect, isWrong: isWrong),
                            lineWidth: 2
                        )
                        .background(
                            Circle()
                                .fill(backgroundColor(isSelected: isSelected, isCorrect: isCorrect, isWrong: isWrong))
                        )
                    
                    if isCorrect {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    } else if isWrong {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    } else if isSelected && !showFeedback {
                        Circle()
                            .fill(Color(hex: "0EB060"))
                            .frame(width: 8, height: 8)
                    }
                }
                .frame(width: 32, height: 32)
                
                Text(text)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        borderColor(isSelected: isSelected, isCorrect: isCorrect, isWrong: isWrong),
                        lineWidth: 2
                    )
            )
            .opacity(isWrong && showFeedback ? 0.5 : 1.0)
        }
        .disabled(showFeedback)
    }
    
    private func borderColor(isSelected: Bool, isCorrect: Bool, isWrong: Bool) -> Color {
        if isCorrect {
            return Color(hex: "0EB060")
        } else if isWrong {
            return Color(hex: "FF6B6B")
        } else if isSelected {
            return Color(hex: "0EB060")
        } else {
            return Color.white.opacity(0.2)
        }
    }
    
    private func backgroundColor(isSelected: Bool, isCorrect: Bool, isWrong: Bool) -> Color {
        if isCorrect {
            return Color(hex: "0EB060").opacity(0.2)
        } else if isWrong {
            return Color(hex: "FF6B6B").opacity(0.2)
        } else if isSelected {
            return Color(hex: "0EB060").opacity(0.1)
        } else {
            return Color.clear
        }
    }
    
    // MARK: - Actions
    
    private func submitAnswer(_ selectedIndex: Int, correctIndex: Int) {
        isCorrect = selectedIndex == correctIndex
        if isCorrect {
            correctCount += 1
        }
        if let question = currentQuestion {
            let item = DiscoveryReviewItem(
                id: question.id,
                order: currentQuestionIndex,
                question: question.question,
                options: question.options,
                selectedIndex: selectedIndex,
                correctIndex: question.correctAnswerIndex,
                explanation: question.explanation
            )
            if !reviewItems.contains(where: { $0.id == item.id }) {
                reviewItems.append(item)
            }
        }
        withAnimation(.easeInOut(duration: 0.3)) {
            showFeedback = true
        }
    }
    
    private func nextQuestion() {
        if currentQuestionIndex < (viewModel.educationalContent?.quizQuestions.count ?? 0) - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentQuestionIndex += 1
                selectedAnswerIndex = nil
                showFeedback = false
            }
        } else {
            Task {
                let total = viewModel.educationalContent?.quizQuestions.count ?? 0
                await MainActor.run {
                    viewModel.discoveryReviewItems = reviewItems.sorted { $0.order < $1.order }
                }
                await viewModel.completeDiscoveryQuiz(correctCount: correctCount, totalCount: total)
                await MainActor.run {
                    viewModel.isShowingDiscoverySummary = true
                }
            }
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = DiscoveryViewModel()
    viewModel.educationalContent = EducationalContent(
        id: "preview",
        title: "The Trial",
        detectedObjectName: "Book Cover",
        category: "philosophy",
        shortSummary: "A philosophical novel exploring bureaucracy",
        educationalFacts: ["Published 1925", "Written by Kafka"],
        difficultyLevel: "Advanced",
        keyLearningPoints: ["Existentialism", "Surrealism"],
        quizQuestions: [
            EVDiscoveryQuizQuestion(
                id: "q1",
                question: "Who is the main character of The Trial?",
                options: ["Josef K.", "Josef P.", "Joseph K.", "John K."],
                correctAnswerIndex: 0,
                explanation: "The protagonist's name is Josef K., whose mysterious trial forms the novel's central narrative."
            ),
            EVDiscoveryQuizQuestion(
                id: "q2",
                question: "What literary style is The Trial known for?",
                options: ["Realism", "Surrealism", "Romanticism", "Classicism"],
                correctAnswerIndex: 1,
                explanation: "The Trial is a masterpiece of surrealist literature, featuring absurd and dreamlike narrative elements."
            ),
            EVDiscoveryQuizQuestion(
                id: "q3",
                question: "When was The Trial published?",
                options: ["1915", "1925", "1935", "1945"],
                correctAnswerIndex: 1,
                explanation: "Although written earlier, The Trial was first published in 1925, posthumously edited by Max Brod."
            )
        ],
        arOverlayCaption: "The Trial - A philosophical exploration",
        extractedText: "The Trial",
        generatedAt: Date()
    )
    
    return DiscoveryQuizView(viewModel: viewModel)
}
