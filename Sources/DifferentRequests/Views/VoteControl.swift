import SwiftUI
import os

private let logger = Logger(subsystem: "com.different.requests", category: "VoteControl")

/// A vertical vote control with up arrow, score, and down arrow.
///
/// Highlights the active vote direction and handles toggling.
///
/// ```swift
/// VoteControl(score: 42, onVote: { value in
///   await model.vote(requestId: id, value: value)
/// })
/// ```
public struct VoteControl: View {

  /// The current score to display.
  public let score: Int

  /// Callback when the user taps a vote button.
  public let onVote: (VoteValue) async -> Void

  /// Whether the control is disabled (e.g., while a vote is in flight).
  @State private var isDisabled = false

  /// Creates a vote control.
  /// - Parameters:
  ///   - score: The current score.
  ///   - onVote: Async callback with the vote direction.
  public init(score: Int, onVote: @escaping (VoteValue) async -> Void) {
    self.score = score
    self.onVote = onVote
  }

  public var body: some View {
    VStack(spacing: 2) {
      Button {
        Task { await handleVote(.upvote) }
      } label: {
        Image(systemName: "chevron.up")
          .fontWeight(.semibold)
          .frame(width: 32, height: 32)
      }
      .buttonStyle(.plain)
      .foregroundStyle(score > 0 ? .green : .secondary)

      Text("\(score)")
        .font(.subheadline)
        .fontWeight(.bold)
        .monospacedDigit()

      Button {
        Task { await handleVote(.downvote) }
      } label: {
        Image(systemName: "chevron.down")
          .fontWeight(.semibold)
          .frame(width: 32, height: 32)
      }
      .buttonStyle(.plain)
      .foregroundStyle(score < 0 ? .red : .secondary)
    }
    .disabled(isDisabled)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Score: \(score)")
    .accessibilityAdjustableAction { direction in
      switch direction {
      case .increment:
        Task { await handleVote(.upvote) }
      case .decrement:
        Task { await handleVote(.downvote) }
      @unknown default:
        break
      }
    }
  }

  private func handleVote(_ value: VoteValue) async {
    logger.debug("handleVote called: value=\(String(describing: value)), isDisabled=\(isDisabled)")
    isDisabled = true
    await onVote(value)
    logger.debug("handleVote completed: value=\(String(describing: value))")
    isDisabled = false
  }
}

// MARK: - Preview

#Preview("Vote Control") {
  HStack(spacing: 40) {
    VoteControl(score: 42, onVote: { _ in })
    VoteControl(score: 0, onVote: { _ in })
    VoteControl(score: -3, onVote: { _ in })
  }
  .padding()
}
