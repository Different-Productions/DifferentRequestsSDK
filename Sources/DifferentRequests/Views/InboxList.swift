import SwiftUI

/// The updates the inbox holds, as one grouped list: a failed stamp's notice, the rows, and the row
/// for the next page. It stays up through a refresh, because the list owns the refreshing task.
struct InboxList: View {

  /// What holds the inbox.
  let hub: DifferentRequestsHub

  var body: some View {
    List {
      if let failure = hub.inbox.write.failure() {
        Section {
          WriteFailureNotice(failure: failure) {
            hub.inbox.acknowledgeWriteFailure()
          }
        }
      }

      Section {
        ForEach(hub.inbox.inbox.notifications, id: \.id) { notification in
          InboxRow(hub: hub, notification: notification)
            .listRowPadding()
        }

        if hub.inbox.page.isDone() == false {
          NextPageRow(
            content: NextPageRowContent(
              page: hub.inbox.page,
              failureMessage: String(
                localized: "Couldn't load more updates.",
                bundle: .module,
                comment: "Row at the end of the Inbox list when the next page failed to load"
              )
            )
          ) {
            await hub.inbox.loadMore()
          }
        }
      }
    }
    .groupedList()
    .refreshable {
      await hub.inbox.load()
    }
  }
}
