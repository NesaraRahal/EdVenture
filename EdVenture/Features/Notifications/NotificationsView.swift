import SwiftUI

struct NotificationsView: View {
    @StateObject private var vm = NotificationsViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var expandedNotificationId: String?

    var body: some View {
        ZStack {
            Color(hex: "0F0F0F").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    if vm.filteredNotifications.isEmpty {
                        emptyState
                    } else {
                        ForEach(vm.filteredNotifications) { notification in
                            NotificationCard(
                                notification: notification,
                                isExpanded: expandedNotificationId == notification.id,
                                onTap: {
                                    withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                                        if expandedNotificationId == notification.id {
                                            expandedNotificationId = nil
                                        } else {
                                            expandedNotificationId = notification.id
                                        }
                                    }
                                    vm.markAsRead(notification)
                                },
                                onDelete: {
                                    vm.deleteNotification(notification)
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                topChrome
            }
        }
        .navigationBarHidden(true)
    }

    private var topChrome: some View {
        VStack(spacing: 14) {
            ZStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .frame(height: 42)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                    }

                    Spacer()

                    Color.clear
                        .frame(width: 78, height: 42)
                }

                Text("Notifications")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 96)
            }

            HStack(spacing: 12) {
                tabButton("All")
                tabButton("Unread")
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(Color(hex: "0F0F0F"))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 40, weight: .semibold))
                .foregroundColor(.white.opacity(0.35))

            Text("No notifications")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
        .padding(.bottom, 30)
    }

    private func tabButton(_ tab: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                vm.selectedTab = tab
            }
        } label: {
            Text(tab)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(vm.selectedTab == tab ? .white : .white.opacity(0.55))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    vm.selectedTab == tab
                        ? Color(hex: "0EB060")
                        : Color.white.opacity(0.06)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Notification Card
private struct NotificationCard: View {
    let notification: EVNotification
    let isExpanded: Bool
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 14) {
                Circle()
                    .fill(notification.type.color.opacity(0.2))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: notification.type.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(notification.type.color)
                    )

                VStack(alignment: .leading, spacing: 6) {
                    Text(notification.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text(notification.description)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.white.opacity(0.58))
                        .lineLimit(isExpanded ? 6 : 2)

                    if isExpanded {
                        Divider()
                            .overlay(Color.white.opacity(0.08))

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Details")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))

                            Text(expandedDetailText)
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(6)
                        }
                    }
                }

                Spacer(minLength: 10)

                VStack(alignment: .trailing, spacing: 8) {
                    Text(notification.timeAgo)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.45))

                    if !notification.isRead {
                        Circle()
                            .fill(Color(hex: "0EB060"))
                            .frame(width: 10, height: 10)
                    }
                }

            }
            .padding(14)
            .padding(.trailing, 30)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .onTapGesture {
                onTap()
            }

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.45))
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .padding(.top, 10)
            .padding(.trailing, 10)
            .buttonStyle(.plain)
        }
    }

    private var expandedDetailText: String {
        "Received \(formattedTimestamp)"
    }

    private var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: notification.timestamp)
    }
}

#Preview {
    NotificationsView()
}
