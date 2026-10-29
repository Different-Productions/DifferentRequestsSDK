import DifferentRequestsProtos
import SwiftUI

/// A request that was read: the request and what can be done to it on one card, the notification
/// card when it is offered, the comments, and the comment field as a bar the comments scroll under.
struct RequestLoaded: View {

  /// What holds who is signed in and the notification card.
  let hub: DifferentRequestsHub

  /// The request's own store.
  let store: RequestDetailStore

  let request: DRFeatureRequest

  var body: some View {
    List {
      Section {
        VStack(alignment: .leading, spacing: Spacing.small.points()) {
          RequestHeader(request: request)
          RequestStateNote(hub: hub, request: request)
        }
        RequestActions(hub: hub, store: store, request: request)
      }

      if hub.notificationOffer.isOffered(on: request.id) {
        Section {
          NotificationOfferCard(offer: hub.notificationOffer)
        }
      }

      Section {
        RequestThread(store: store)
      } header: {
        Text("Comments", bundle: .module, comment: "Header over a request's comments")
          .textRole(.rowTitle)
          .foregroundStyle(ColorRole.label)
          .textCase(nil)
      }
    }
    .groupedList()
    .scrollDismissesKeyboard(.interactively)
    .refreshable {
      await store.load()
    }
    #if os(macOS)
    .bottomRow(CommentBar(hub: hub, store: store))
    #else
    .safeAreaBar(edge: .bottom) {
      // Commenting acts for a person, so with nobody signed in there is no bar at all.
      if hub.whoIsHere.somebodyIsHere() {
        RequestComposerBar(store: store)
          .padding(.horizontal, Spacing.medium.points())
          .padding(.vertical, Spacing.xSmall.points())
      }
    }
    #endif
  }
}
