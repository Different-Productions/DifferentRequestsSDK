import DifferentRequestsProtos
import SwiftUI

/// One update in the inbox, and the whole row opens its request: the unread dot, what happened, and
/// under it the request's title and how long ago.
///
/// Unread is told three ways, never by color alone: the dot, a heavier headline, and "Unread" to
/// VoiceOver. Opening the request reads the update; so does the row's swipe action.
struct InboxRow: View {

  /// What a push from this row is built against, and what holds the inbox the row marks read.
  let hub: DifferentRequestsHub

  let notification: DRNotification

  var body: some View {
    NavigationLink {
      RequestDetailView(hub: hub, requestID: notification.destinationID)
        .task {
          if notification.hasReadAt == false {
            await hub.inbox.markRead(notificationID: notification.id)
          }
        }
    } label: {
      HStack(alignment: .firstTextBaseline, spacing: Spacing.xSmall.rawValue) {
        UnreadDot(isUnread: notification.hasReadAt == false)

        VStack(alignment: .leading, spacing: Spacing.xxSmall.rawValue) {
          Text(notification.headline)
            .textRole(notification.hasReadAt ? .reading : .rowTitle)
            .foregroundStyle(ColorRole.label)

          InboxRowFacts(notification: notification)
        }
      }
    }
    .accessibilityValue(
      notification.hasReadAt
        ? Text(verbatim: "")
        : Text("Unread", bundle: .module, comment: "VoiceOver value on an inbox update that has not been read")
    )
    .swipeActions(edge: .trailing) {
      if notification.hasReadAt == false {
        AsyncButton {
          await hub.inbox.markRead(notificationID: notification.id)
        } label: {
          Label {
            Text("Mark as read", bundle: .module, comment: "Swipe action that marks one inbox update read")
          } icon: {
            Image(systemName: "envelope.open")
          }
        }
        .tint(Color.accentColor)
      }
    }
  }
}
