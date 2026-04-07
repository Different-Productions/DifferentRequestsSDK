import SwiftUI

/// A vertical vote control with up arrow, score, and down arrow.
public struct VoteControl: View {

  /// The score to display.
  public let score: Int

  /// Called when the user taps a vote button. Returns the updated score.
  public let onVote: (VoteValue) async -> Int?

  public init(score: Int, onVote: @escaping (VoteValue) async -> Int?) {
    self.score = score
    self.onVote = onVote
  }

  public var body: some View {
    VStack(spacing: 2) {
      Button("Upvote", systemImage: "chevron.up", action: upvote)
        .labelStyle(.iconOnly)
        .fontWeight(.semibold)
        .frame(width: 32, height: 32)
        .foregroundStyle(score > 0 ? .green : .secondary)

      Text("\(score)")
        .font(.subheadline)
        .fontWeight(.bold)
        .monospacedDigit()

      Button("Downvote", systemImage: "chevron.down", action: downvote)
        .labelStyle(.iconOnly)
        .fontWeight(.semibold)
        .frame(width: 32, height: 32)
        .foregroundStyle(score < 0 ? .red : .secondary)
    }
    .buttonStyle(.borderless)
  }

  private func upvote() {
    Task { await onVote(.upvote) }
  }

  private func downvote() {
    Task { await onVote(.downvote) }
  }
}
