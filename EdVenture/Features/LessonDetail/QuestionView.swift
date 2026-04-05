import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

struct QuestionView: View {
    let lessonId: String
    let questionIndex: Int
    var onBack: (() -> Void)?

        @State private var navigateToTutorial = false
    @State private var showTutorial = false
    @State private var currentTutorialStep = 0
    @State private var selectedAnswer: String?
    @State private var showHint = false
    @State private var timeRemaining = 3599 // 1 hour in seconds
    @State private var timerActive = true
    
    @StateObject private var vm = QuestionViewModel()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color(hex: "0A0F0D").ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
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

                    // Help button
                        NavigationLink(destination: TutorialQuestionView(onBack: {
                            navigateToTutorial = false
                        })) {
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

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Timer
                        timerCard
                            .padding(.horizontal, 20)

                        // Question Image/Content
                        questionContentCard
                            .padding(.horizontal, 20)

                        // Question Text
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Can you name the author of this book?")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)

                        // Answer Options
                        answersGrid
                            .padding(.horizontal, 20)

                        // Hint Button
                        hintButton
                            .padding(.horizontal, 20)

                        // Next Question Button
                        nextButton
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)

                        // Hint Section
                        if showHint {
                            hintSection
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)
                        }
                    }
                }
            }

            // Interactive Tutorial with Spotlight
            if showTutorial {
                spotlightTutorialOverlay
            }
        }
        .navigationBarHidden(true)
        .onReceive(timer) { _ in
            if timerActive && timeRemaining > 0 {
                timeRemaining -= 1
            }
        }
    }

    // MARK: - Subviews

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
        Image("EdVentureLogo")
            .resizable()
            .scaledToFit()
            .frame(height: 200)
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
            )
    }

    private var answersGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                answerButton("George Orwell", isSelected: selectedAnswer == "george")
                answerButton("Franz Kafka", isSelected: selectedAnswer == "franz")
            }
            HStack(spacing: 12) {
                answerButton("Ernest Hemingway", isSelected: selectedAnswer == "ernest")
                answerButton("Virginia Woolf", isSelected: selectedAnswer == "virginia")
            }
        }
    }

    private func answerButton(_ text: String, isSelected: Bool) -> some View {
        Button {
            selectedAnswer = text.lowercased().split(separator: " ").first.map(String.init)
        } label: {
            Text(text)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(isSelected ? Color(hex: "0EB060") : .white.opacity(0.8))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? Color(hex: "0EB060").opacity(0.15) : Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(isSelected ? Color(hex: "0EB060").opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
        }
    }

    private var hintButton: some View {
        Button {
            showHint.toggle()
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
    }

    private var nextButton: some View {
        Button {
            // Handle next question
        } label: {
            Text("Next Question")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color(hex: "0EB060"))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var hintSection: some View {
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

            Text("Consider the era of the author's most famous works. This book explores the absurdity of bureaucracy and the human condition in a way that defined 20th-century literature.")
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

    // MARK: - Interactive Spotlight Tutorial

    private var spotlightTutorialOverlay: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            // Spotlight regions - drawn as shapes to highlight different parts
            Canvas { context, size in
                // Create a spotlight effect by drawing circles with clear regions
                var path = Path(CGRect(x: 0, y: 0, width: size.width, height: size.height))
                
                // Spotlight position changes based on step
                let spotlightFrame = spotlightFrame(for: currentTutorialStep)
                let spotlightPath = Path(roundedRect: spotlightFrame, cornerRadius: 16)
                path.addPath(spotlightPath)
                
                context.fill(path, with: .color(.black.opacity(0.7)))
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Tutorial explanation box at bottom
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: tutorialSteps[currentTutorialStep].icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(Color(hex: "0EB060"))
                            .frame(width: 40, height: 40)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(tutorialSteps[currentTutorialStep].title)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Text(tutorialSteps[currentTutorialStep].description)
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(.white.opacity(0.75))
                                .lineSpacing(1)
                        }

                        Spacer()
                    }

                    // Navigation buttons
                    HStack(spacing: 12) {
                        if currentTutorialStep > 0 {
                            Button {
                                currentTutorialStep -= 1
                            } label: {
                                Text("Previous")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(Color.white.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }

                        Button {
                            if currentTutorialStep < tutorialSteps.count - 1 {
                                currentTutorialStep += 1
                            } else {
                                showTutorial = false
                            }
                        } label: {
                            Text(currentTutorialStep == tutorialSteps.count - 1 ? "Got it!" : "Next")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color(hex: "0EB060"))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }

                    // Step indicators
                    HStack(spacing: 6) {
                        ForEach(0..<tutorialSteps.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentTutorialStep ? Color(hex: "0EB060") : Color.white.opacity(0.25))
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(hex: "1A2420"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color(hex: "0EB060").opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
    }

    private func spotlightFrame(for step: Int) -> CGRect {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        switch step {
        case 0: // Timer
            return CGRect(x: screenWidth / 2 - 100, y: 100, width: 200, height: 80)
        case 1: // Question Image
            return CGRect(x: 20, y: 160, width: screenWidth - 40, height: 200)
        case 2: // Answer Options
            return CGRect(x: 20, y: 420, width: screenWidth - 40, height: 180)
        case 3: // Hint Button
            return CGRect(x: screenWidth / 2 - 60, y: 640, width: 120, height: 50)
        case 4: // Next Question Button
            return CGRect(x: 20, y: 710, width: screenWidth - 40, height: 56)
        default:
            return CGRect(x: 0, y: 0, width: 0, height: 0)
        }
    }

    private let tutorialSteps: [(title: String, description: String, icon: String)] = [
        (
            title: "📝 Question Screen",
            description: "Welcome to the quiz! This screen shows questions one at a time. Read carefully and select the correct answer from the options below.",
            icon: "questionmark.bubble.fill"
        ),
        (
            title: "⏱️ Timer",
            description: "You have a limited time to complete this quiz. The timer at the top shows your remaining hours, minutes, and seconds.",
            icon: "timer"
        ),
        (
            title: "🎯 Select an Answer",
            description: "Choose the correct answer by tapping one of the four options. Your selection will be highlighted in green.",
            icon: "checkmark.circle.fill"
        ),
        (
            title: "💡 Get a Hint",
            description: "If you're stuck, tap the 'GET HINT' button to receive an expert hint that may help you find the correct answer.",
            icon: "lightbulb.fill"
        ),
        (
            title: "➡️ Next Question",
            description: "Once you've selected an answer, tap 'Next Question' to move to the next quiz question.",
            icon: "arrow.right.circle.fill"
        )
    ]
}

@MainActor
final class QuestionViewModel: ObservableObject {
    @Published var isLoading = false
}

#Preview {
    QuestionView(lessonId: "astronomy", questionIndex: 0)
}
