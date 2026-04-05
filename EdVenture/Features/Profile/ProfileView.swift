import SwiftUI

struct ProfileView: View {
    @StateObject private var vm = UserProfileViewModel()
    @AppStorage("security.biometricsEnabled") private var biometricsEnabled = false
    @AppStorage("security.requireForProfileChanges") private var requireForProfileChanges = false
    @State private var showingBiometricError = false

    var onEditProfile: (() -> Void)?
    var onBack: (() -> Void)?

    private let stats: [ProfileStat] = [
        .init(icon: "flame.fill", value: "12 Days", label: "CURRENT STREAK", color: Color(hex: "7EF5A8")),
        .init(icon: "medal.fill", value: "4,250", label: "TOTAL XP", color: Color(hex: "75DFFF")),
        .init(icon: "scope", value: "94%", label: "ACCURACY %", color: Color(hex: "66FFC8")),
        .init(icon: "brain.head.profile", value: "148", label: "QUIZZES COMPLETED", color: Color(hex: "7EF5A8"))
    ]

    private let achievements: [AchievementItem] = [
        .init(icon: "rosette", title: "7-DAY STREAK", color: Color(hex: "F6CC2E"), isLocked: false),
        .init(icon: "speedometer", title: "SPEED DEMON", color: Color(hex: "7EF5A8"), isLocked: false),
        .init(icon: "graduationcap.fill", title: "TOPIC MASTER", color: Color(hex: "75DFFF"), isLocked: false),
        .init(icon: "moon", title: "NIGHT OWL", color: .white.opacity(0.2), isLocked: true)
    ]

    private let activities: [RecentActivity] = [
        .init(icon: "paperplane.fill", title: "Introduction to Quasars", time: "2h ago", score: "100%", tag: "PERFECT", color: Color(hex: "7EF5A8")),
        .init(icon: "globe.americas.fill", title: "Solar System Quiz", time: "yesterday", score: "85%", tag: "GREAT", color: Color(hex: "75DFFF"))
    ]

    var body: some View {
        ZStack {
            Color(hex: "0A0F0D").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    topBar
                        .padding(.top, 52)
                        .padding(.horizontal, 20)

                    header
                        .padding(.top, 28)

                    statsGrid
                        .padding(.top, 28)
                        .padding(.horizontal, 20)

                    insightsCard
                        .padding(.top, 24)
                        .padding(.horizontal, 20)

                    levelSection
                        .padding(.top, 24)
                        .padding(.horizontal, 20)

                    achievementsSection
                        .padding(.top, 30)
                        .padding(.horizontal, 20)

                    recentActivitySection
                        .padding(.top, 30)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task { await vm.loadProfile() }
        }
        .alert("Authentication Required", isPresented: $showingBiometricError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Face ID / Touch ID verification failed. Please try again.")
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                onBack?()
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .frame(height: 44)
                .background(Color.white.opacity(0.18))
                .clipShape(Capsule())
            }
            .frame(minWidth: 44, minHeight: 44)

            Spacer()

            Text("Profile")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            Color.clear
                .frame(width: 88, height: 44)
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 148, height: 148)
                    .overlay(
                        Circle()
                            .stroke(Color(hex: "2BE292"), lineWidth: 5)
                    )
                    .overlay(
                        Group {
                            if !vm.profile.profileImagePath.isEmpty {
                                EVStorageImageView(path: vm.profile.profileImagePath) {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 54, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            } else if let data = Data(base64Encoded: vm.profile.profileImageBase64),
                                      let image = UIImage(data: data) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                            } else if let url = URL(string: vm.profile.profileImageURL), !vm.profile.profileImageURL.isEmpty {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    default:
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 54, weight: .medium))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 54, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .frame(width: 136, height: 136)
                        .clipShape(Circle())
                    )
                    .clipShape(Circle())

                Circle()
                    .fill(Color(hex: "2BE292"))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(hex: "0A0F0D"))
                    )
                    .offset(x: -2, y: -2)
            }

            Text(vm.profile.fullName.isEmpty ? "Learner" : vm.profile.fullName)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 20)

            Text(vm.profile.username.isEmpty ? "Leveling up daily" : "@\(vm.profile.username)")
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.horizontal, 20)

            Button("Edit Profile") {
                Task {
                    if biometricsEnabled && requireForProfileChanges {
                        let ok = await EVBiometricAuth.authorize(
                            reason: "Authenticate to edit your profile"
                        )

                        if ok {
                            onEditProfile?()
                        } else {
                            showingBiometricError = true
                        }
                    } else {
                        onEditProfile?()
                    }
                }
            }
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "0EB060"))
                .frame(width: 180, height: 50)
                .background(Color.clear)
                .overlay(
                    Capsule().stroke(Color(hex: "0EB060"), lineWidth: 2)
                )
                .padding(.top, 10)
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
            ForEach(stats) { stat in
                VStack(spacing: 10) {
                    Image(systemName: stat.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(stat.color)

                    Text(stat.value)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(stat.label)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.45))
                        .tracking(1.2)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .background(statCardBackground)
            }
        }
    }

    private var insightsCard: some View {
        VStack(spacing: 14) {
            HStack {
                Label("LEARNING INSIGHTS", systemImage: "sparkles")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.88))
                    .tracking(1)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }

            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("STRONGEST")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.45))
                        .tracking(1.1)
                    Text("Astronomy")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text("TREND")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.45))
                        .tracking(1.1)
                    Text("+12% accuracy")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "71F8AA"))
                }
            }
        }
        .padding(18)
        .background(statCardBackground)
    }

    private var levelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Level 12 Polymath")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text("450 XP to Level 13")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.16))
                        .frame(height: 18)

                    Capsule()
                        .fill(Color(hex: "0EB060"))
                        .frame(width: geo.size.width * 0.65, height: 12)
                        .padding(.horizontal, 4)
                        .shadow(color: Color(hex: "0EB060").opacity(0.4), radius: 6, y: 1)
                }
            }
            .frame(height: 18)
        }
    }

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievements")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(achievements) { item in
                    VStack(spacing: 12) {
                        Image(systemName: item.icon)
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundColor(item.color)

                        Text(item.title)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(item.isLocked ? .white.opacity(0.18) : .white.opacity(0.85))
                            .tracking(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(item.isLocked ? Color.white.opacity(0.02) : Color.white.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white.opacity(item.isLocked ? 0.05 : 0.08), lineWidth: 0.6)
                            )
                    )
                }
            }
        }
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent Activity")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            VStack(spacing: 14) {
                ForEach(activities) { activity in
                    HStack(spacing: 14) {
                        Circle()
                            .fill(activity.color.opacity(0.16))
                            .frame(width: 54, height: 54)
                            .overlay(
                                Image(systemName: activity.icon)
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(activity.color)
                            )

                        VStack(alignment: .leading, spacing: 3) {
                            Text(activity.title)
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text(activity.time)
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(.white.opacity(0.55))
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(activity.score)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(activity.color)
                            Text(activity.tag)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))
                                .tracking(0.8)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private var statCardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.05), Color(hex: "0EB060").opacity(0.02)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.6)
            )
    }
}

private struct ProfileStat: Identifiable {
    let id = UUID()
    let icon: String
    let value: String
    let label: String
    let color: Color
}

private struct AchievementItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let color: Color
    let isLocked: Bool
}

private struct RecentActivity: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let time: String
    let score: String
    let tag: String
    let color: Color
}

#Preview {
    ProfileView()
}
