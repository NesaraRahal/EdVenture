import SwiftUI
import ActivityKit

/// Lock screen + Dynamic Island view for lesson cooldown timer
struct LessonCooldownLiveActivityView: View {
    let state: LessonCooldownActivityAttributes.ContentState
    let attributes: LessonCooldownActivityAttributes
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: state.lessonIcon)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(hex: state.lessonColor))
                .frame(width: 32, height: 32)
                .background(Color(hex: state.lessonColor).opacity(0.15))
                .clipShape(Circle())
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(state.lessonName)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // Time remaining
                HStack(spacing: 4) {
                    Image(systemName: "hourglass.bottomhalf.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: state.lessonColor))
                    
                    if state.hoursRemaining > 0 {
                        Text("\(state.hoursRemaining)h \(state.minutesRemaining)m")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                    } else {
                        Text("\(state.minutesRemaining)m \(state.secondsRemaining)s")
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
                                Color(hex: state.lessonColor).opacity(0.7),
                                Color(hex: state.lessonColor).opacity(0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3, height: CGFloat(state.progressPercent * 40))
                
                Spacer()
                
                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 3, height: CGFloat((1 - state.progressPercent) * 40))
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
                        .stroke(Color(hex: state.lessonColor).opacity(0.2), lineWidth: 0.5)
                )
        )
    }
}

// Compact presentation for Dynamic Island
struct LessonCooldownCompactView: View {
    let state: LessonCooldownActivityAttributes.ContentState
    let attributes: LessonCooldownActivityAttributes
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: state.lessonIcon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: state.lessonColor))
            
            VStack(alignment: .leading, spacing: 1) {
                Text(state.lessonName)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                if state.hoursRemaining > 0 {
                    Text("\(state.hoursRemaining)h \(state.minutesRemaining)m")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                } else {
                    Text("\(state.minutesRemaining)m")
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
        lessonId: "astronomy",
        lessonTitle: "Astronomy",
        icon: "star.fill",
        colorHex: "0EB060"
    )
    
    static let contentState = LessonCooldownActivityAttributes.ContentState(
        lessonName: "Astronomy",
        lessonIcon: "star.fill",
        lessonColor: "0EB060",
        hoursRemaining: 23,
        minutesRemaining: 45,
        secondsRemaining: 30,
        unlockAt: Date().addingTimeInterval(24 * 60 * 60),
        progressPercent: 0.02
    )
    
    static var previews: some View {
        Group {
            LessonCooldownLiveActivityView(state: contentState, attributes: attributes)
                .previewDisplayName("Lock Screen")
            
            LessonCooldownCompactView(state: contentState, attributes: attributes)
                .previewDisplayName("Dynamic Island Compact")
        }
        .background(Color(hex: "0A0F0D"))
    }
}
#endif
