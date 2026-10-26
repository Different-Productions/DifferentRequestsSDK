import DifferentRequestsProtos
import SwiftUI

/// The requests the board holds, as one grouped list: a failed vote's notice, the rows, the row for
/// the next page, and the Powered by row of a free app.
///
/// Reads the rows off the board it is handed, so it stays up through a refresh: a pull-to-refresh
/// runs on the list's own task, and a list that disappears takes that task with it.
struct RequestsList: View {

  /// What holds the board, who is signed in, and what the app's plan includes.
  let hub: DifferentRequestsHub

  var body: some View {
    List {
      if let failure = hub.board.write.failure {
        Section {
          WriteFailureNotice(failure: failure) {
            hub.board.acknowledgeWriteFailure()
          }
        }
      }

      Section {
        ForEach(hub.board.read.held, id: \.id) { request in
          RequestRow(hub: hub, request: request)
            .listRowInsets(
              EdgeInsets(
                top: Spacing.small.rawValue,
                leading: Spacing.medium.rawValue,
                bottom: Spacing.small.rawValue,
                trailing: Spacing.medium.rawValue
              )
            )

          if hub.notificationOffer.isOffered(on: request.id) {
            NotificationOfferCard(offer: hub.notificationOffer)
          }
        }

        if hub.board.page.isDone == false {
          NextPageRow(
            state: hub.board.page,
            failureMessage: String(
              localized: "Couldn't load more requests.",
              bundle: .module,
              comment: "Row at the end of the Requests list when the next page failed to load"
            )
          ) {
            await hub.board.loadMore()
          }
        }
      }

      if hub.appConfig.badge.isCarried {
        Section {
          PoweredByRow(appConfig: hub.appConfig)
            .listRowBackground(Color.clear)
            .listRowInsets(
              EdgeInsets(top: 0, leading: Spacing.medium.rawValue, bottom: 0, trailing: Spacing.medium.rawValue)
            )
        }
      }
    }
    .groupedList()
    // The Powered by row is one line of small text, held to the smallest tap area and no taller.
    .environment(\.defaultMinListRowHeight, TargetSize.minimum.rawValue)
    .refreshable {
      await hub.board.load()
    }
  }
}
