import SwiftUI

struct GlobalChallengeLaunchView: View {
    let challenge: GlobalChallenge
    let onBack: (() -> Void)?
    let onStart: ((GlobalChallenge, [EVQuizQuestion]) -> Void)?

    var body: some View {
        GlobalChallengeDetailView(
            challenge: challenge,
            challengeQuestions: GlobalChallengeQuestionBank.questions(for: challenge.id),
            onBack: onBack,
            onStart: onStart
        )
    }
}
