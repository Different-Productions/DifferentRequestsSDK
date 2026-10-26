import SwiftUI

/// A request's demand where it cannot be voted on: the same triangle and count as ``VoteControl``,
/// with no tile behind them, so it lines up with the tile and does not read as a button.
struct VoteTally: View {

  /// How much demand the request has, as the server counts it.
  let voteCount: Int

  /// Whether the caller's own vote is among them. Always false with nobody signed in.
  let voted: Bool

  var body: some View {
    VoteMark(voteCount: voteCount, voted: voted)
      .foregroundStyle(ColorRole.label)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(Text("\(voteCount) votes", bundle: .module, comment: "VoiceOver count of a request's votes"))
      .accessibilityValue(
        voted
          ? Text("Including yours", bundle: .module, comment: "VoiceOver note that the count includes the reader's own vote")
          : Text(verbatim: "")
      )
  }
}
