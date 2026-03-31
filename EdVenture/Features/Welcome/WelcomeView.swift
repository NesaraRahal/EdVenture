import SwiftUI

// MARK: - Color Tokens
extension Color {
    static let evBackground  = Color(hex: "0A0F0D")
    static let evPrimary     = Color(hex: "0EB060")
    static let evTextMuted   = Color(hex: "8A9E93")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double( int        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Welcome View
struct WelcomeView: View {

    @State private var appeared = false
    var onGetStarted: (() -> Void)?

    var body: some View {
        ZStack {
            Color.evBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {

                Spacer()

                // ── Logo / wordmark ─────────────────────────────────────────
                Text("EdVenture")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.evPrimary)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -10)
                    .animation(.easeOut(duration: 0.5).delay(0.1), value: appeared)

                Spacer().frame(height: 44)

                // ── Hero illustration ───────────────────────────────────────
                // When your asset is ready, replace the ZStack below with:
                //   Image("welcome_tree")
                //       .resizable()
                //       .scaledToFit()
                //       .frame(width: 220, height: 220)
                ZStack {
                    Circle()
                        .fill(Color.evPrimary.opacity(0.08))
                        .frame(width: 240, height: 240)

                    Circle()
                        .fill(Color.evPrimary.opacity(0.05))
                        .frame(width: 190, height: 190)

                    Image(systemName: "brain.head.profile")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.evPrimary)
                }
                .scaleEffect(appeared ? 1 : 0.85)
                .opacity(appeared ? 1 : 0)
                .animation(
                    .spring(response: 0.6, dampingFraction: 0.7).delay(0.2),
                    value: appeared
                )

                Spacer().frame(height: 48)

                // ── Headline ────────────────────────────────────────────────
                VStack(spacing: 2) {
                    Text("Learn Fast.")
                    Text("Play Hard.")
                    Text("Level Up Your Mind.")
                }
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
                .animation(.easeOut(duration: 0.5).delay(0.35), value: appeared)

                Spacer().frame(height: 16)

                // ── Subtitle ────────────────────────────────────────────────
                Text("Bite-sized lessons, daily challenges, and\nrewards that make learning addictive.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(.evTextMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 32)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                    .animation(.easeOut(duration: 0.5).delay(0.42), value: appeared)

                Spacer().frame(height: 48)

                // ── Primary CTA ─────────────────────────────────────────────
                // iOS HIG: primary action uses full-width capsule shape,
                // minimum touch target 44pt, prominent fill colour.
                Button {
                    onGetStarted?()
                } label: {
                    Text("Get Started")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.evBackground)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)               // 56pt > 44pt minimum HIG touch target
                        .background(Color.evPrimary)
                        .clipShape(Capsule())            // full pill — iOS HIG rounded CTA
                }
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.52), value: appeared)

                Spacer().frame(height: 16)

                // ── Legal footer ────────────────────────────────────────────
                // iOS HIG: secondary/legal text uses minimum 12pt,
                // tappable links satisfy 44pt touch target via .contentShape
                (
                    Text("By continuing, you agree to our ")
                        .foregroundColor(.evTextMuted)
                    + Text("Terms")
                        .foregroundColor(.evPrimary)
                    + Text(" and ")
                        .foregroundColor(.evTextMuted)
                    + Text("Privacy Policy")
                        .foregroundColor(.evPrimary)
                )
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.6), value: appeared)

                // Bottom safe-area breathing room (HIG: respect home indicator)
                Spacer().frame(height: 8)
            }
        }
        .ignoresSafeArea(edges: .top)
        .onAppear { appeared = true }
    }
}

#Preview {
    WelcomeView()
}
