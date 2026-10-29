import DifferentRequestsProtos
import SwiftUI

/// The vote on a request's own screen, filled with the tint once the caller's vote is among them.
///
/// On iOS the button holds a triangle and the count in words. On macOS it says what it does, Vote or
/// Voted, and the count sits beside it in words, since a push button's label is a verb.
struct VoteButton: View {

  /// The request's own store, which writes the vote.
  let store: RequestDetailStore

  let request: DRFeatureRequest

  var body: some View {
    #if os(macOS)
    HStack(spacing: Spacing.xSmall.points()) {
      AsyncButton {
        await store.toggleVote()
      } label: {
        HStack(spacing: Spacing.xSmall.points()) {
          Image(systemName: "arrowtriangle.up")
            .symbolVariant(request.viewer.voted ? .fill : .none)
          if request.viewer.voted {
            Text("Voted", bundle: .module, comment: "Mac button showing the reader has voted; a click takes the vote back")
          } else {
            Text("Vote", bundle: .module, comment: "Mac button that votes for a request")
          }
        }
      }
      .buttonStyle(PillButtonStyle(fill: PillFill(chosen: request.viewer.voted)))
      .disabled(store.write.isWriting())
      .accessibilityHint(
        request.viewer.voted
          ? Text("Remove your vote", bundle: .module, comment: "VoiceOver label for the vote button once the reader has voted")
          : Text("Vote for this", bundle: .module, comment: "VoiceOver label for the vote button")
      )

      Text("\(Int(request.voteCount)) votes", bundle: .module, comment: "VoiceOver count of a request's votes")
        .monospacedDigit()
        .textRole(.supporting)
        .foregroundStyle(ColorRole.secondaryLabel)
    }
    #else
    AsyncButton {
      await store.toggleVote()
    } label: {
      HStack(spacing: Spacing.xSmall.points()) {
        Image(systemName: "arrowtriangle.up")
          .symbolVariant(request.viewer.voted ? .fill : .none)
        Text("\(Int(request.voteCount)) votes", bundle: .module, comment: "VoiceOver count of a request's votes")
          .monospacedDigit()
      }
    }
    .buttonStyle(PillButtonStyle(fill: PillFill(chosen: request.viewer.voted)))
    .disabled(store.write.isWriting())
    .accessibilityHint(
      request.viewer.voted
        ? Text("Remove your vote", bundle: .module, comment: "VoiceOver label for the vote button once the reader has voted")
        : Text("Vote for this", bundle: .module, comment: "VoiceOver label for the vote button")
    )
    #endif
  }
}
