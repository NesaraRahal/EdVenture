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
        HStack(spacing: 12) {
            // Icon
            Image(systemName: attributes.lessonIcon)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(evHex: attributes.lessonColorHex))
                .frame(width: 32, height: 32)
                .background(Color(evHex: attributes.lessonColorHex).opacity(0.15))
                .clipShape(Circle())
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(attributes.lessonName)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // Time remaining
                HStack(spacing: 4) {
                    Image(systemName: "hourglass.bottomhalf.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(evHex: attributes.lessonColorHex))
                    
                    if hoursRemaining > 0 {
                        Text("\(hoursRemaining)h \(minutesRemaining)m")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                    } else {
                        Text("\(minutesRemaining)m \(secondsPartRemaining)s")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            
            Spacer()
            
            // Progress bar (vertical)
            VStack(spacing: 0) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(evHex: attributes.lessonColorHex).opacity(0.7),
                                Color(evHex: attributes.lessonColorHex).opacity(0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3, height: CGFloat(progressPercent * 40))
                
                Spacer()
                
                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 3, height: CGFloat((1 - progressPercent) * 40))
            }
            .frame(height: 40)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(evHex: attributes.lessonColorHex).opacity(0.2), lineWidth: 0.5)
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
        HStack(spacing: 8) {
            Image(systemName: attributes.lessonIcon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(evHex: attributes.lessonColorHex))
            
            VStack(alignment: .leading, spacing: 1) {
                Text(attributes.lessonName)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                if hoursRemaining > 0 {
                    Text("\(hoursRemaining)h \(minutesRemaining)m")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                } else {
                    Text("\(minutesRemaining)m")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
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
