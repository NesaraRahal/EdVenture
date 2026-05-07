import SwiftUI

struct ProfileView: View {
    @StateObject private var vm = UserProfileViewModel()
    @AppStorage("security.biometricsEnabled") private var biometricsEnabled = false
    @AppStorage("security.requireForProfileChanges") private var requireForProfileChanges = false
    @State private var showingBiometricError = false
    @State private var showPaymentRequiredAlert = false
    @State private var showActivationResultAlert = false
    @State private var showCancelProConfirm = false
    @State private var activationResultMessage = ""
    @State private var isActivatingPro = false
    private let proPriceLabel = "USD 4.99 / month"

    var onInsights: (() -> Void)?
    var onEditProfile: (() -> Void)?
    var onOpenPayment: (() -> Void)?
    var onBack: (() -> Void)?


    private var stats: [ProfileStat] {
        [
            .init(icon: "flame.fill", value: "\(vm.profile.currentStreak) Days", label: "CURRENT STREAK", color: Color(hex: "7EF5A8")),
            .init(icon: "medal.fill", value: "\(vm.profile.totalXP)", label: "TOTAL XP", color: Color(hex: "75DFFF")),
            .init(icon: "scope", value: "\(vm.profile.accuracyPercent)%", label: "ACCURACY %", color: Color(hex: "66FFC8")),
            .init(icon: "brain.head.profile", value: "\(vm.profile.quizzesCompleted)", label: "QUIZZES COMPLETED", color: Color(hex: "7EF5A8"))
        ]
    }
    private var achievements: [ProfileAchievementItem] {
        vm.achievements
    }

    private var activities: [ProfileRecentActivity] {
        vm.recentActivities
    }

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

                    dailyGoalCard
                        .padding(.top, 22)
                        .padding(.horizontal, 20)

                    proMembershipSection
                        .padding(.top, 24)
                        .padding(.horizontal, 20)

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
        .alert("Payment Method Required", isPresented: $showPaymentRequiredAlert) {
            Button("Add Payment Method") {
                onOpenPayment?()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please add a payment method first in Payment & Billing before activating Pro.")
        }
        .alert("Pro Membership", isPresented: $showActivationResultAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(activationResultMessage)
        }
        .confirmationDialog(
            "Cancel Pro Membership",
            isPresented: $showCancelProConfirm,
            titleVisibility: .visible
        ) {
            Button("Cancel Pro", role: .destructive) {
                Task {
                    let result = await vm.cancelProMembership()
                    switch result {
                    case .success(let message):
                        activationResultMessage = message
                        showActivationResultAlert = true
                    case .missingPaymentMethod:
                        break
                    case .failure(let message):
                        activationResultMessage = message
                        showActivationResultAlert = true
                    }
                }
            }
            Button("Keep Pro", role: .cancel) {}
        } message: {
            Text("This will turn off your Pro status in Firebase and return the account to the free plan.")
        }
    }

    private var topBar: some View {
        HStack {
            EVBackButton(title: "Back", action: { onBack?() })

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

    private var dailyGoalCard: some View {
        let goal = max(vm.profile.dailyGoalMinutes, 1)
        let progressMinutes = vm.profile.dailyProgressSeconds / 60
        let progressRatio = min(max(Double(vm.profile.dailyProgressSeconds) / Double(goal * 60), 0.0), 1.0)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("DAILY GOAL", systemImage: "target")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .tracking(1)

                Spacer()

                Text("\(goal) min")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "7EF5A8"))
            }

            Text("Progress today: \(progressMinutes) / \(goal) minutes")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.white.opacity(0.65))

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.16))
                        .frame(height: 10)

                    Capsule()
                        .fill(Color(hex: "0EB060"))
                        .frame(width: geo.size.width * progressRatio, height: 10)
                }
            }
            .frame(height: 10)
        }
        .padding(16)
        .background(statCardBackground)
    }

    private var proMembershipSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Pro Membership")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                Text(vm.profile.isPro ? "ACTIVE" : "INACTIVE")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(vm.profile.isPro ? Color(hex: "7EF5A8") : .white.opacity(0.55))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background((vm.profile.isPro ? Color(hex: "7EF5A8") : Color.white).opacity(0.12))
                    .clipShape(Capsule())
            }

            Text("Plan: \(proPriceLabel)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "0EB060"))

            if vm.profile.isPro, let purchasedAt = vm.profile.proPurchasedAt {
                Text("Activated on \(formatDate(purchasedAt))")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            } else {
                Text("Activate Pro to remove cooldown restrictions and unlock premium access.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }

            HStack(spacing: 10) {
                Button {
                    Task {
                        isActivatingPro = true
                        let result = await vm.activateProMembership(priceLabel: proPriceLabel)
                        isActivatingPro = false

                        switch result {
                        case .success(let message):
                            activationResultMessage = message
                            showActivationResultAlert = true
                        case .missingPaymentMethod:
                            showPaymentRequiredAlert = true
                        case .failure(let message):
                            activationResultMessage = message
                            showActivationResultAlert = true
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isActivatingPro {
                            ProgressView()
                                .tint(Color(hex: "0A0F0D"))
                        }
                        Text(vm.profile.isPro ? "Pro Active" : "Activate Pro")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(Color(hex: "0A0F0D"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(vm.profile.isPro ? Color.white.opacity(0.4) : Color(hex: "0EB060"))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(isActivatingPro || vm.profile.isPro)

                if vm.profile.isPro {
                    Button {
                        showCancelProConfirm = true
                    } label: {
                        Text("Cancel Pro")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                } else {
                    Button {
                        onOpenPayment?()
                    } label: {
                        Text("Manage Payment")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
        }
        .padding(16)
        .background(statCardBackground)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
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
        Button {
            onInsights?()
        } label: {
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
                        Text(vm.profile.strongestSubject.isEmpty ? "Keep learning" : vm.profile.strongestSubject)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 6) {
                        Text("TREND")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.45))
                            .tracking(1.1)
                        Text(vm.accuracyTrendText)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: vm.accuracyTrendColorHex))
                    }
                }
            }
            .padding(18)
            .background(statCardBackground)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var levelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Level \(vm.levelProgress.level) \(vm.levelProgress.title)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text("\(vm.levelProgress.xpToNext) XP to Level \(vm.levelProgress.level + 1)")
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
                        .frame(width: geo.size.width * CGFloat(vm.levelProgress.progressRatio), height: 12)
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
                            .foregroundColor(item.isLocked ? .white.opacity(0.2) : Color(hex: item.colorHex))

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
                if activities.isEmpty {
                    Text("Complete a quiz to see your recent activity.")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                        .padding(.vertical, 12)
                } else {
                    ForEach(activities) { activity in
                        HStack(spacing: 14) {
                            let color = Color(hex: activity.colorHex)
                            Circle()
                                .fill(color.opacity(0.16))
                                .frame(width: 54, height: 54)
                                .overlay(
                                    Image(systemName: activity.icon)
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundColor(color)
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
                                    .foregroundColor(color)
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

#Preview {
    ProfileView()
}
