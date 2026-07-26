import SwiftUI

/// A request's demand, and the caller's own vote in it.
///
/// One control for both directions: the count is what the board measures, and whether it includes
/// your vote is the whole difference between a form and a room — so the button has to already
/// look pressed.
///
/// ```swift
/// VoteControl(voteCount: Int(request.voteCount), voted: request.viewer.voted) {
///   await store.toggleVote(requestID: request.id)
/// }
/// ```
public struct VoteControl: View {

  private static let width: CGFloat = 44
  private static let spacing: CGFloat = 2

  /// How much demand the request has, as the server counts it.
  public let voteCount: Int

  /// Whether the caller's own vote is among them.
  public let voted: Bool

  /// Adds the caller's vote, or takes it back.
  public let toggle: () async -> Void

  /// - Parameters:
  ///   - voteCount: How much demand the request has.
  ///   - voted: Whether the caller's own vote is among them.
  ///   - toggle: Adds the caller's vote, or takes it back.
  public init(voteCount: Int, voted: Bool, toggle: @escaping () async -> Void) {
    self.voteCount = voteCount
    self.voted = voted
    self.toggle = toggle
  }

  public var body: some View {
    AsyncButton {
      await toggle()
    } label: {
      VStack(spacing: Self.spacing) {
        Image(systemName: voted ? "chevron.up.circle.fill" : "chevron.up.circle")
          .font(.title3)
        Text(voteCount.formatted())
          .font(.subheadline)
          .fontWeight(.semibold)
          .monospacedDigit()
      }
      .frame(width: Self.width)
      .foregroundStyle(voted ? Color.accentColor : Color.secondary)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(voted ? "Remove your vote" : "Vote for this")
    .accessibilityValue("\(voteCount) votes")
  }
}
