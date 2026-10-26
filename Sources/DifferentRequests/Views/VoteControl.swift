import SwiftUI

/// A request's demand, and the caller's own vote in it, as one tile.
///
/// Voted, the tile is filled with the tint and its triangle is solid. Not voted, it is filled gray
/// with an outline triangle. Its width and height are minimums, so it grows with larger text.
///
/// ```swift
/// VoteControl(
///   voteCount: Int(request.voteCount),
///   voted: request.viewer.voted,
///   isWriting: store.write.isWriting
/// ) {
///   await store.toggleVote(requestID: request.id)
/// }
/// ```
public struct VoteControl: View {

  /// How much demand the request has, as the server counts it.
  public let voteCount: Int

  /// Whether the caller's own vote is among them.
  public let voted: Bool

  /// Whether a write is already running on the surface this sits on. The tile takes no tap while
  /// one is.
  public let isWriting: Bool

  /// Adds the caller's vote, or takes it back.
  public let toggle: () async -> Void

  /// - Parameters:
  ///   - voteCount: How much demand the request has.
  ///   - voted: Whether the caller's own vote is among them.
  ///   - isWriting: Whether a write is already running on this surface.
  ///   - toggle: Adds the caller's vote, or takes it back.
  public init(
    voteCount: Int,
    voted: Bool,
    isWriting: Bool,
    toggle: @escaping () async -> Void
  ) {
    self.voteCount = voteCount
    self.voted = voted
    self.isWriting = isWriting
    self.toggle = toggle
  }

  public var body: some View {
    AsyncButton {
      await toggle()
    } label: {
      VoteMark(voteCount: voteCount, voted: voted)
    }
    .buttonStyle(VoteTileStyle(voted: voted))
    .disabled(isWriting)
    .accessibilityLabel(
      voted
        ? Text("Remove your vote", bundle: .module, comment: "VoiceOver label for the vote button once the reader has voted")
        : Text("Vote for this", bundle: .module, comment: "VoiceOver label for the vote button")
    )
    .accessibilityValue(Text("\(voteCount) votes", bundle: .module, comment: "VoiceOver count of a request's votes"))
  }
}
