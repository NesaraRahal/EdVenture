import SwiftUI

struct EVScreenTopBar: View {
    var onProfile: (() -> Void)?
    var onNotifications: (() -> Void)?
    var showNotifications: Bool = true

    var body: some View {
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
                if showNotifications {
                    EVLiquidGlassIconButton(systemName: "bell.fill") {
                        onNotifications?()
                    }
                }

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
