import SwiftUI
import Combine

@MainActor
final class GlobalChallengeLoaderViewModel: ObservableObject {
    @Published var challenge: GlobalChallenge?
    @Published var challengeQuestions: [EVQuizQuestion] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let store = GlobalChallengeStore()

    func load(challengeId: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            challenge = try await store.loadChallenge(id: challengeId)
            if let challenge {
                challengeQuestions = store.challengeQuestions(for: challenge)
            }
        } catch {
            challenge = store.fallbackChallenge(id: challengeId)
            if let challenge {
                challengeQuestions = store.challengeQuestions(for: challenge)
            }
        }

        if challenge == nil {
            challenge = store.fallbackChallenge(id: challengeId)
            if let challenge {
                challengeQuestions = store.challengeQuestions(for: challenge)
            }
        }
    }
}

struct GlobalChallengeLoaderView: View {
    let challengeId: String
    let onBack: (() -> Void)?
    let onStart: ((GlobalChallenge, [EVQuizQuestion]) -> Void)?

    @StateObject private var vm = GlobalChallengeLoaderViewModel()

    var body: some View {
        ZStack {
            Color(hex: "0A0F0D").ignoresSafeArea()

            if vm.isLoading {
                ProgressView()
                    .tint(Color(hex: "0EB060"))
            } else if let challenge = vm.challenge {
                GlobalChallengeDetailView(
                    challenge: challenge,
                    challengeQuestions: vm.challengeQuestions,
                    onBack: onBack,
                    onStart: onStart
                )
            } else if let errorMessage = vm.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(Color(hex: "F6CC2E"))
                    Text(errorMessage)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            }
        }
        .navigationBarHidden(true)
        .task(id: challengeId) {
            await vm.load(challengeId: challengeId)
        }
    }
}
