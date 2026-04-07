import SwiftUI

/// A vertical vote control with up arrow, score, and down arrow.
public struct VoteControl: View {

  /// The score to display.
  public let score: Int

  /// Called when the user taps upvote.
  public let onUpvote: () -> Void

  /// Called when the user taps downvote.
  public let onDownvote: () -> Void

  public init(score: Int, onUpvote: @escaping () -> Void, onDownvote: @escaping () -> Void) {
    self.score = score
    self.onUpvote = onUpvote
    self.onDownvote = onDownvote
  }

  public var body: some View {
    VStack(spacing: 2) {
      Button("Upvote", systemImage: "chevron.up", action: onUpvote)
        .labelStyle(.iconOnly)
        .fontWeight(.semibold)
        .frame(width: 32, height: 32)
        .foregroundStyle(score > 0 ? .green : .secondary)

      Text("\(score)")
        .font(.subheadline)
        .fontWeight(.bold)
        .monospacedDigit()

      Button("Downvote", systemImage: "chevron.down", action: onDownvote)
        .labelStyle(.iconOnly)
        .fontWeight(.semibold)
        .frame(width: 32, height: 32)
        .foregroundStyle(score < 0 ? .red : .secondary)
    }
    .buttonStyle(.borderless)
  }
}
