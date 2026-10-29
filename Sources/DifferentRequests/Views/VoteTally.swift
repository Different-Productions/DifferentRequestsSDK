import SwiftUI

/// A request's demand where it cannot be voted on: the same triangle and count as ``VoteControl``,
/// with no tile behind them, so it lines up with the tile and does not read as a button.
struct VoteTally: View {

  /// The count, and whether the caller's own vote is among it. Never voted with nobody signed in.
  let tile: VoteTile

  var body: some View {
    VoteMark(tile: tile)
      .foregroundStyle(ColorRole.label)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(Text("\(Int(tile.voteCount)) votes", bundle: .module, comment: "VoiceOver count of a request's votes"))
      .accessibilityValue(
        tile.voted
          ? Text("Including yours", bundle: .module, comment: "VoiceOver note that the count includes the reader's own vote")
          : Text(verbatim: "")
      )
  }
}
