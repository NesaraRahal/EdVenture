import SwiftUI
import FirebaseAuth
import UIKit
import Combine

struct LevelQuizView: View {
    let lessonId: String
    let level: Int
    let questionIndex: Int
    let totalLevels: Int
    let sessionLessonId: String?
    let questionsOverride: [EVQuizQuestion]?
    let lessonTitleOverride: String?
    var onShowSummary: ((String, Int, Int, Int, Int, Int, String, Int) -> Void)?
    var onBack: (() -> Void)?

    @StateObject private var vm = LevelQuizViewModel()

    init(lessonId: String,
         level: Int,
         questionIndex: Int,
         totalLevels: Int,
         sessionLessonId: String? = nil,
         questionsOverride: [EVQuizQuestion]? = nil,
         lessonTitleOverride: String? = nil,
         onShowSummary: ((String, Int, Int, Int, Int, Int, String, Int) -> Void)? = nil,
         onBack: (() -> Void)? = nil) {
        self.lessonId = lessonId
        self.level = level
        self.questionIndex = questionIndex
        self.totalLevels = totalLevels
        self.sessionLessonId = sessionLessonId
        self.questionsOverride = questionsOverride
        self.lessonTitleOverride = lessonTitleOverride
        self.onShowSummary = onShowSummary
        self.onBack = onBack
    }

    var body: some View {
        ZStack {
            Color(hex: "0A0F0D").ignoresSafeArea()

            if vm.isLoading {
                ProgressView()
                    .tint(Color(hex: "0EB060"))
                    .scaleEffect(1.2)
            } else if let errorMessage = vm.errorMessage {
                errorState(errorMessage)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        topBar
                            .padding(.horizontal, 20)
                            .padding(.top, 32)

                        progressHeader
                            .padding(.horizontal, 20)

                        HStack(spacing: 10) {
                            EVQuestionVisualIcon(lessonId: lessonId, compact: true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(lessonTitle)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.9))
                                Text(lessonSubtitle)
                                    .font(.system(size: 10, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)

                        if let question = vm.currentQuestion {
                            questionCard(question)
                                .padding(.top, 12)
                                .padding(.horizontal, 20)

                            answerGrid(question)
                                .padding(.horizontal, 20)

                            hintButton(question)
                                .padding(.horizontal, 20)

                            if vm.showHint {
                                hintCard(question)
                                    .padding(.horizontal, 20)
                            }

                            if let feedback = vm.feedbackMessage {
                                feedbackCard(feedback, isCorrect: vm.feedbackIsCorrect)
                                    .padding(.horizontal, 20)
                            }

                            actionButton
                                .padding(.horizontal, 20)
                                .padding(.bottom, 28)
                        }
                    }
                }
            }

            if let lockMessage = vm.lockMessage {
                lockOverlay(lockMessage)
            }
        }
        .alert("Time's up", isPresented: $vm.showTimeoutRetryPrompt) {
            Button("Retry") {
                vm.retryAfterTimeout()
            }
            Button("Skip") {
                vm.skipToNextAvailable()
            }
            Button("Back", role: .cancel) {
                vm.showTimeoutRetryPrompt = false
            }
        } message: {
            Text("You have one more chance to retry this question for reduced XP.")
        }
        .navigationBarHidden(true)
        .task(id: lessonId) {
            await vm.load(
                lessonId: lessonId,
                level: level,
                startIndex: questionIndex,
                totalLevels: totalLevels,
                sessionLessonId: sessionLessonId,
                questionsOverride: questionsOverride,
                lessonTitleOverride: lessonTitleOverride
            )
        }
        .onDisappear {
            vm.stopTimer()
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

            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .font(.system(size: 13, weight: .semibold))
                Text(vm.timerText)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(Color.white.opacity(0.1))
            .clipShape(Capsule())

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
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vm.lessonTitle)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Level \(vm.currentLevelDisplay) • Question \(vm.currentDisplayIndex + 1) of \(max(vm.questions.count, 1))")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(vm.completedQuestionsCount) COMPLETED")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "0EB060"))
                    Text("\(vm.sessionStreak) WIN STREAK")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                }
            }

            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.1)).frame(height: 8)
                Capsule().fill(Color(hex: "0EB060")).frame(width: max(8, vm.progressWidth), height: 8)
            }

            HStack {
                Text("XP earned this session: \(vm.sessionXP)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                if let lockUntil = vm.lockUntil {
                    Text("Unlocks \(lockUntil.relativeTimeDescription)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "F6CC2E"))
                }
            }
        }
    }

    // Removed: visualCard view no longer needed, now inline HStack

    private func questionCard(_ question: EVQuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(question.prompt)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineSpacing(2)

            Text(hintSubcopy(for: question))
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private func answerGrid(_ question: EVQuizQuestion) -> some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Array(question.choices.enumerated()), id: \.offset) { index, choice in
                answerButton(choice, index: index, question: question)
            }
        }
    }

    private func answerButton(_ text: String, index: Int, question: EVQuizQuestion) -> some View {
        let isSelected = vm.selectedAnswerIndex == index
        let showCorrect = vm.didSubmit && index == question.correctIndex
        let showWrong = vm.didSubmit && isSelected && index != question.correctIndex

        return Button {
            guard !vm.didSubmit else { return }
            vm.selectedAnswerIndex = index
            EVAccessibilitySupport.playSound(.click)
        } label: {
            Text(text)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(showCorrect ? Color(hex: "0EB060") : .white.opacity(0.9))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 82)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(answerFill(isSelected: isSelected, showCorrect: showCorrect, showWrong: showWrong))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(answerStroke(isSelected: isSelected, showCorrect: showCorrect, showWrong: showWrong), lineWidth: 1)
                        )
                )
        }
        .disabled(vm.didSubmit)
    }

    private func hintButton(_ question: EVQuizQuestion) -> some View {
        Button {
            guard !vm.didSubmit else { return }
            vm.showHint.toggle()
            EVAccessibilitySupport.playSound(vm.showHint ? .hint : .click)
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
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color(hex: "0EB060").opacity(0.25), lineWidth: 1)
                    )
            )
        }
        .disabled(vm.didSubmit)
    }

    private func hintCard(_ question: EVQuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                EVQuestionVisualIcon(lessonId: lessonId, compact: true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Visual Hint")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "0EB060"))
                    Text("Use the image cue and category clue to narrow the choices.")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.white.opacity(0.62))
                }
                Spacer()
            }

            Text(hintText(for: question))
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color(hex: "0EB060").opacity(0.22), lineWidth: 0.8)
                )
        )
    }

    private func feedbackCard(_ feedback: String, isCorrect: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            let lower = feedback.lowercased()
            let isTimeout = vm.showTimeoutRetryPrompt || lower.contains("time's up") || lower.contains("time up")
            Text(isCorrect ? "Correct" : (isTimeout ? "Time's up" : "Not quite"))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(isCorrect ? Color(hex: "0EB060") : (isTimeout ? Color(red: 0.95, green: 0.55, blue: 0.25) : Color.red.opacity(0.9)))
            Text(feedback)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke((isCorrect ? Color(hex: "0EB060") : Color.red).opacity(0.28), lineWidth: 0.8)
                )
        )
    }

    private var actionButton: some View {
        VStack(spacing: 10) {
            Button {
                Task {
                    await vm.primaryAction(onBack: onBack)
                    if let summary = vm.consumePendingSummary() {
                        onShowSummary?(
                            summary.lessonId,
                            summary.level,
                            summary.totalLevels,
                            summary.score,
                            summary.totalQuestions,
                            summary.earnedXP,
                            summary.attemptSessionId,
                            summary.totalTimeSeconds
                        )
                    }
                }
            } label: {
                Text(vm.primaryActionTitle)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(vm.primaryButtonEnabled ? Color(hex: "0EB060") : Color.white.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(!vm.primaryButtonEnabled)
            .buttonStyle(.plain)

            if vm.showSkipToNextAvailable && vm.canSkipToNextAvailable {
                Button {
                    vm.skipToNextAvailable()
                } label: {
                    Text("Go to next available question")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 0.6)
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func errorState(_ errorMessage: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
            Text(errorMessage)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.white.opacity(0.72))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
    }

    private func lockOverlay(_ message: String) -> some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(Color(hex: "F6CC2E"))
                Text("Category Locked")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(message)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                Button {
                    vm.lockMessage = nil
                    onBack?()
                } label: {
                    Text("Back to Lesson")
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

    private func hintText(for question: EVQuizQuestion) -> String {
        switch lessonId.lowercased() {
        case "astronomy":
            return "Look for the option that matches a space concept, celestial body, or cosmic process described in the prompt."
        case "philosophy":
            return "Focus on whether the clue points to a thinker, a school of thought, or a core ethical idea."
        case "biology":
            return "Check whether the prompt is describing a cell part, process, organism function, or gene-related idea."
        case "mathematics":
            return "Try to identify the operation or concept the problem is really testing before choosing an answer."
        case "computer_science":
            return "Eliminate options that do not fit the data structure, protocol, or system behavior described."
        default:
            if question.difficulty >= 70 {
                return "The clue is indirect, so compare each option against the definition rather than the wording alone."
            }
            return "Use the most specific clue in the prompt and remove the options that clearly do not fit."
        }
    }

    private func hintSubcopy(for question: EVQuizQuestion) -> String {
        if question.difficulty >= 70 {
            return "Harder questions use more indirect wording, so read the clue twice."
        }
        return "This one is straightforward; look for the most literal match."
    }

    private func answerFill(isSelected: Bool, showCorrect: Bool, showWrong: Bool) -> Color {
        if showCorrect { return Color(hex: "0EB060").opacity(0.18) }
        if showWrong { return Color.red.opacity(0.16) }
        if isSelected { return Color(hex: "0EB060").opacity(0.12) }
        return Color.white.opacity(0.06)
    }

    private func answerStroke(isSelected: Bool, showCorrect: Bool, showWrong: Bool) -> Color {
        if showCorrect { return Color(hex: "0EB060").opacity(0.55) }
        if showWrong { return Color.red.opacity(0.6) }
        if isSelected { return Color(hex: "0EB060").opacity(0.35) }
        return Color.white.opacity(0.1)
    }

    private var lessonTitle: String {
        lessonId.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private var lessonSubtitle: String {
        switch lessonId.lowercased() {
        case "astronomy": return "Space • Stars • Galaxies"
        case "biology": return "Cells • Life • Systems"
        case "philosophy": return "Ideas • Thinkers • Ethics"
        case "mathematics": return "Patterns • Logic • Numbers"
        case "computer_science": return "Code • Data • Systems"
        default: return "Category Quiz"
        }
    }
}

@MainActor
final class LevelQuizViewModel: ObservableObject {
    @Published var questions: [EVQuizQuestion] = []
    @Published var session: EVQuizSessionState?
    @Published var currentIndex = 0
    @Published var selectedAnswerIndex: Int?
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var feedbackMessage: String?
    @Published var feedbackIsCorrect = false
    @Published var showHint = false
    @Published var showLevelComplete = false
    @Published var lockMessage: String?
    @Published var showSkipToNextAvailable: Bool = false
    @Published var showTimeoutRetryPrompt: Bool = false
    @Published var remainingSeconds: Int = 1800

    private let store = EVQuizStore()
    private var userId: String?
    private var displayName: String = "Learner"
    private var totalQuestions = 0
    private var totalLevels = 1
    private var currentLevel = 1
    private var sessionLessonId: String?
    private var questionsOverride: [EVQuizQuestion]?
    private var lessonTitleOverride: String?
    private var timerCancellable: AnyCancellable?
    private var pendingSummary: EVLevelSummaryPayload?
    private var attemptSessionId: String = UUID().uuidString
    private var totalElapsedSecondsForRun: Int = 0

    var lessonTitle: String = "Lesson"

    var currentQuestion: EVQuizQuestion? {
        guard questions.indices.contains(currentIndex) else { return nil }
        return questions[currentIndex]
    }

    var currentDisplayIndex: Int {
        currentQuestion == nil ? 0 : currentIndex
    }

    var currentLevelDisplay: Int {
        max(currentLevel, 1)
    }

    var sessionStreak: Int {
        session?.consecutiveWins ?? 0
    }

    var sessionXP: Int {
        session?.totalXP ?? 0
    }

    var completedQuestionsCount: Int {
        Set(session?.completedQuestionIDs ?? []).count
    }

    var lockUntil: Date? {
        session?.lockedUntil
    }

    var timerText: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var progressWidth: CGFloat {
        guard totalQuestions > 0 else { return 0 }
        let progress = CGFloat(min(currentIndex + 1, totalQuestions)) / CGFloat(totalQuestions)
        return progress * 320
    }

    var primaryButtonEnabled: Bool {
        if showLevelComplete || lockMessage != nil { return false }
        if currentQuestion == nil { return false }
        if !didSubmit { return selectedAnswerIndex != nil }
        return true
    }

    var primaryActionTitle: String {
        if showLevelComplete { return "Done" }
        if didSubmit {
            if completedQuestionsCount >= max(totalQuestions, 1) {
                return "Finish Level"
            }
            if indexOfNextAvailableQuestion(after: currentIndex) != nil {
                return "Next Question"
            }
            return "Back to Lesson"
        }
        return "Submit Answer"
    }

    var didSubmit = false

    func consumePendingSummary() -> EVLevelSummaryPayload? {
        let payload = pendingSummary
        pendingSummary = nil
        return payload
    }

    func load(lessonId: String,
              level: Int,
              startIndex: Int,
              totalLevels: Int,
              sessionLessonId: String? = nil,
              questionsOverride: [EVQuizQuestion]? = nil,
              lessonTitleOverride: String? = nil) async {
        isLoading = true
        errorMessage = nil
        feedbackMessage = nil
        lockMessage = nil
        showLevelComplete = false
        didSubmit = false
        selectedAnswerIndex = nil
        pendingSummary = nil
        attemptSessionId = UUID().uuidString
        totalElapsedSecondsForRun = 0
        self.sessionLessonId = sessionLessonId
        self.questionsOverride = questionsOverride
        self.lessonTitleOverride = lessonTitleOverride
        self.currentLevel = max(1, level)
        self.totalLevels = max(1, totalLevels)
        self.showSkipToNextAvailable = false

        defer { isLoading = false }

        guard let user = Auth.auth().currentUser else {
            errorMessage = "Please sign in to play this lesson."
            return
        }

        userId = user.uid
        displayName = user.displayName?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty ?? "Learner"

        do {
            let sourceLessonId = sessionLessonId ?? lessonId
            var loadedQuestions: [EVQuizQuestion]
            if let questionsOverride = questionsOverride {
                loadedQuestions = questionsOverride
            } else {
                loadedQuestions = try await store.loadLevelQuestionSet(userId: user.uid, lessonId: lessonId, level: self.currentLevel)
            }
            guard !loadedQuestions.isEmpty else {
                errorMessage = "No questions were found for this level."
                return
            }

            lessonTitle = self.lessonTitleOverride ?? sourceLessonId.replacingOccurrences(of: "_", with: " ").capitalized

            let loadedSession = try await store.loadSession(userId: user.uid, lessonId: sourceLessonId, level: self.currentLevel, totalQuestions: loadedQuestions.count)
            var sanitizedSession = loadedSession
            
            // Check if session is locked (non-pro user after 2 failures)
            if let lockedUntil = sanitizedSession.lockedUntil, lockedUntil > Date() {
                self.lockMessage = "This category is locked. Try again in \(lockedUntil.relativeTimeDescription)."
                self.session = sanitizedSession
                return
            }
            
            // For pro users, filter out locked questions
            let lockedQuestionIds = Set(sanitizedSession.lockedQuestionIds)
            let availableLoaded = loadedQuestions.filter { !lockedQuestionIds.contains($0.id) }
            
            let retryQuestions = sessionLessonId == nil ? sanitizedSession.activeRetryQuestions.map { $0.question }.filter { !lockedQuestionIds.contains($0.id) } : []
            if !retryQuestions.isEmpty, questionsOverride == nil {
                loadedQuestions = retryQuestions
            } else {
                loadedQuestions = availableLoaded
            }

            questions = loadedQuestions
            totalQuestions = max(sanitizedSession.totalQuestions, loadedQuestions.count)

            let completedCount = sanitizedSession.completedQuestionIDs.count
            sanitizedSession.unlockedCount = min(max(1, completedCount + 1), max(totalQuestions, 1))
            sanitizedSession.totalQuestions = totalQuestions

            if !retryQuestions.isEmpty, sanitizedSession.currentQuestionIndex >= loadedQuestions.count {
                sanitizedSession.currentQuestionIndex = 0
            }
            session = sanitizedSession

            let resumeIndex = sanitizedSession.currentQuestionIndex
            let safeStartIndex = min(max(0, startIndex), max(loadedQuestions.count - 1, 0))
            let safeIndex = min(max(safeStartIndex, resumeIndex), loadedQuestions.count - 1)
            currentIndex = safeIndex
            startTimerForCurrentQuestion()

            try await store.persistSession(userId: user.uid, session: sanitizedSession)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func primaryAction(onBack: (() -> Void)?) async {
        guard let question = currentQuestion else { return }

        if showLevelComplete {
            prepareSummaryIfNeeded()
            return
        }

        if didSubmit {
            // If all questions completed, finish level
            if completedQuestionsCount >= max(totalQuestions, 1) {
                prepareSummaryIfNeeded()
                return
            }

            // Advance to next available question (wraps) if any
            if let next = indexOfNextAvailableQuestion(after: currentIndex) {
                currentIndex = next
                selectedAnswerIndex = nil
                didSubmit = false
                feedbackMessage = nil
                feedbackIsCorrect = false
                showHint = false
                showSkipToNextAvailable = false
                startTimerForCurrentQuestion()

                if var session = session {
                    session.currentQuestionIndex = currentIndex
                    self.session = session
                }

                Task {
                    guard let userId, let session else { return }
                    do {
                        try await store.persistSession(userId: userId, session: session)
                    } catch {
                        await MainActor.run { errorMessage = error.localizedDescription }
                    }
                }
                return
            }

            // If the session/level is locked, show the lock overlay
            if let lockedUntil = session?.lockedUntil, lockedUntil > Date() {
                lockMessage = "This category is locked. Try again in \(lockedUntil.relativeTimeDescription)."
                return
            }

            onBack?()
            return
        }

        guard let selectedAnswerIndex else { return }
        guard let userId else { return }

        stopTimer()
        let elapsed = timeSpentForCurrentQuestion()
        totalElapsedSecondsForRun += elapsed
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await store.submitRound(
                userId: userId,
                displayName: displayName,
                session: session ?? EVQuizSessionState.initial(lessonId: sessionLessonId ?? question.lessonId, level: question.level, totalQuestions: questions.count),
                question: question,
                selectedIndex: selectedAnswerIndex,
                attemptSessionId: attemptSessionId,
                timeSpentSeconds: elapsed,
                questionIndex: currentIndex,
                totalQuestions: questions.count,
                totalLevels: totalLevels
            )

            self.session = result.updatedSession
            self.feedbackIsCorrect = result.isCorrect
            self.showHint = false

            if result.isCorrect {
                // Correct answer (either first try or retry)
                self.didSubmit = true
                EVAccessibilitySupport.playSound(.correct)
                self.feedbackMessage = "Great work. You earned \(result.earnedXP) XP."
            } else {
                let cooldownRemaining = self.session?.questionCooldownExpiresAt(questionId: question.id, now: Date())
                if let cooldownRemaining = cooldownRemaining {
                    // Mark submitted, give feedback and offer skip-to-next (do NOT show full-screen lock)
                    self.didSubmit = true
                    EVAccessibilitySupport.playSound(.wrong)
                    let remainingText = cooldownRemaining.relativeTimeDescription
                    self.feedbackMessage = "This question is on cooldown. Try again in \(remainingText). Move to the next question."
                    self.showSkipToNextAvailable = true
                } else {
                    let isNowRetry = self.session?.activeRetryQuestions.contains(where: { $0.question.id == question.id }) ?? false

                    if isNowRetry {
                        // allow retry: do not mark as submitted so user can answer again
                        self.didSubmit = false
                        self.selectedAnswerIndex = nil
                        EVAccessibilitySupport.playSound(.wrong)
                        self.feedbackMessage = "Not quite. You have another chance — try again to earn reduced XP."
                    } else {
                        // fallback behaviour
                        self.didSubmit = true
                        EVAccessibilitySupport.playSound(.wrong)
                        self.feedbackMessage = "Not quite. Review the hint and continue to the next question."
                    }
                }
            }

            if self.currentIndex + 1 >= self.questions.count {
                await handlePostSubmissionFlow()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func moveToNextQuestion() {
        guard currentIndex + 1 < questions.count else {
            Task { await handlePostSubmissionFlow() }
            return
        }
        showSkipToNextAvailable = false
        currentIndex += 1
        selectedAnswerIndex = nil
        didSubmit = false
        feedbackMessage = nil
        feedbackIsCorrect = false
        showHint = false
        lockMessage = nil
        startTimerForCurrentQuestion()

        if var session = session {
            session.currentQuestionIndex = currentIndex
            self.session = session
        }

        Task {
            guard let userId, let session else { return }
            do {
                try await store.persistSession(userId: userId, session: session)
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    // Returns the next index after `index` for which the question is not on cooldown.
    func indexOfNextAvailableQuestion(after index: Int) -> Int? {
        guard !questions.isEmpty else { return nil }
        let start = index + 1
        if start < 0 { return nil }
        for i in start..<questions.count {
            let q = questions[i]
            if session?.questionCooldownExpiresAt(questionId: q.id, now: Date()) == nil {
                return i
            }
        }
        // If nothing ahead, try searching from beginning up to current index
        for i in 0...index {
            let q = questions[i]
            if session?.questionCooldownExpiresAt(questionId: q.id, now: Date()) == nil {
                return i
            }
        }
        return nil
    }

    var canSkipToNextAvailable: Bool {
        indexOfNextAvailableQuestion(after: currentIndex) != nil
    }

    func skipToNextAvailable() {
        guard let next = indexOfNextAvailableQuestion(after: currentIndex) else { return }
        currentIndex = next
        selectedAnswerIndex = nil
        didSubmit = false
        feedbackMessage = nil
        feedbackIsCorrect = false
        showHint = false
        showSkipToNextAvailable = false

        if var session = session {
            session.currentQuestionIndex = currentIndex
            self.session = session
        }

        Task {
            guard let userId, let session else { return }
            do {
                try await store.persistSession(userId: userId, session: session)
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
        startTimerForCurrentQuestion()
    }

    func retryAfterTimeout() {
        // Allow the user to retry the current question: reset selection and timers
        showTimeoutRetryPrompt = false
        didSubmit = false
        selectedAnswerIndex = nil
        feedbackMessage = nil
        feedbackIsCorrect = false
        showHint = false
        startTimerForCurrentQuestion()
    }

    func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func startTimer() {
        stopTimer()

        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                guard self.remainingSeconds > 0 else {
                    self.stopTimer()
                    self.timeoutCurrentQuestion()
                    return
                }
                self.remainingSeconds -= 1
            }
    }

    private func startTimerForCurrentQuestion() {
        let difficulty = currentQuestion?.difficulty ?? 1
        remainingSeconds = timeLimitSeconds(for: difficulty)
        startTimer()
    }

    private func timeSpentForCurrentQuestion() -> Int {
        let difficulty = currentQuestion?.difficulty ?? 1
        let totalTime = timeLimitSeconds(for: difficulty)
        let elapsed = totalTime - remainingSeconds
        return max(0, min(totalTime, elapsed))
    }

    private func timeLimitSeconds(for difficulty: Int) -> Int {
        let clamped = max(1, min(difficulty, 100))
        switch clamped {
        case ...33:
            return 60
        case ...66:
            return 120
        default:
            return 180
        }
    }

    private func timeoutCurrentQuestion() {
        guard !didSubmit, !showLevelComplete else { return }
        guard let question = currentQuestion else { return }
        guard let userId else { return }

        Task {
            let elapsed = timeSpentForCurrentQuestion()
            totalElapsedSecondsForRun += elapsed
            isLoading = true
            defer { isLoading = false }

            do {
                let result = try await store.submitRound(
                    userId: userId,
                    displayName: displayName,
                    session: session ?? EVQuizSessionState.initial(lessonId: question.lessonId, level: question.level, totalQuestions: questions.count),
                    question: question,
                    selectedIndex: -1,
                    attemptSessionId: attemptSessionId,
                    timeSpentSeconds: elapsed,
                    questionIndex: currentIndex,
                    totalQuestions: questions.count,
                    totalLevels: totalLevels
                )

                session = result.updatedSession
                feedbackIsCorrect = false
                showHint = false
                EVAccessibilitySupport.playSound(.wrong)

                // Mirror wrong-answer handling: check cooldown / retry state and set flags/messages accordingly
                let cooldownRemaining = session?.questionCooldownExpiresAt(questionId: question.id, now: Date())
                if let cooldownRemaining = cooldownRemaining {
                    // question is now on cooldown (second failed attempt)
                    didSubmit = true
                    let remainingText = cooldownRemaining.relativeTimeDescription
                    feedbackMessage = "This question is on cooldown. Try again in \(remainingText). Move to the next question."
                    showSkipToNextAvailable = true
                } else {
                    let isNowRetry = session?.activeRetryQuestions.contains(where: { $0.question.id == question.id }) ?? false
                    if isNowRetry {
                        // show a retry prompt so the user can choose to retry or skip
                        showTimeoutRetryPrompt = true
                        // keep didSubmit = false (allow retry if they choose)
                        didSubmit = false
                        selectedAnswerIndex = nil
                    } else {
                        didSubmit = true
                        feedbackMessage = "Time's up. This question was marked incorrect."
                    }
                }

                if currentIndex + 1 >= questions.count {
                    await handlePostSubmissionFlow()
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func prepareSummaryIfNeeded() {
        guard pendingSummary == nil else { return }

        let score = completedQuestionsCount
        let total = max(questions.count, totalQuestions, 1)
        pendingSummary = EVLevelSummaryPayload(
            lessonId: lessonIdFromSession,
            level: currentLevel,
            totalLevels: totalLevels,
            score: score,
            totalQuestions: total,
            earnedXP: sessionXP,
            attemptSessionId: attemptSessionId,
            totalTimeSeconds: totalElapsedSecondsForRun
        )
    }

    // Handles what happens after a submission/timeout when the current question was the last in the local list.
    // Advances to the next available question if any; otherwise prepares the summary only when all questions are completed,
    // or shows a locked message if the session is locked.
    private func handlePostSubmissionFlow() async {
        // If user completed all expected questions, finish level
        if completedQuestionsCount >= max(totalQuestions, 1) {
            prepareSummaryIfNeeded()
            return
        }

        // Try to find a next available question (wraps to beginning)
        if let next = indexOfNextAvailableQuestion(after: currentIndex) {
            currentIndex = next
            selectedAnswerIndex = nil
            didSubmit = false
            feedbackMessage = nil
            feedbackIsCorrect = false
            showHint = false
            showSkipToNextAvailable = false
            startTimerForCurrentQuestion()

            if var session = session {
                session.currentQuestionIndex = currentIndex
                self.session = session
            }

            Task {
                guard let userId, let session else { return }
                do {
                    try await store.persistSession(userId: userId, session: session)
                } catch {
                    await MainActor.run { errorMessage = error.localizedDescription }
                }
            }

            return
        }

        // No available question: if session is locked, show lock overlay; otherwise, as a fallback, prepare summary
        if let lockedUntil = session?.lockedUntil, lockedUntil > Date() {
            lockMessage = "This category is locked. Try again in \(lockedUntil.relativeTimeDescription)."
            return
        }

        prepareSummaryIfNeeded()
    }

    private var lessonIdFromSession: String {
        session?.lessonId ?? sessionLessonId ?? currentQuestion?.lessonId ?? "lesson"
    }
}

struct EVLevelSummaryPayload {
    let lessonId: String
    let level: Int
    let totalLevels: Int
    let score: Int
    let totalQuestions: Int
    let earnedXP: Int
    let attemptSessionId: String
    let totalTimeSeconds: Int
}

// Removed: EVQuestionVisualView is now replaced with inline HStack icon + text

private struct EVQuestionVisualIcon: View {
    let lessonId: String
    var compact: Bool = false

    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: compact ? 24 : 44, weight: .semibold))
            .foregroundColor(Color(hex: "0EB060"))
            .frame(width: compact ? 38 : 64, height: compact ? 38 : 64)
            .background(Color.white.opacity(compact ? 0.12 : 0.09))
            .clipShape(RoundedRectangle(cornerRadius: compact ? 12 : 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: compact ? 12 : 18, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.6)
            )
    }

    private var symbolName: String {
        switch lessonId.lowercased() {
        case "astronomy": return "sparkles"
        case "biology": return "leaf"
        case "philosophy": return "brain.head.profile"
        case "mathematics": return "function"
        case "computer_science": return "chevron.left.forwardslash.chevron.right"
        default: return "questionmark.circle"
        }
    }
}

private extension Date {
    var relativeTimeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}

#Preview {
    LevelQuizView(lessonId: "astronomy", level: 1, questionIndex: 0, totalLevels: 10)
}
