import SwiftUI

/// A request's demand, and the caller's own vote in it, as one tile.
///
/// Voted, the tile is filled with the tint and its triangle is solid. Not voted, it is filled gray
/// with an outline triangle. Its width and height are minimums, so it grows with larger text.
///
/// ```swift
/// VoteControl(tile: VoteTile(request: request, writing: store.write.isWriting())) {
///   await store.toggleVote(requestID: request.id)
/// }
/// ```
public struct VoteControl: View {

  /// The count, whether the caller's vote is among it, and whether a write is already running on
  /// the surface this sits on. The tile takes no tap while one is.
  public let tile: VoteTile

  /// Adds the caller's vote, or takes it back.
  public let toggle: () async -> Void

  /// - Parameters:
  ///   - tile: The count, the caller's vote, and whether a write is already running.
  ///   - toggle: Adds the caller's vote, or takes it back.
  public init(tile: VoteTile, toggle: @escaping () async -> Void) {
    self.tile = tile
    self.toggle = toggle
  }

  public var body: some View {
    AsyncButton {
      await toggle()
    } label: {
      VoteMark(tile: tile)
    }
    .buttonStyle(VoteTileStyle(tile: tile))
    .disabled(tile.writing)
    .accessibilityLabel(
      tile.voted
        ? Text("Remove your vote", bundle: .module, comment: "VoiceOver label for the vote button once the reader has voted")
        : Text("Vote for this", bundle: .module, comment: "VoiceOver label for the vote button")
    )
    .accessibilityValue(Text("\(Int(tile.voteCount)) votes", bundle: .module, comment: "VoiceOver count of a request's votes"))
  }
}
