import SwiftUI
import UIKit
import Combine

struct GlobalChallengeDetailView: View {
    let challenge: GlobalChallenge
    let challengeQuestions: [EVQuizQuestion]
    let onBack: (() -> Void)?
    let onStart: ((GlobalChallenge, [EVQuizQuestion]) -> Void)?

    @State private var showStartWarning = false
    @StateObject private var vm = GlobalChallengeDetailViewModel()

    var body: some View {
        ZStack {
            Color(hex: "0A0F0D").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    topBar
                        .padding(.horizontal, 20)
                        .padding(.top, 52)

                    heroCard
                        .padding(.horizontal, 20)

                    statsGrid
                        .padding(.horizontal, 20)

                    strategyCard
                        .padding(.horizontal, 20)

                    leaderboardSection
                        .padding(.horizontal, 20)

                    startButton
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                }
            }
        }
        .navigationBarHidden(true)
        .task(id: challenge.id) {
            await vm.loadLeaderboard(challengeId: challenge.id)
        }
        .alert("Start challenge?", isPresented: $showStartWarning) {
            Button("Cancel", role: .cancel) {}
            Button("Start Now", role: .destructive) {
                onStart?(challenge, challengeQuestions)
            }
        } message: {
            Text("You must finish this challenge in one go. If you go back, you lose this run’s progress.")
        }
    }

    private var topBar: some View {
        HStack {
            EVBackButton(title: "Back", action: { onBack?() }, compactTitleSize: 16)

            Spacer()

            Text("Global Challenge")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            Color.clear.frame(width: 82, height: 44)
        }
    }

    private var heroCard: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: challenge.gradient.compactMap { Color(hex: $0) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(
                Image(systemName: "globe.europe.africa.fill")
                    .font(.system(size: 110))
                    .foregroundColor(.white.opacity(0.08))
                    .offset(x: 110, y: -18)
            )

            VStack(alignment: .leading, spacing: 10) {
                Text(challenge.tag.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.18))
                    .clipShape(Capsule())

                Text(challenge.title)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .lineSpacing(2)

                Text(challenge.subtitle)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.white.opacity(0.82))
                    .lineSpacing(3)

                Text(challenge.description)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.white.opacity(0.72))
                    .lineSpacing(3)
            }
            .padding(20)
        }
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var statsGrid: some View {
        HStack(spacing: 12) {
            challengeStat(title: "Reward", value: challenge.rewardSummary, icon: "sparkles")
            challengeStat(title: "Time", value: challenge.timeLimitSummary, icon: "timer")
            challengeStat(title: "Target", value: "\(challenge.correctAnswersTarget) Correct", icon: "checkmark.seal")
        }
    }

    private func challengeStat(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "0EB060"))
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.45))
                .tracking(1.0)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )
        )
    }

    private var strategyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Strategy")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            ForEach(Array(challenge.strategyTips.enumerated()), id: \.offset) { index, tip in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .frame(width: 22, height: 22)
                        .background(Color(hex: "0EB060"))
                        .clipShape(Circle())
                    Text(tip)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.white.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )
        )
    }

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            leaderboardHeader

            if vm.isLoading {
                leaderboardLoadingState
            } else if vm.leaderboard.isEmpty {
                leaderboardEmptyState
            } else {
                leaderboardBody
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )
        )
    }

    private var leaderboardHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Challenge Leaderboard")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Ranked by challenge XP, then accuracy and time.")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.45))
                    .tracking(0.5)
            }

            Spacer()
        }
    }

    private var leaderboardLoadingState: some View {
        ProgressView()
            .tint(Color(hex: "0EB060"))
            .frame(maxWidth: .infinity, minHeight: 100)
    }

    private var leaderboardEmptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.3.sequence.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(Color(hex: "0EB060"))
            Text("Be the first to set a challenge score.")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity, minHeight: 120)
    }

    @ViewBuilder
    private var leaderboardBody: some View {
        if vm.leaderboard.count >= 3 {
            podiumSection
        }

        if !listEntries.isEmpty {
            leaderboardRows
        }

        Text(challenge.rankRuleSummary)
            .font(.system(size: 13, design: .rounded))
            .foregroundColor(.white.opacity(0.7))
    }

    private var leaderboardRows: some View {
        VStack(spacing: 10) {
            ForEach(Array(listEntries.enumerated()), id: \.element.id) { index, entry in
                leaderboardRow(entry: entry, rank: listStartRank + index)
            }
        }
    }

    private func leaderboardRow(entry: GlobalChallengeLeaderboardEntry, rank: Int) -> some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(rank == 1 ? Color(hex: "F6CC2E") : Color.white.opacity(0.7))
                .frame(width: 30)

            leaderboardAvatar(for: entry)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text("\(entry.earnedXP) challenge XP • \(entry.accuracyPercent)% accuracy")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }

            Spacer()

            Text("\(entry.earnedXP)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "0EB060"))
        }
        .padding(.horizontal, 16)
        .frame(height: 64)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(rank == 1 ? Color(hex: "F6CC2E").opacity(0.2) : Color.white.opacity(0.08), lineWidth: 0.6)
                )
        )
    }

    private var startButton: some View {
        Button {
            showStartWarning = true
        } label: {
            Text("Join Challenge")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var listEntries: [GlobalChallengeLeaderboardEntry] {
        vm.leaderboard.count >= 3 ? Array(vm.leaderboard.dropFirst(3)) : vm.leaderboard
    }

    private var listStartRank: Int {
        vm.leaderboard.count >= 3 ? 4 : 1
    }

    private var podiumSection: some View {
        HStack(alignment: .bottom, spacing: 14) {
            podiumItem(rank: 2, entry: vm.leaderboard[1], avatarSize: 62, pedestalHeight: 56)
            podiumItem(rank: 1, entry: vm.leaderboard[0], avatarSize: 84, pedestalHeight: 82)
            podiumItem(rank: 3, entry: vm.leaderboard[2], avatarSize: 62, pedestalHeight: 46)
        }
        .frame(maxWidth: .infinity)
    }

    private func podiumItem(rank: Int, entry: GlobalChallengeLeaderboardEntry, avatarSize: CGFloat, pedestalHeight: CGFloat) -> some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                leaderboardAvatar(for: entry, size: avatarSize)
                    .overlay(
                        Circle()
                            .stroke(rank == 1 ? Color(hex: "F6CC2E") : Color(hex: "0EB060"), lineWidth: rank == 1 ? 2.2 : 1.2)
                    )

                Circle()
                    .fill(rank == 1 ? Color(hex: "F6CC2E") : Color(hex: "0EB060"))
                    .frame(width: 26, height: 26)
                    .overlay(
                        Text("\(rank)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "0A0F0D"))
                    )
            }

            Text(entry.displayName)
                .font(.system(size: rank == 1 ? 18 : 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)

            Text("\(entry.earnedXP) XP")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.7))

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "0EB060").opacity(0.22), Color.white.opacity(0.04)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 0.7)
                )
                .frame(height: pedestalHeight)
        }
        .frame(maxWidth: .infinity)
    }

    private func leaderboardAvatar(for entry: GlobalChallengeLeaderboardEntry) -> some View {
        leaderboardAvatar(for: entry, size: 34)
    }

    private func leaderboardAvatar(for entry: GlobalChallengeLeaderboardEntry, size: CGFloat) -> some View {
        Group {
            if let base64 = entry.profileImageBase64,
               let data = Data(base64Encoded: base64),
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
            } else if let path = entry.profileImageUrl, !path.isEmpty {
                if path.lowercased().hasPrefix("http"), let url = URL(string: path) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            Image(systemName: "person.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .clipShape(Circle())
                } else {
                    EVStorageImageView(path: path) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .clipShape(Circle())
                }
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
        }
        .frame(width: size, height: size)
        .overlay(
            Circle()
                .stroke(Color.white.opacity(0.14), lineWidth: 0.8)
        )
    }
}

@MainActor
final class GlobalChallengeDetailViewModel: ObservableObject {
    @Published var leaderboard: [GlobalChallengeLeaderboardEntry] = []
    @Published var isLoading = false

    private let store = GlobalChallengeStore()

    func loadLeaderboard(challengeId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            leaderboard = try await store.loadLeaderboard(challengeId: challengeId)
        } catch {
            leaderboard = []
        }
    }
}
