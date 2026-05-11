//
//  EdVentureWidgetExtensionLiveActivity.swift
//  EdVentureWidgetExtension
//
//  Created by COBSCCOMP24.2P-053 on 2026-05-07.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct EdVentureWidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LessonCooldownActivityAttributes.self) { context in
            LessonCooldownLiveActivityView(
                state: context.state,
                attributes: context.attributes
            )
            .activityBackgroundTint(Color.black.opacity(0.9))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.attributes.lessonIcon)
                        .foregroundColor(Color(evHex: context.attributes.lessonColorHex))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.unlockTime, style: .timer)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    LessonCooldownCompactView(
                        state: context.state,
                        attributes: context.attributes
                    )
                }
            } compactLeading: {
                Image(systemName: context.attributes.lessonIcon)
                    .foregroundColor(Color(evHex: context.attributes.lessonColorHex))
            } compactTrailing: {
                Text(context.state.unlockTime, style: .timer)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            } minimal: {
                Image(systemName: "hourglass")
            }
            .keylineTint(Color(evHex: context.attributes.lessonColorHex))
        }
    }
}

#Preview("Notification", as: .content, using: LessonCooldownActivityAttributes(
    lessonName: "Astronomy",
    lessonIcon: "star.fill",
    lessonColorHex: "0EB060",
    unlockTime: Date().addingTimeInterval(24 * 60 * 60)
)) {
    EdVentureWidgetExtensionLiveActivity()
} contentStates: {
    LessonCooldownActivityAttributes.ContentState(
        secondsRemaining: 60 * 60 * 4 + 31,
        unlockTime: Date().addingTimeInterval(60 * 60 * 4 + 31)
    )
}

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
