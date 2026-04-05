import SwiftUI

struct TutorialQuestionView: View {
    var onBack: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    @State private var selectedAnswer: String?
    @State private var showHint = false
    @State private var showCompletion = false
    @State private var isAutoPlaying = false
    @State private var demoStatus: DemoStatus = .idle
    @State private var demoRunID = UUID()

    private let correctAnswer = "Franz Kafka"

    var body: some View {
        ZStack {
            Color(hex: "0A0F0D").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    topBar
                        .padding(.horizontal, 20)
                        .padding(.top, 52)

                    Text(coachMessage)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "0EB060"))
                        .lineSpacing(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 18)
                        .padding(.bottom, 6)

                    Text(stepNote)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.white.opacity(0.72))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)

                    VStack(spacing: 20) {
                        quizPreview
                            .padding(.horizontal, 20)

                        if showHint {
                            hintSection
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }

            if showCompletion {
                completionOverlay
            }
        }
        .navigationBarHidden(true)
        .task(id: demoRunID) {
            await runDemo(runID: demoRunID)
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                onBack?()
                dismiss()
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

            Button {
                demoRunID = UUID()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "play.fill")
                    Text("Replay")
                }
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.black)
                .padding(.horizontal, 12)
                .frame(height: 36)
                .background(Color(hex: "0EB060"))
                .clipShape(Capsule())
            }
            .disabled(isAutoPlaying)
            .opacity(isAutoPlaying ? 0.5 : 1)
        }
    }

    private var quizPreview: some View {
        VStack(spacing: 20) {
            timerCard

            questionContentCard

            Text("Can you name the\nauthor of this book?")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            answersGrid

            if let feedback = feedbackText {
                Text(feedback)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(feedbackColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(feedbackColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            Button {
                showHint.toggle()
                if showHint {
                    demoStatus = .showingHint
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
                .frame(width: 140, height: 40)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
            }
            .disabled(isAutoPlaying)

            Button {
                guard selectedAnswer != nil else { return }
                showCompletion = true
                demoStatus = .complete
                EVAccessibilitySupport.playSound(.next)
            } label: {
                Text(selectedAnswer == nil ? "Select an answer" : "Next Question")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(selectedAnswer == nil ? Color.white.opacity(0.25) : Color(hex: "0EB060"))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
                    .disabled(selectedAnswer == nil || isAutoPlaying)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.6)
                )
        )
    }

    private var timerCard: some View {
        HStack(spacing: 16) {
            timerBlock(value: "1", label: "HOURS")
            timerBlock(value: "59", label: "MINUTES")
            timerBlock(value: "59", label: "SECONDS")
        }
        .padding(.horizontal, 16)
        .frame(height: 72)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.6)
                )
        )
    }

    private func timerBlock(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }

    private var questionContentCard: some View {
        Image("EdVentureLogo")
            .resizable()
            .scaledToFit()
            .frame(height: 200)
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
            )
    }

    private var answersGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                answerButton("George\nOrwell")
                answerButton("Franz\nKafka")
            }
            HStack(spacing: 12) {
                answerButton("Ernest\nHemingway")
                answerButton("Virginia\nWoolf")
            }
        }
    }

    private func answerButton(_ text: String) -> some View {
        let answer = text.replacingOccurrences(of: "\n", with: " ")
        let isSelected = selectedAnswer == answer
        let isCorrect = answer == correctAnswer

        return Button {
            selectedAnswer = answer
            demoStatus = isCorrect ? .correctSelected : .wrongSelected
            showCompletion = false
            EVAccessibilitySupport.playSound(isCorrect ? .correct : .wrong)
        } label: {
            Text(text)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(
                    isSelected
                    ? (isCorrect ? Color(hex: "0EB060") : .red)
                    : .white.opacity(0.85)
                )
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            isSelected
                            ? (isCorrect ? Color(hex: "0EB060").opacity(0.15) : Color.red.opacity(0.12))
                            : Color.white.opacity(0.06)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(
                                    isSelected
                                    ? (isCorrect ? Color(hex: "0EB060").opacity(0.5) : Color.red.opacity(0.7))
                                    : Color.white.opacity(0.1),
                                    lineWidth: 1
                                )
                        )
                )
        }
        .disabled(isAutoPlaying)
    }

    private var hintSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "0EB060"))
                    .frame(width: 34, height: 34)
                    .background(Color(hex: "0EB060").opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text("Visual Clue")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "0EB060"))
                    Text("Use the category and the clue to narrow the options.")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                Button {
                    showHint = false
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            Text("Think about the literary movement, the time period, and the kind of story the prompt describes. Choose the author whose work best fits those clues.")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.white.opacity(0.75))
                .lineSpacing(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color(hex: "0EB060").opacity(0.25), lineWidth: 0.8)
                )
        )
    }

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: selectedAnswer == correctAnswer ? "checkmark.circle.fill" : "hand.thumbsup.fill")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(Color(hex: "0EB060"))

                Text("Demo Complete")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("You just watched: wrong answer → hint → correct answer.")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)

                Button {
                    onBack?()
                    dismiss()
                } label: {
                    Text("Finish Tutorial")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(hex: "0EB060"))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(hex: "1A2420"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color(hex: "0EB060").opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
        }
    }

    private var coachMessage: String {
        switch demoStatus {
        case .idle:
            return "Demo starts automatically: wrong answer → hint → correct answer."
        case .wrongSelected:
            return "Step 1: Wrong answer selected."
        case .wrongFeedback:
            return "Wrong feedback shown. Next, hint is opened."
        case .showingHint:
            return "Step 2: Hint appears to guide the user."
        case .correctSelected:
            return "Step 3: Correct answer selected after hint."
        case .complete:
            return "Tutorial round complete."
        }
    }

    private var stepNote: String {
        switch demoStatus {
        case .idle:
            return "Watch the flow first, then tap Replay anytime."
        case .wrongSelected:
            return "A wrong option is highlighted in red to show error feedback."
        case .wrongFeedback:
            return "The app suggests using a hint before trying again."
        case .showingHint:
            return "Hint panel appears with a clue related to the correct author."
        case .correctSelected:
            return "Correct option turns green to confirm success."
        case .complete:
            return "That’s one full tutorial round from mistake to success."
        }
    }

    private var feedbackText: String? {
        switch demoStatus {
        case .wrongSelected, .wrongFeedback:
            return "Not quite. Use hint and try again."
        case .correctSelected, .complete:
            return "Correct! Great job."
        default:
            return nil
        }
    }

    private var feedbackColor: Color {
        switch demoStatus {
        case .wrongSelected, .wrongFeedback:
            return .red
        case .correctSelected, .complete:
            return Color(hex: "0EB060")
        default:
            return .white
        }
    }

    private func runDemo(runID: UUID) async {
        isAutoPlaying = true
        selectedAnswer = nil
        showHint = false
        showCompletion = false
        demoStatus = .idle

        guard await pauseAndValidate(runID, seconds: 1.5) else { return }
        selectedAnswer = "George Orwell"
        demoStatus = .wrongSelected
        EVAccessibilitySupport.playSound(.wrong)

        guard await pauseAndValidate(runID, seconds: 1.8) else { return }
        demoStatus = .wrongFeedback

        guard await pauseAndValidate(runID, seconds: 1.8) else { return }
        showHint = true
        demoStatus = .showingHint
        EVAccessibilitySupport.playSound(.hint)

        guard await pauseAndValidate(runID, seconds: 2.0) else { return }
        selectedAnswer = correctAnswer
        demoStatus = .correctSelected
        EVAccessibilitySupport.playSound(.correct)

        guard await pauseAndValidate(runID, seconds: 1.8) else { return }
        showCompletion = true
        demoStatus = .complete
        EVAccessibilitySupport.playSound(.next)
        isAutoPlaying = false
    }

    private func pauseAndValidate(_ runID: UUID, seconds: Double) async -> Bool {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        return self.demoRunID == runID
    }
}

private enum DemoStatus {
    case idle
    case wrongSelected
    case wrongFeedback
    case showingHint
    case correctSelected
    case complete
}

#Preview {
    TutorialQuestionView()
}
