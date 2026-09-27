import DifferentRequestsProtos
import SwiftUI

/// What a reader has been told: status changes, replies, and duplicates on requests they follow.
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
  private static let unreadDotWidth: CGFloat = 12

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
    VStack(spacing: 0) {
      PoweredByBadge(appConfig: hub.appConfig)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.bottom, 6)

      content
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
      .navigationTitle(Text("Inbox", bundle: .module, comment: "Menu item and title of the screen listing updates on requests"))
      .worn(by: hub.appearanceDrawn)
      .sheetDoneButton()
      .sheetMinimumSize()
      .task {
        await hub.appConfig.load()
      }
      .toolbar {
        if store.unreadCount > 0 {
          ToolbarItem(placement: .primaryAction) {
            AsyncButton {
              await store.markAllRead()
            } label: {
              Text("Mark all as read", bundle: .module, comment: "Button that marks every inbox update read")
            }
            .disabled(store.write.isWriting)
          }
        }
      }
      .task {
        // Every time, not only the first: an inbox is the list of what changed while somebody was
        // elsewhere, and coming back to it is exactly the moment that list is out of date. A read
        // already in flight is not started twice, so returning costs one round trip at most.
        await hub.whoIsHere.read()
        if hub.whoIsHere.somebodyIsHere {
          await store.load()
        }
      }
  }

  // MARK: - Content

  /// Four outcomes, from one state. The list stays up through a refresh even while its rows are
  /// being replaced: a pull-to-refresh runs on the list's own task, and a list that disappears
  /// takes that task with it.
  @ViewBuilder
  private var content: some View {
    if hub.whoIsHere.somebodyIsHere {
      switch store.read {
      case .unread, .reading:
        ProgressView()
      case .failed(let error):
        LoadFailure(error: error) {
          await store.load()
        }
      case .empty:
        nothingYet
      case .loaded(let notifications), .refreshing(let notifications):
        list(notifications)
      }
    } else {
      nothingYet
    }
  }

  /// An inbox with nothing in it, which is also what one belonging to nobody holds.
  private var nothingYet: some View {
    ContentUnavailableView {
      Label {
        Text("Nothing yet", bundle: .module, comment: "Heading on an empty inbox")
      } icon: {
        Image(systemName: "bell")
      }
    } description: {
      Text("Vote for or follow a request, and you'll get updates here when it changes.", bundle: .module, comment: "Message on an empty inbox")
    }
  }

  private func list(_ notifications: [DRNotification]) -> some View {
    List {
      if let failure = store.write.failure {
        Section {
          WriteFailureNotice(failure: failure) {
            store.acknowledgeWriteFailure()
          }
        }
      }

      ForEach(notifications, id: \.id) { notification in
        row(notification)
      }

      if store.page.isDone == false {
        NextPageRow(state: store.page) {
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
  ///
  /// Every dot goes inert while any stamp is being written, because the store writes one at a
  /// time. Without that, a second dot tapped during the first one's round trip is refused before
  /// it reaches the network and nothing at all happens on screen.
  private func row(_ notification: DRNotification) -> some View {
    HStack(spacing: Self.rowSpacing) {
      // Always the same width, read or not, so every row's text and chevron line up.
      if notification.hasReadAt == false {
        AsyncButton {
          await store.markRead(notificationID: notification.id)
        } label: {
          Image(systemName: "circle.fill")
            .font(.caption2)
            .foregroundStyle(dotTint)
            .frame(width: Self.unreadDotWidth)
        }
        .buttonStyle(.plain)
        .disabled(store.write.isWriting)
        .accessibilityLabel(Text("Mark as read", bundle: .module, comment: "VoiceOver label for the unread dot on an inbox update"))
      } else {
        Color.clear
          .frame(width: Self.unreadDotWidth)
          .accessibilityHidden(true)
      }

      NavigationLink {
        RequestDetailView(hub: hub, requestID: destinationID(notification))
          // Opening it is reading it. The dot beside the row stays, for marking one read without
          // opening it, but a person who has read the thing should not have to say so twice.
          .task {
            if notification.hasReadAt == false {
              await store.markRead(notificationID: notification.id)
            }
          }
      } label: {
        summary(notification)
      }
    }
  }

  /// `.buttonStyle(.plain)` renders its own label, so a disabled plain button looks exactly like
  /// an enabled one. The dim is stated here instead, or the inert dot would be inert in secret.
  private var dotTint: AnyShapeStyle {
    if store.write.isWriting {
      return AnyShapeStyle(HierarchicalShapeStyle.tertiary)
    }
    return AnyShapeStyle(Color.accentColor)
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
        Text(notification.createdAt.date.ago)
          .font(.caption)
          .foregroundStyle(.tertiary)
      }
    }
  }

  /// Where a tap lands.
  ///
  /// Only duplicate news names somewhere else, and it names it on its own arm — so a tap can no
  /// longer be routed by a target that arrived on news that was never about a duplicate.
  private func destinationID(_ notification: DRNotification) -> String {
    switch notification.news {
    case .requestDuplicated(let folded):
      // The request it duplicates now holds the demand, so that is the one worth opening.
      return folded.duplicateOfRequestID
    case .statusChanged, .commentAdded, .none:
      return notification.requestID
    }
  }

  /// News this SDK version does not know still says something happened, rather than rendering an
  /// empty row: the request title underneath is what the reader recognizes anyway.
  ///
  /// In the phone's language, saying in English what the contract's `NotificationHeadline` labels
  /// say, which is also what the server's push alert says.
  private func headline(_ notification: DRNotification) -> String {
    switch notification.news {
    case .statusChanged(let moved):
      return moved.newStatus.movedHeadline
    case .commentAdded:
      return String(localized: "New comment", bundle: .module, comment: "Inbox headline: someone commented on a followed request")
    case .requestDuplicated:
      return String(localized: "Already asked for", bundle: .module, comment: "Inbox headline: the request was merged into another")
    case .none:
      return String(localized: "Something changed", bundle: .module, comment: "Inbox headline for news this version can't name")
    }
  }
}
