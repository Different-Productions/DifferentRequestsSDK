import SwiftUI

/// An up triangle over a request's vote count: solid when the caller's vote is among them, an
/// outline when it is not.
struct VoteMark: View {

  /// The count, and whether the caller's own vote is among it.
  let tile: VoteTile

  var body: some View {
    #if os(macOS)
    VStack(spacing: 0) {
      Image(systemName: "arrowtriangle.up")
        .symbolVariant(tile.voted ? .fill : .none)
      Text(tile.voteCount.formatted())
        .monospacedDigit()
    }
    .textRole(.supporting)
    .fontWeight(.semibold)
    .padding(Spacing.xxSmall.points())
    .frame(minWidth: VoteTileSize.side.points(), minHeight: VoteTileSize.side.points())
    #else
    VStack(spacing: Spacing.xxSmall.points()) {
      Image(systemName: "arrowtriangle.up")
        .symbolVariant(tile.voted ? .fill : .none)
      Text(tile.voteCount.formatted())
        .monospacedDigit()
    }
    .textRole(.supporting)
    .fontWeight(.semibold)
    .padding(.vertical, Spacing.xSmall.points())
    .padding(.horizontal, Spacing.xxSmall.points())
    .frame(minWidth: VoteTileSize.width.points(), minHeight: VoteTileSize.height.points())
    #endif
  }
}
