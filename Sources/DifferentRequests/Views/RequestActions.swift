import DifferentRequestsProtos
import SwiftUI

/// What a person can do to a request: Vote and Follow as two buttons of one size, and under them
/// whatever the last write has to say. With nobody signed in, the count in words and no buttons.
struct RequestActions: View {

  /// What holds who is signed in and the one-time note after a first vote.
  let hub: DifferentRequestsHub

  /// The request's own store, which writes the vote and the follow.
  let store: RequestDetailStore

  let request: DRFeatureRequest

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.small.points()) {
      if hub.whoIsHere.somebodyIsHere(), dynamicTypeSize.isAccessibilitySize {
        VoteButton(store: store, request: request)
        FollowButton(store: store, request: request)
      } else if hub.whoIsHere.somebodyIsHere() {
        HStack(spacing: Spacing.small.points()) {
          VoteButton(store: store, request: request)
          FollowButton(store: store, request: request)
        }
      } else {
        Text("\(Int(request.voteCount)) votes", bundle: .module, comment: "VoiceOver count of a request's votes")
          .textRole(.supporting)
          .foregroundStyle(ColorRole.secondaryLabel)
      }

      if hub.firstVoteNote.isSaid(on: request.id) {
        Text(
          "You'll get an update in Inbox when this request changes.",
          bundle: .module,
          comment: "One-time line after a person's first vote on this phone"
        )
        .textRole(.supporting)
        .foregroundStyle(ColorRole.secondaryLabel)
      }

      if let failure = store.write.failure() {
        WriteFailureNotice(failure: failure) {
          store.acknowledgeWriteFailure()
        }
      }
    }
  }
}
