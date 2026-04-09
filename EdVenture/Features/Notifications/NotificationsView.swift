import SwiftUI

struct NotificationsView: View {
    @StateObject private var vm = NotificationsViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color(hex: "0F0F0F")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Header
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
                        .frame(height: 40)
                        .padding(.horizontal, 12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(20)
                    }

                    Spacer()

                    Text("Notifications")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    // Placeholder for alignment
                    Color.clear
                        .frame(width: 70)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .padding(.top, 52)

                // MARK: - Tabs
                HStack(spacing: 12) {
                    ForEach(["All", "Unread"], id: \.self) { tab in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                vm.selectedTab = tab
                            }
                        } label: {
                            Text(tab)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(vm.selectedTab == tab ? .white : .gray)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    vm.selectedTab == tab
                                        ? Color(hex: "0EB060")
                                        : Color.white.opacity(0.05)
                                )
                                .cornerRadius(20)
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 10)

                // MARK: - Notifications List
                ScrollView {
                    VStack(spacing: 12) {
                        if vm.filteredNotifications.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "bell.slash.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)

                                Text("No notifications")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ForEach(vm.filteredNotifications) { notification in
                                NotificationCard(
                                    notification: notification,
                                    onTap: {
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
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Notification Card
private struct NotificationCard: View {
    let notification: EVNotification
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 12) {
                // Icon container
                Circle()
                    .fill(notification.type.color.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: notification.type.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(notification.type.color)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(notification.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)

                        Spacer()

                        Text(notification.timeAgo)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.gray)
                    }

                    Text(notification.description)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    if !notification.isRead {
                        Circle()
                            .fill(Color(hex: "0EB060"))
                            .frame(width: 8, height: 8)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .onTapGesture {
                onTap()
            }

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray)
                    .frame(width: 24, height: 24)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
            }
            .padding(12)
        }
    }
}

#Preview {
    NotificationsView()
}
