import SwiftUI

enum EVMainTab: CaseIterable {
    case home
    case lessons
    case discovery
    case rank
    case settings

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .lessons: return "book.fill"
        case .discovery: return "safari"
        case .rank: return "chart.bar.fill"
        case .settings: return "gearshape.fill"
        }
    }

    var title: String {
        switch self {
        case .home: return "HOME"
        case .lessons: return "LESSONS"
        case .discovery: return "DISCOVERY"
        case .rank: return "RANK"
        case .settings: return "SETTINGS"
        }
    }
}

struct EVMainTabBar: View {
    let activeTab: EVMainTab
    var onSelect: (EVMainTab) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(EVMainTab.allCases, id: \.self) { tab in
                Button {
                    onSelect(tab)
                } label: {
                    VStack(spacing: 6) {
                        if tab == activeTab {
                            ZStack {
                                Capsule()
                                    .fill(Color(hex: "0EB060"))
                                    .frame(width: 88, height: 44)
                                Image(systemName: tab.icon)
                                    .font(.system(size: 19, weight: .semibold))
                                    .foregroundColor(Color(hex: "0A0F0D"))
                            }
                            .shadow(color: Color(hex: "0EB060").opacity(0.35), radius: 14, y: 2)
                        } else {
                            Image(systemName: tab.icon)
                                .font(.system(size: 21, weight: .medium))
                                .foregroundColor(.white.opacity(0.45))
                                .frame(height: 44)
                        }

                        Text(tab.title)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(tab == activeTab ? Color(hex: "0EB060") : .white.opacity(0.35))
                            .tracking(0.5)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                }
            }
        }
        .padding(.top, 14)
        .padding(.bottom, 22)
        .padding(.horizontal, 10)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 34, style: .continuous).fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "1A201E").opacity(0.86), Color(hex: "141A18").opacity(0.84)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.6)
            }
        )
        .padding(.horizontal, 16)
        .shadow(color: .black.opacity(0.45), radius: 22, y: -4)
    }
}
