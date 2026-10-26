import SwiftUI

/// An up triangle over a request's vote count: solid when the caller's vote is among them, an
/// outline when it is not.
struct VoteMark: View {

  /// How much demand the request has, as the server counts it.
  let voteCount: Int

  /// Whether the caller's own vote is among them.
  let voted: Bool

  var body: some View {
    VStack(spacing: Spacing.xxSmall.rawValue) {
      Image(systemName: "arrowtriangle.up")
        .symbolVariant(voted ? .fill : .none)
      Text(voteCount.formatted())
        .monospacedDigit()
    }
    .textRole(.supporting)
    .fontWeight(.semibold)
    .padding(.vertical, Spacing.xSmall.rawValue)
    .padding(.horizontal, Spacing.xxSmall.rawValue)
    .frame(minWidth: VoteTileSize.width.rawValue, minHeight: VoteTileSize.height.rawValue)
  }
}
