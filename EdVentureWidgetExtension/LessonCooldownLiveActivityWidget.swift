import SwiftUI
import ActivityKit

/// Lock screen + Dynamic Island view for lesson cooldown timer
struct LessonCooldownLiveActivityView: View {
    let state: LessonCooldownActivityAttributes.ContentState
    let attributes: LessonCooldownActivityAttributes

    private var hoursRemaining: Int {
        max(0, state.secondsRemaining / 3600)
    }

    private var minutesRemaining: Int {
        max(0, (state.secondsRemaining % 3600) / 60)
    }

    private var secondsPartRemaining: Int {
        max(0, state.secondsRemaining % 60)
    }

    private var progressPercent: Double {
        let totalSeconds = 24.0 * 60.0 * 60.0
        return min(max(1.0 - (Double(state.secondsRemaining) / totalSeconds), 0), 1)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text("Next Level Cooldown")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(0.5)

                Text(state.unlockTime, style: .timer)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(evHex: attributes.lessonColorHex))
                    .monospacedDigit()
            }

            VStack(spacing: 6) {
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 6)
                    Capsule()
                        .fill(Color(evHex: attributes.lessonColorHex))
                        .frame(width: max(0, progressPercent) * 260, height: 6)
                }

                HStack {
                    Text("Time elapsed")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.45))
                    Spacer()
                    Text(String(format: "%.0f%%", progressPercent * 100))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.45))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(evHex: attributes.lessonColorHex).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(evHex: attributes.lessonColorHex).opacity(0.25), lineWidth: 0.6)
                )
        )
    }
}

// Compact presentation for Dynamic Island
struct LessonCooldownCompactView: View {
    let state: LessonCooldownActivityAttributes.ContentState
    let attributes: LessonCooldownActivityAttributes

    private var hoursRemaining: Int {
        max(0, state.secondsRemaining / 3600)
    }

    private var minutesRemaining: Int {
        max(0, (state.secondsRemaining % 3600) / 60)
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "hourglass")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(evHex: attributes.lessonColorHex))

            Text(state.unlockTime, style: .timer)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
                .monospacedDigit()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}

#if DEBUG
struct LessonCooldownLiveActivityView_Previews: PreviewProvider {
    static let attributes = LessonCooldownActivityAttributes(
        lessonName: "Astronomy",
        lessonIcon: "star.fill",
        lessonColorHex: "0EB060",
        unlockTime: Date().addingTimeInterval(24 * 60 * 60)
    )
    
    static let contentState = LessonCooldownActivityAttributes.ContentState(
        secondsRemaining: 30,
        unlockTime: Date().addingTimeInterval(24 * 60 * 60)
    )
    
    static var previews: some View {
        Group {
            LessonCooldownLiveActivityView(state: contentState, attributes: attributes)
                .previewDisplayName("Lock Screen")
            
            LessonCooldownCompactView(state: contentState, attributes: attributes)
                .previewDisplayName("Dynamic Island Compact")
        }
        .background(Color(evHex: "0A0F0D"))
    }
}
#endif

private extension Color {
    init(evHex: String) {
        let cleaned = evHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
