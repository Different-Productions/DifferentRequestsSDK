import DifferentRequestsProtos
import SwiftUI

/// The vote on a request's own screen: a triangle and the count in words, filled with the tint once
/// the caller's vote is among them.
struct VoteButton: View {

  /// The request's own store, which writes the vote.
  let store: RequestDetailStore

  let request: DRFeatureRequest

  var body: some View {
    AsyncButton {
      await store.toggleVote()
    } label: {
      HStack(spacing: Spacing.xSmall.rawValue) {
        Image(systemName: "arrowtriangle.up")
          .symbolVariant(request.viewer.voted ? .fill : .none)
        Text("\(Int(request.voteCount)) votes", bundle: .module, comment: "VoiceOver count of a request's votes")
          .monospacedDigit()
      }
    }
    .buttonStyle(PillButtonStyle(isFilled: request.viewer.voted))
    .disabled(store.write.isWriting)
    .accessibilityHint(
      request.viewer.voted
        ? Text("Remove your vote", bundle: .module, comment: "VoiceOver label for the vote button once the reader has voted")
        : Text("Vote for this", bundle: .module, comment: "VoiceOver label for the vote button")
    )
  }
}
