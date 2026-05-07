import Foundation
import WidgetKit

struct HomeWidgetSnapshot: Codable, Hashable {
    var updatedAt: Date
    var lessonName: String?
    var lessonIcon: String?
    var lessonColorHex: String?
    var cooldownEndsAt: Date?
    var rankText: String
    var playTimeText: String
    var activeLessonsText: String
    var greetingName: String

    static let placeholder = HomeWidgetSnapshot(
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

enum HomeWidgetSnapshotStore {
    static let appGroupIdentifier = "group.com.yourcompany.EdVenture"
    static let snapshotKey = "home-widget-snapshot"
    static let widgetKind = "EdVentureHomeWidget"

    static func load() -> HomeWidgetSnapshot {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier),
              let data = defaults.data(forKey: snapshotKey),
              let snapshot = try? JSONDecoder().decode(HomeWidgetSnapshot.self, from: data)
        else {
            print("[Widget] ⚠️  No snapshot found, using placeholder")
            return .placeholder
        }

        print("[Widget] ✅ Loaded snapshot: \(snapshot.lessonName ?? "nil") | Rank: \(snapshot.rankText)")
        return snapshot
    }

    static func save(_ snapshot: HomeWidgetSnapshot) {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier),
              let data = try? JSONEncoder().encode(snapshot)
        else {
            print("[Widget] ❌ Failed to save snapshot: no defaults or encoding failed")
            return
        }

        defaults.set(data, forKey: snapshotKey)
        print("[Widget] ✅ Saved snapshot: \(snapshot.lessonName ?? "nil") | Rank: \(snapshot.rankText) | Play: \(snapshot.playTimeText)")
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
        print("[Widget] 🔄 Reloaded widget timelines")
    }

    static func updateProfile(greetingName: String? = nil,
                              rankText: String? = nil,
                              playTimeText: String? = nil,
                              activeLessonsCount: Int? = nil) {
        var snapshot = load()

        if let greetingName {
            snapshot.greetingName = greetingName
        }

        if let rankText {
            snapshot.rankText = rankText
        }

        if let playTimeText {
            snapshot.playTimeText = playTimeText
        }

        if let activeLessonsCount {
            snapshot.activeLessonsText = "\(activeLessonsCount) Lessons"
        }

        snapshot.updatedAt = .now
        save(snapshot)
    }

    static func updateCooldown(from status: LessonCooldownStatus?) {
        var snapshot = load()

        if let status {
            snapshot.lessonName = status.lessonName
            snapshot.lessonIcon = status.lessonIcon
            snapshot.lessonColorHex = status.lessonColorHex
            snapshot.cooldownEndsAt = status.cooldownExpiresAt
        } else {
            snapshot.lessonName = nil
            snapshot.lessonIcon = nil
            snapshot.lessonColorHex = nil
            snapshot.cooldownEndsAt = nil
        }

        snapshot.updatedAt = .now
        save(snapshot)
    }

    static func clearCooldown() {
        updateCooldown(from: nil)
    }
}
