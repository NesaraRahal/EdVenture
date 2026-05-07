import SwiftUI

struct EVBackButton: View {
    let title: String
    let action: () -> Void
    var compactTitleSize: CGFloat = 16
    var isDark: Bool = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: compactTitleSize, weight: .bold, design: .rounded))
            }
            .foregroundColor(isDark ? Color(hex: "0A0F0D") : .white)
            .padding(.horizontal, 18)
            .frame(height: 50)
            .background(isDark ? Color.white.opacity(0.82) : Color.white.opacity(0.18))
            .clipShape(Capsule())
        }
        .frame(minWidth: 44, minHeight: 44)
    }
}
