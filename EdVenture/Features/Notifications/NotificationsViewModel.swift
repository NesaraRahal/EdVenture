import SwiftUI
import Combine

struct EVNotification: Identifiable {
    let id: String
    let title: String
    let description: String
    let type: NotificationType
    let timestamp: Date
    var isRead: Bool

    var timeAgo: String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: timestamp, to: now)

        if let day = components.day, day > 0 {
            return day == 1 ? "1D" : "\(day)D"
        } else if let hour = components.hour, hour > 0 {
            return hour == 1 ? "1H" : "\(hour)H"
        } else if let minute = components.minute, minute > 0 {
            return minute == 1 ? "1M" : "\(minute)M"
        } else {
            return "now"
        }
    }
}

enum NotificationType: String {
    case leaderboardMilestone = "Leaderboard Milestone"
    case newLesson = "New Lesson"
    case reward = "Reward"
    case lessonAdded = "Lesson Added"
    case achievement = "Achievement"

    var icon: String {
        switch self {
        case .leaderboardMilestone:
            return "chart.bar.fill"
        case .newLesson:
            return "rocket.fill"
        case .reward:
            return "star.fill"
        case .lessonAdded:
            return "checkmark.circle.fill"
        case .achievement:
            return "crown.fill"
        }
    }

    var color: Color {
        switch self {
        case .leaderboardMilestone:
            return Color(hex: "0EB060")
        case .newLesson:
            return Color(hex: "00D4FF")
        case .reward:
            return Color(hex: "FFB800")
        case .lessonAdded:
            return Color(hex: "0EB060")
        case .achievement:
            return Color(hex: "FF6B6B")
        }
    }
}

@MainActor
final class NotificationsViewModel: ObservableObject {
    @Published var selectedTab: String = "All"
    @Published private(set) var notifications: [EVNotification] = []

    private let notificationsStore: NotificationsStore

    private var cancellables = Set<AnyCancellable>()

    init(notificationsStore: NotificationsStore = .shared) {
        self.notificationsStore = notificationsStore
        self.notifications = notificationsStore.notifications

        notificationsStore.$notifications
            .receive(on: RunLoop.main)
            .sink { [weak self] items in
                self?.notifications = items
            }
            .store(in: &cancellables)
    }

    var filteredNotifications: [EVNotification] {
        if selectedTab == "Unread" {
            return notifications.filter { !$0.isRead }
        }
        return notifications
    }

    func markAsRead(_ notification: EVNotification) {
        notificationsStore.markAsRead(notification)
    }

    func deleteNotification(_ notification: EVNotification) {
        notificationsStore.deleteNotification(notification)
    }
}
