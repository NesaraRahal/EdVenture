import SwiftUI

struct RankView: View {
    @State private var appeared = false

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

                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 56, weight: .light))
                        .foregroundColor(Color(hex: "0EB060").opacity(0.9))

                    Text("Rank")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Leaderboards are coming soon.\nTrack global standings, weekly climbs, and your learning streak rank.")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 32)
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
        .onAppear { appeared = true }
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
