import SwiftUI

struct RankView: View {
    @State private var appeared = false
    @StateObject private var vm = RankViewModel()

    var onHome: (() -> Void)?
    var onLessons: (() -> Void)?
    var onDiscovery: (() -> Void)?
    var onSettings: (() -> Void)?
    var onNotifications: (() -> Void)?
    var onProfile: (() -> Void)?

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "0A0F0D").ignoresSafeArea()

            VStack(spacing: 0) {
                navBar

                Group {
                    if vm.isLoading {
                        ProgressView()
                            .tint(Color(hex: "0EB060"))
                    } else if let errorMessage = vm.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 14) {
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 56, weight: .light))
                                    .foregroundColor(Color(hex: "0EB060").opacity(0.9))

                                Text("Global Leaderboard")
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)

                                Text("Track the highest XP earners across all categories.")
                                    .font(.system(size: 15, design: .rounded))
                                    .foregroundColor(.white.opacity(0.6))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(3)
                                    .padding(.horizontal, 32)

                                if vm.entries.count >= 3 {
                                    podiumSection
                                        .padding(.horizontal, 20)
                                }

                                if !listEntries.isEmpty {
                                    VStack(spacing: 10) {
                                        ForEach(Array(listEntries.enumerated()), id: \.element.id) { index, entry in
                                            HStack(spacing: 12) {
                                                Text("\(listStartRank + index)")
                                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                                    .foregroundColor((listStartRank + index) == 1 ? Color(hex: "F6CC2E") : Color.white.opacity(0.7))
                                                    .frame(width: 30)

                                                leaderboardAvatar(for: entry)

                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(entry.displayName)
                                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                                        .foregroundColor(.white)
                                                    Text("\(entry.quizXP) quiz XP • \(entry.streak) streak")
                                                        .font(.system(size: 12, design: .rounded))
                                                        .foregroundColor(.white.opacity(0.55))
                                                }

                                                Spacer()

                                                Text("\(entry.totalXP)")
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
                                                            .stroke((listStartRank + index) == 1 ? Color(hex: "F6CC2E").opacity(0.2) : Color.white.opacity(0.08), lineWidth: 0.6)
                                                    )
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                                Spacer(minLength: 130)
                            }
                        }
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(.easeOut(duration: 0.35), value: appeared)

                Spacer()
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarHidden(true)
        .onAppear {
            appeared = true
            Task { await vm.loadLeaderboard() }
        }
    }

    private var navBar: some View {
        EVScreenTopBar(onProfile: onProfile, onNotifications: onNotifications)
    }

    private var listEntries: [EVLeaderboardEntry] {
        vm.entries.count >= 3 ? Array(vm.entries.dropFirst(3)) : vm.entries
    }

    private var listStartRank: Int {
        vm.entries.count >= 3 ? 4 : 1
    }

    private var podiumSection: some View {
        HStack(alignment: .bottom, spacing: 14) {
            podiumItem(rank: 2, entry: vm.entries[1], avatarSize: 62, pedestalHeight: 56)
            podiumItem(rank: 1, entry: vm.entries[0], avatarSize: 84, pedestalHeight: 82)
            podiumItem(rank: 3, entry: vm.entries[2], avatarSize: 62, pedestalHeight: 46)
        }
        .frame(maxWidth: .infinity)
    }

    private func podiumItem(rank: Int, entry: EVLeaderboardEntry, avatarSize: CGFloat, pedestalHeight: CGFloat) -> some View {
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

            Text("\(entry.totalXP) XP")
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

    private func leaderboardAvatar(for entry: EVLeaderboardEntry) -> some View {
        leaderboardAvatar(for: entry, size: 34)
    }

    private func leaderboardAvatar(for entry: EVLeaderboardEntry, size: CGFloat) -> some View {
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

#Preview {
    RankView()
}
