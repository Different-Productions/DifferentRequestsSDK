import SwiftUI

/// The Mac's comment field and Send under a request's comments, as Messages and Notes keep theirs at
/// the bottom of the window. Nothing with nobody signed in, since commenting acts for a person.
struct CommentBar: View {

  /// What says whether somebody is signed in.
  let hub: DifferentRequestsHub

  /// The request's own store, which holds the draft and posts it.
  let store: RequestDetailStore

  var body: some View {
    if hub.whoIsHere.somebodyIsHere() {
      VStack(spacing: 0) {
        Divider()
        RequestComposerBar(store: store)
          .padding(Spacing.small.points())
      }
    }
  }
}
