import SwiftUI

/// A view displaying the authenticated user's in-app notification inbox.
///
/// Tapping a notification marks it read and deep-links to the request it's
/// about. Shows a paginated list with pull-to-refresh and infinite scroll.
///
/// ```swift
/// NotificationCenterView(client: client)
/// ```
public struct NotificationCenterView: View {

  @State private var model: NotificationCenterModel
  private let client: DifferentRequestsClient

  /// Creates the notification center view.
  /// - Parameter client: The DifferentRequests client to use.
  public init(client: DifferentRequestsClient) {
    self.client = client
    self._model = State(initialValue: NotificationCenterModel(client: client))
  }

  public var body: some View {
    NavigationStack {
      Group {
        if model.isLoading && model.notifications.isEmpty {
          ProgressView("Loading notifications...")
        } else if let error = model.error, model.notifications.isEmpty {
          ContentUnavailableView {
            Label("Failed to load", systemImage: "exclamationmark.triangle")
          } description: {
            Text(error.localizedDescription)
          } actions: {
            Button("Retry") { Task { await model.load() } }
          }
        } else if model.notifications.isEmpty {
          ContentUnavailableView(
            "No notifications yet",
            systemImage: "bell",
            description: Text("Updates on requests you follow will appear here.")
          )
        } else {
          notificationList
        }
      }
      .navigationTitle("Notifications")
      .navigationDestination(for: String.self) { requestId in
        RequestDetailView(client: client, requestId: requestId)
      }
      .task {
        await model.load()
        await model.refreshUnreadCount()
      }
    }
  }

  // MARK: - Subviews

  private var notificationList: some View {
    List {
      ForEach(model.notifications) { notification in
        NavigationLink(value: notification.requestId) {
          NotificationRow(notification: notification)
        }
        .simultaneousGesture(TapGesture().onEnded {
          if !notification.read {
            Task { await model.markRead(id: notification.id) }
          }
        })
      }

      if model.hasMore {
        ProgressView()
          .frame(maxWidth: .infinity)
          .task { await model.loadMore() }
      }
    }
    .listStyle(.plain)
    .refreshable {
      await model.load()
      await model.refreshUnreadCount()
    }
  }
}

// MARK: - Notification Row

private struct NotificationRow: View {
  let notification: AppNotification

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Circle()
        .fill(notification.read ? Color.clear : Color.accentColor)
        .frame(width: 8, height: 8)
        .padding(.top, 6)

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.subheadline)
          .fontWeight(notification.read ? .regular : .semibold)

        Text(DateFormatting.formatted(notification.createdAt))
          .font(.caption2)
          .foregroundStyle(.tertiary)
      }
    }
    .padding(.vertical, 4)
  }

  private var title: String {
    switch notification.type {
    case .statusChange:
      guard let status = notification.status else { return "Status changed" }
      let label = RequestStatus(rawValue: status)?.label ?? status
      return "Status changed to \(label)"
    case .comment:
      return "New comment"
    case .officialReply:
      return "Team replied"
    case .changelogPublished:
      return "What's New"
    }
  }
}

// MARK: - Preview

#Preview("Notification Center") {
  NotificationCenterView(client: DifferentRequestsClient(apiKey: "preview"))
}
