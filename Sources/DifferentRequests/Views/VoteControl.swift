import SwiftUI

/// A vertical vote control with up arrow, score, and down arrow.
///
/// Highlights the active vote direction and handles toggling.
///
/// ```swift
/// VoteControl(score: 42, myVote: 1, onVote: { value in
///   await model.vote(requestId: id, value: value)
/// })
/// ```
public struct VoteControl: View {

  /// The current score to display.
  public let score: Int

  /// The current user's own vote (1, -1), or `nil` if they haven't voted.
  public let myVote: Int?

  /// Callback when the user taps a vote button.
  public let onVote: (VoteValue) async -> Void

  /// Whether the control is disabled (e.g., while a vote is in flight).
  @State private var isDisabled = false

  /// Creates a vote control.
  /// - Parameters:
  ///   - score: The current score.
  ///   - myVote: The current user's own vote (1, -1) or nil.
  ///   - onVote: Async callback with the vote direction.
  public init(score: Int, myVote: Int?, onVote: @escaping (VoteValue) async -> Void) {
    self.score = score
    self.myVote = myVote
    self.onVote = onVote
  }

  public var body: some View {
    VStack(spacing: 2) {
      Button {
        Task { await handleTap(.upvote) }
      } label: {
        Image(systemName: "chevron.up")
          .fontWeight(.semibold)
          .frame(width: 32, height: 32)
      }
      .buttonStyle(.plain)
      .foregroundStyle(myVote == 1 ? .green : .secondary)

      Text("\(score)")
        .font(.subheadline)
        .fontWeight(.bold)
        .monospacedDigit()

      Button {
        Task { await handleTap(.downvote) }
      } label: {
        Image(systemName: "chevron.down")
          .fontWeight(.semibold)
          .frame(width: 32, height: 32)
      }
      .buttonStyle(.plain)
      .foregroundStyle(myVote == -1 ? .red : .secondary)
    }
    .disabled(isDisabled)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Score: \(score)")
    .accessibilityAdjustableAction { direction in
      switch direction {
      case .increment:
        Task { await handleTap(.upvote) }
      case .decrement:
        Task { await handleTap(.downvote) }
      @unknown default:
        break
      }
    }
  }

  /// Resolves the vote to send when the user taps `direction`. Tapping the
  /// direction the user has already voted toggles that vote off (`.remove`);
  /// any other tap sets the tapped direction. `currentVote` is the raw
  /// `myVote` value (``VoteValue/upvote`` or ``VoteValue/downvote`` raw value,
  /// or `nil` when the user has not voted).
  ///
  /// - Parameters:
  ///   - currentVote: The user's current vote as a raw score contribution.
  ///   - direction: The direction the user tapped (`.upvote` or `.downvote`).
  static func voteValue(currentVote: Int?, tapping direction: VoteValue) -> VoteValue {
    if currentVote == direction.rawValue {
      return .remove
    }
    return direction
  }

  private func handleTap(_ direction: VoteValue) async {
    await handleVote(VoteControl.voteValue(currentVote: myVote, tapping: direction))
  }

  private func handleVote(_ value: VoteValue) async {
    isDisabled = true
    await onVote(value)
    isDisabled = false
  }
}

// MARK: - Preview

#Preview("Vote Control") {
  HStack(spacing: 40) {
    VoteControl(score: 42, myVote: 1, onVote: { _ in })
    VoteControl(score: 0, myVote: nil, onVote: { _ in })
    VoteControl(score: -3, myVote: -1, onVote: { _ in })
  }
  .padding()
}
