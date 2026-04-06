import SwiftUI

/// A vertical vote control with up arrow, score, and down arrow.
///
/// Shows a loading indicator while a vote is in flight. The callback
/// returns the updated score so the UI reflects the change immediately.
///
/// ```swift
/// VoteControl(score: request.score) { value in
///   return await model.vote(requestId: id, value: value)
/// }
/// ```
public struct VoteControl: View {

  /// The initial score from the data source.
  private let initialScore: Int

  /// Callback when the user taps a vote button. Returns the new score.
  private let onVote: (VoteValue) async -> Int?

  /// Local score that updates immediately after voting.
  @State private var displayScore: Int
  @State private var isVoting = false

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
        Task { await handleVote(.upvote) }
      } label: {
        Image(systemName: "chevron.up")
          .fontWeight(.semibold)
          .frame(width: 32, height: 32)
      }
      .buttonStyle(.plain)
      .foregroundStyle(displayScore > 0 ? .green : .secondary)

      if isVoting {
        ProgressView()
          .scaleEffect(0.7)
          .frame(height: 20)
      } else {
        Text("\(displayScore)")
          .font(.subheadline)
          .fontWeight(.bold)
          .monospacedDigit()
          .frame(height: 20)
      }

      Button {
        Task { await handleVote(.downvote) }
      } label: {
        Image(systemName: "chevron.down")
          .fontWeight(.semibold)
          .frame(width: 32, height: 32)
      }
      .buttonStyle(.plain)
      .foregroundStyle(displayScore < 0 ? .red : .secondary)
    }
    .disabled(isVoting)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Score: \(displayScore)")
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
    .onChange(of: initialScore) { _, newValue in
      displayScore = newValue
    }
  }

  private func handleVote(_ value: VoteValue) async {
    isVoting = true
    if let newScore = await onVote(value) {
      displayScore = newScore
    }
    isVoting = false
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
