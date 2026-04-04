import SwiftUI

struct DiscoveryView: View {
    @State private var appeared = false

    var onHome: (() -> Void)?
    var onLessons: (() -> Void)?
    var onRank: (() -> Void)?
    var onSettings: (() -> Void)?

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "0A0F0D").ignoresSafeArea()

            VStack(spacing: 0) {
                navBar

                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: "sparkles.rectangle.stack")
                        .font(.system(size: 56, weight: .light))
                        .foregroundColor(Color(hex: "0EB060").opacity(0.9))

                    Text("Discovery")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Immersive AR discovery is coming soon.\nScan physical materials and explore instant learning overlays.")
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

            EVMainTabBar(activeTab: .discovery) { tab in
                switch tab {
                case .home:
                    onHome?()
                case .lessons:
                    onLessons?()
                case .rank:
                    onRank?()
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
                Button { onSettings?() } label: {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 38, height: 38)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.7))
                        )
                        .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 52)
    }
}

#Preview {
    DiscoveryView()
}
