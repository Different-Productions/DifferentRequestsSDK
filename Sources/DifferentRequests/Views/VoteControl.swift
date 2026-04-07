import SwiftUI

/// A vertical vote control with up arrow, score, and down arrow.
///
/// Updates the displayed score immediately from the callback result.
///
/// ```swift
/// VoteControl(score: request.score) { value in
///   return await model.vote(requestId: id, value: value)
/// }
/// ```
public struct VoteControl: View {

  private let initialScore: Int
  private let onVote: (VoteValue) async -> Int?

  @State private var displayScore: Int

  /// Creates a vote control.
  /// - Parameters:
  ///   - score: The current score.
  ///   - onVote: Async callback that returns the updated score, or nil on failure.
  public init(score: Int, onVote: @escaping (VoteValue) async -> Int?) {
    self.initialScore = score
    self.onVote = onVote
    self._displayScore = State(initialValue: score)
  }

  public var body: some View {
    VStack(spacing: 2) {
      Button {
        vote(.upvote)
      } label: {
        Image(systemName: "chevron.up")
          .fontWeight(.semibold)
          .frame(width: 32, height: 32)
      }
      .buttonStyle(.plain)
      .foregroundStyle(displayScore > 0 ? .green : .secondary)

      Text("\(displayScore)")
        .font(.subheadline)
        .fontWeight(.bold)
        .monospacedDigit()

      Button {
        vote(.downvote)
      } label: {
        Image(systemName: "chevron.down")
          .fontWeight(.semibold)
          .frame(width: 32, height: 32)
      }
      .buttonStyle(.plain)
      .foregroundStyle(displayScore < 0 ? .red : .secondary)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Score: \(displayScore)")
    .accessibilityAdjustableAction { direction in
      switch direction {
      case .increment:
        vote(.upvote)
      case .decrement:
        vote(.downvote)
      @unknown default:
        break
      }
    }
    .onChange(of: initialScore) { _, newValue in
      displayScore = newValue
    }
  }

  private func vote(_ value: VoteValue) {
    Task {
      if let newScore = await onVote(value) {
        displayScore = newScore
      }
    }
  }
}

// MARK: - Preview

#Preview("Vote Control") {
  HStack(spacing: 40) {
    VoteControl(score: 42, onVote: { _ in 43 })
    VoteControl(score: 0, onVote: { _ in 1 })
    VoteControl(score: -3, onVote: { _ in -2 })
  }
  .padding()
}
