//
//  EdVentureWidgetExtensionLiveActivity.swift
//  EdVentureWidgetExtension
//
//  Created by COBSCCOMP24.2P-053 on 2026-05-07.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct EdVentureWidgetExtensionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct EdVentureWidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: EdVentureWidgetExtensionAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension EdVentureWidgetExtensionAttributes {
    fileprivate static var preview: EdVentureWidgetExtensionAttributes {
        EdVentureWidgetExtensionAttributes(name: "World")
    }
}

extension EdVentureWidgetExtensionAttributes.ContentState {
    fileprivate static var smiley: EdVentureWidgetExtensionAttributes.ContentState {
        EdVentureWidgetExtensionAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: EdVentureWidgetExtensionAttributes.ContentState {
         EdVentureWidgetExtensionAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: EdVentureWidgetExtensionAttributes.preview) {
   EdVentureWidgetExtensionLiveActivity()
} contentStates: {
    EdVentureWidgetExtensionAttributes.ContentState.smiley
    EdVentureWidgetExtensionAttributes.ContentState.starEyes
}
