import SwiftUI

struct RankView: View {
    @State private var appeared = false
    @StateObject private var vm = RankViewModel()

    var onHome: (() -> Void)?
    var onLessons: (() -> Void)?
    var onDiscovery: (() -> Void)?
    var onSettings: (() -> Void)?
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

                            VStack(spacing: 10) {
                                ForEach(Array(vm.entries.enumerated()), id: \.element.id) { index, entry in
                                    HStack(spacing: 12) {
                                        Text("\(index + 1)")
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                            .foregroundColor(index == 0 ? Color(hex: "F6CC2E") : Color.white.opacity(0.7))
                                            .frame(width: 30)

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
                                                    .stroke(index == 0 ? Color(hex: "F6CC2E").opacity(0.2) : Color.white.opacity(0.08), lineWidth: 0.6)
                                            )
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(.easeOut(duration: 0.35), value: appeared)

                Spacer()
            }

            EVMainTabBar(activeTab: .rank) { tab in
                switch tab {
                case .home:
                    onHome?()
                case .lessons:
                    onLessons?()
                case .discovery:
                    onDiscovery?()
                case .settings:
                    onSettings?()
                default:
                    break
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            appeared = true
            Task { await vm.loadLeaderboard() }
        }
    }

    private var navBar: some View {
        HStack {
            HStack(spacing: 8) {
                Image("EdVentureLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                Text("EdVenture")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "0EB060"))
            }

            Spacer()

            HStack(spacing: 10) {
                EVLiquidGlassIconButton(systemName: "bell.fill") {}
                Button { onProfile?() } label: {
                    EVProfileAvatarView(
                        size: 38,
                        iconSize: 15,
                        iconOpacity: 0.7,
                        ringColor: Color.white.opacity(0.15),
                        ringWidth: 0.5
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 52)
    }
}

#Preview {
    RankView()
}
