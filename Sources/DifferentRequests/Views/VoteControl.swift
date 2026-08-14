import SwiftUI

/// A request's demand, and the caller's own vote in it.
///
/// One control for both directions: the count is what the board measures, and whether it includes
/// your vote is the whole difference between a form and a room — so the button has to already
/// look pressed.
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

  private static let width: CGFloat = 44
  private static let spacing: CGFloat = 2

  /// How much demand the request has, as the server counts it.
  public let voteCount: Int

  /// Whether the caller's own vote is among them.
  public let voted: Bool

  /// Whether a write is already running on the surface this sits on.
  ///
  /// A surface writes one vote at a time, so a control tapped during someone else's round trip is
  /// refused before it reaches the network. Stated here rather than left to the store, because a
  /// refusal the store makes silently is a tap that does nothing and says nothing — which is the
  /// thing this control is on screen to avoid.
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
      VStack(spacing: Self.spacing) {
        Image(systemName: voted ? "chevron.up.circle.fill" : "chevron.up.circle")
          .font(.title3)
        Text(voteCount.formatted())
          .font(.subheadline)
          .fontWeight(.semibold)
          .monospacedDigit()
      }
      .frame(width: Self.width)
      .foregroundStyle(tint)
    }
    .buttonStyle(.plain)
    .disabled(isWriting)
    .accessibilityLabel(voted ? "Remove your vote" : "Vote for this")
    .accessibilityValue("\(voteCount) votes")
  }

  /// `.buttonStyle(.plain)` renders its own label, so a disabled plain button looks exactly like
  /// an enabled one. The dim is stated here instead, or the inert control would be inert in
  /// secret.
  private var tint: AnyShapeStyle {
    if isWriting {
      return AnyShapeStyle(HierarchicalShapeStyle.tertiary)
    }
    if voted {
      return AnyShapeStyle(Color.accentColor)
    }
    return AnyShapeStyle(Color.secondary)
  }
}
