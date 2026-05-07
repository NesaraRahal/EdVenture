import SwiftUI
import WidgetKit
import ActivityKit

/// Live Activity UI for Lesson Cooldown - shown on lock screen and Dynamic Island
@available(iOS 16.1, *)
struct LessonCooldownLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LessonCooldownActivityAttributes.self) { context in
            // Lock Screen (expanded) view
            lockScreenView(context: context)
        } dynamicIsland: { context in
            // Dynamic Island view
            dynamicIslandView(context: context)
        }
    }
    
    // MARK: - Lock Screen View
    
    private func lockScreenView(context: ActivityViewContext<LessonCooldownActivityAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: context.attributes.lessonIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: context.attributes.lessonColorHex))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.lessonName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Level Cooldown")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(timerDisplay(context.state.secondsRemaining))
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: context.attributes.lessonColorHex))
                    
                    Text("Remaining")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            // Progress bar showing time elapsed
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))
                    
                    // Progress
                    let totalSeconds = 24 * 60 * 60
                    let secondsElapsed = max(0, totalSeconds - context.state.secondsRemaining)
                    let progress = totalSeconds > 0 ? Double(secondsElapsed) / Double(totalSeconds) : 0
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: context.attributes.lessonColorHex))
                        .frame(width: geo.size.width * progress)
                }
                .frame(height: 4)
            }
            .frame(height: 4)
        }
        .padding(12)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    // MARK: - Dynamic Island View
    
    private func dynamicIslandView(
        context: ActivityViewContext<LessonCooldownActivityAttributes>
    ) -> DynamicIsland {
        DynamicIsland {
            DynamicIslandExpandedRegion(.leading) {
                HStack(spacing: 6) {
                    Image(systemName: context.attributes.lessonIcon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: context.attributes.lessonColorHex))

                    Text(context.attributes.lessonName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
            }

            DynamicIslandExpandedRegion(.trailing) {
                Text(context.state.displayText)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(1)
            }

            DynamicIslandExpandedRegion(.bottom) {
                HStack(spacing: 8) {
                    Text("Level Cooldown")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))

                    Spacer()

                    Text(timerDisplay(context.state.secondsRemaining))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: context.attributes.lessonColorHex))
                }
                .padding(.top, 2)
            }
        } compactLeading: {
            Image(systemName: context.attributes.lessonIcon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: context.attributes.lessonColorHex))
        } compactTrailing: {
            Text(timerDisplay(context.state.secondsRemaining))
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .lineLimit(1)
        } minimal: {
            Image(systemName: context.attributes.lessonIcon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: context.attributes.lessonColorHex))
        }
    }
    
    // MARK: - Helper
    
    private func timerDisplay(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}

