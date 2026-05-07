import WidgetKit
import SwiftUI

struct WidgetHomeSnapshot: Codable, Hashable {
    var updatedAt: Date
    var lessonName: String?
    var lessonIcon: String?
    var lessonColorHex: String?
    var cooldownEndsAt: Date?
    var rankText: String
    var playTimeText: String
    var activeLessonsText: String
    var greetingName: String

    static let placeholder = WidgetHomeSnapshot(
        updatedAt: .now,
        lessonName: nil,
        lessonIcon: nil,
        lessonColorHex: nil,
        cooldownEndsAt: nil,
        rankText: "Amateur",
        playTimeText: "0m",
        activeLessonsText: "0 Lessons",
        greetingName: "Learner"
    )
}

enum WidgetHomeSnapshotStore {
    static let appGroupIdentifier = "group.com.yourcompany.EdVenture"
    static let snapshotKey = "home-widget-snapshot"
    static let widgetKind = "EdVentureHomeWidget"

    static func load() -> WidgetHomeSnapshot {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier),
              let data = defaults.data(forKey: snapshotKey),
              let snapshot = try? JSONDecoder().decode(WidgetHomeSnapshot.self, from: data)
        else {
            return .placeholder
        }

        return snapshot
    }
}

struct EdVentureHomeWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetHomeSnapshot
}

struct EdVentureHomeWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> EdVentureHomeWidgetEntry {
        EdVentureHomeWidgetEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (EdVentureHomeWidgetEntry) -> Void) {
        completion(EdVentureHomeWidgetEntry(date: .now, snapshot: WidgetHomeSnapshotStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EdVentureHomeWidgetEntry>) -> Void) {
        let snapshot = WidgetHomeSnapshotStore.load()
        let entry = EdVentureHomeWidgetEntry(date: .now, snapshot: snapshot)

        let nextRefresh: Date
        if let cooldownEndsAt = snapshot.cooldownEndsAt {
            nextRefresh = cooldownEndsAt.addingTimeInterval(1)
        } else {
            nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now.addingTimeInterval(900)
        }

        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

struct EdVentureHomeWidgetEntryView: View {
    let entry: EdVentureHomeWidgetEntry

    private var accentColor: Color {
        Color(evHex: entry.snapshot.lessonColorHex ?? "0EB060")
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.06, green: 0.06, blue: 0.06), Color(red: 0.08, green: 0.08, blue: 0.08)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Cooldown Status")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(0.5)

                        Text(entry.snapshot.lessonName ?? "All Set")
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        if let icon = entry.snapshot.lessonIcon {
                            Image(systemName: icon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(accentColor)
                        }

                        if let cooldownEndsAt = entry.snapshot.cooldownEndsAt {
                            Text(cooldownEndsAt, style: .timer)
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        } else {
                            Text("Ready")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(evHex: "0EB060"))
                        }
                    }
                }

                // Cooldown detail
                if let cooldownEndsAt = entry.snapshot.cooldownEndsAt {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(accentColor.opacity(0.3))
                                .frame(width: 6, height: 6)

                            Text("Ready at ")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.65))
                            +
                            Text(cooldownEndsAt, style: .time)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(accentColor.opacity(0.1))
                    )
                } else {
                    Text("All lessons ready to continue.")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }

                // Stats
                HStack(spacing: 8) {
                    statChip(title: "RANK", value: entry.snapshot.rankText, accent: Color(evHex: "0EB060"))
                    statChip(title: "PLAY", value: entry.snapshot.playTimeText, accent: Color(evHex: "F59E0B"))
                    statChip(title: "ACTIVE", value: entry.snapshot.activeLessonsText, accent: Color(evHex: "38BDF8"))
                }
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .containerBackground(Color.black, for: .widget)
    }

    private func statChip(title: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(1.1)
                .foregroundColor(.white.opacity(0.5))
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(accent.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(accent.opacity(0.3), lineWidth: 1)
                )
        )
    }
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

struct EdVentureHomeWidget: Widget {
    let kind = WidgetHomeSnapshotStore.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EdVentureHomeWidgetProvider()) { entry in
            EdVentureHomeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Cooldown Dashboard")
        .description("Shows the next lesson cooldown, rank, and play time.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

#Preview(as: .systemMedium) {
    EdVentureHomeWidget()
} timeline: {
    EdVentureHomeWidgetEntry(date: .now, snapshot: .placeholder)
}
