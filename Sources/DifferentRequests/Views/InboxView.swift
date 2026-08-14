import DifferentRequestsProtos
import SwiftUI

/// What a reader has been told: status changes, replies, and merges on requests they follow.
///
/// ```swift
/// NavigationStack {
///   InboxView(hub: requests)
/// }
/// ```
///
/// Reading a row is a tap on its unread dot, not a side effect of opening the request: a row
/// marked read by being scrolled past is a notification nobody saw.
public struct InboxView: View {

  private static let rowSpacing: CGFloat = 12
  private static let summarySpacing: CGFloat = 4

  /// What the screen reads from, and what a push from a row is built against.
  private let hub: DifferentRequestsHub

  /// The hub's inbox state, which outlives this screen and keeps the pages it has read.
  private let store: InboxStore

  /// - Parameter hub: What the host app built once and holds.
  public init(hub: DifferentRequestsHub) {
    self.hub = hub
    self.store = hub.inbox
  }

  public var body: some View {
    content
      .navigationTitle("Inbox")
      .toolbar {
        if store.unreadCount > 0 {
          ToolbarItem(placement: .primaryAction) {
            AsyncButton {
              await store.markAllRead()
            } label: {
              Text("Read All")
            }
          }
        }
      }
      .firstRead(hasLoaded: store.hasLoaded) {
        await store.load()
      }
  }

  // MARK: - Content

  /// The list stays up while a read is in flight even with nothing in it: a pull-to-refresh runs on
  /// the list's own task, and a page cleared at the start of a read would take the list — and the
  /// read with it.
  @ViewBuilder
  private var content: some View {
    if store.hasLoaded == false {
      ProgressView()
    } else if store.notifications.isEmpty == false || store.isLoading {
      list
    } else if store.loadError != nil {
      LoadFailure {
        await store.load()
      }
    } else {
      ContentUnavailableView {
        Label("Nothing yet", systemImage: "bell")
      } description: {
        Text("Vote for a request or follow one, and you'll hear when it moves.")
      }
    }
  }

  private var list: some View {
    List {
      ForEach(store.notifications, id: \.id) { notification in
        row(notification)
      }

      if store.hasMore {
        ProgressView()
          .frame(maxWidth: .infinity)
          .task {
            await store.loadMore()
          }
      }
    }
    .listStyle(.plain)
    .refreshable {
      await store.load()
    }
  }

  /// The dot sits beside the link rather than inside its label: a button inside a
  /// `NavigationLink` label never receives the tap.
  private func row(_ notification: DRNotification) -> some View {
    HStack(spacing: Self.rowSpacing) {
      NavigationLink {
        RequestDetailView(hub: hub, requestID: destinationID(notification))
      } label: {
        summary(notification)
      }

      if notification.hasReadAt == false {
        AsyncButton {
          await store.markRead(notificationID: notification.id)
        } label: {
          Image(systemName: "circle.fill")
            .font(.caption2)
            .foregroundStyle(Color.accentColor)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Mark as read")
      }
    }
  }

  private func summary(_ notification: DRNotification) -> some View {
    VStack(alignment: .leading, spacing: Self.summarySpacing) {
      Text(headline(notification))
        .font(.subheadline)
        .fontWeight(.semibold)

      Text(notification.requestTitle)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .lineLimit(2)

      if notification.hasCreatedAt {
        Text(notification.createdAt.date.formatted(.relative(presentation: .named)))
          .font(.caption)
          .foregroundStyle(.tertiary)
      }
    }
  }

  /// A merged request carries where the vote went, and that is the request worth opening — the
  /// one it was folded into now holds the demand.
  private func destinationID(_ notification: DRNotification) -> String {
    if notification.mergedIntoRequestID.isEmpty == false {
      return notification.mergedIntoRequestID
    }
    return notification.requestID
  }

  /// A kind this SDK version does not know still says something happened, rather than rendering
  /// an empty row: the request title underneath is what the reader recognises anyway.
  private func headline(_ notification: DRNotification) -> String {
    switch notification.kind {
    case .statusChanged:
      return "Now \(notification.newStatus.badgeLabel)"
    case .commentAdded:
      return "New comment"
    case .requestMerged:
      return "Folded into another request"
    case .unspecified, .UNRECOGNIZED:
      return "Updated"
    }
  }
}
