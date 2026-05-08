import SwiftUI
import ActivityKit
import Combine

@MainActor
final class NotificationsStore: ObservableObject {
    static let shared = NotificationsStore()

    @Published var notifications: [EVNotification] = []

    private let persistence = EVNotificationsCoreDataStore.shared

    private init() {
        loadNotifications()
    }

    private func loadNotifications() {
        let storedNotifications = persistence.loadNotifications()
        if !storedNotifications.isEmpty {
            notifications = storedNotifications
            return
        }

        // Migrate older UserDefaults-backed notifications into Core Data once.
        if let data = UserDefaults.standard.data(forKey: "notifications.list"),
           let decoded = try? JSONDecoder().decode([EVNotification].self, from: data) {
            notifications = decoded.sorted { $0.timestamp > $1.timestamp }
            persistence.saveNotifications(notifications)
            UserDefaults.standard.removeObject(forKey: "notifications.list")
        }
    }

    // MARK: - Add new notification

    func addNotification(
        title: String,
        description: String,
        type: NotificationType
    ) {
        let notification = EVNotification(
            id: UUID().uuidString,
            title: title,
            description: description,
            type: type,
            timestamp: Date(),
            isRead: false
        )

        notifications.insert(notification, at: 0)
        saveNotifications()

        // Send push notification
        Task {
            await sendPushNotification(notification)
        }

        // Show Dynamic Island activity
        Task {
            await showDynamicIslandActivity(notification)
        }
    }

    private func saveNotifications() {
        persistence.saveNotifications(notifications)
    }

    func markAsRead(_ notification: EVNotification) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
            saveNotifications()
        }
    }

    func deleteNotification(_ notification: EVNotification) {
        notifications.removeAll { $0.id == notification.id }
        saveNotifications()
    }

    // MARK: - Push Notifications

    private func sendPushNotification(_ notification: EVNotification) async {
        _ = await EVNotificationService.shared.sendInstantNotification(
            title: notification.title,
            body: notification.description,
            identifierPrefix: "ev.notifications.inapp"
        )
    }

    // MARK: - Dynamic Island

    private func showDynamicIslandActivity(_ notification: EVNotification) async {
        // Dynamic Island is only available on iOS 16.1+
        guard #available(iOS 16.1, *) else { return }

        let attributes = NotificationActivityAttributes(
            title: notification.title,
            description: notification.description
        )

        let state = NotificationActivityAttributes.ContentState(
            notificationId: notification.id,
            type: notification.type.rawValue,
            timestamp: Date()
        )

        do {
            let activity = try Activity<NotificationActivityAttributes>.request(
                attributes: attributes,
                contentState: state,
                pushType: nil
            )

            // Dismiss after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                Task {
                    await activity.end(dismissalPolicy: .immediate)
                }
            }
        } catch {
            print("Error showing Dynamic Island activity: \(error)")
        }
    }
}

// MARK: - Activity Attributes for Dynamic Island

@available(iOS 16.1, *)
struct NotificationActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var notificationId: String
        var type: String
        var timestamp: Date
    }

    var title: String
    var description: String
}

// MARK: - Codable extension for EVNotification

extension EVNotification: Codable {
    enum CodingKeys: String, CodingKey {
        case id, title, description, type, timestamp, isRead
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        let typeString = try container.decode(String.self, forKey: .type)
        type = NotificationType(rawValue: typeString) ?? .achievement
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        isRead = try container.decode(Bool.self, forKey: .isRead)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(type.rawValue, forKey: .type)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(isRead, forKey: .isRead)
    }
}
