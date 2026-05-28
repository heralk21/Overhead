//
//  FlightTrackerWidgetLiveActivity.swift
//  FlightTrackerWidget
//
//  Created by Heral Kumar on 2026-05-14.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct FlightTrackerWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct FlightTrackerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FlightTrackerWidgetAttributes.self) { context in
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

extension FlightTrackerWidgetAttributes {
    fileprivate static var preview: FlightTrackerWidgetAttributes {
        FlightTrackerWidgetAttributes(name: "World")
    }
}

extension FlightTrackerWidgetAttributes.ContentState {
    fileprivate static var smiley: FlightTrackerWidgetAttributes.ContentState {
        FlightTrackerWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: FlightTrackerWidgetAttributes.ContentState {
         FlightTrackerWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: FlightTrackerWidgetAttributes.preview) {
   FlightTrackerWidgetLiveActivity()
} contentStates: {
    FlightTrackerWidgetAttributes.ContentState.smiley
    FlightTrackerWidgetAttributes.ContentState.starEyes
}
