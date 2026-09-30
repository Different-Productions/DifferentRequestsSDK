import SwiftUI

/// A request's demand where it cannot be voted on — nobody signed in, or the roadmap's summary —
/// drawn exactly like ``VoteControl`` but with nothing to press.
///
/// The width, the circled arrow and the tint match ``VoteControl``'s, so every screen shows the
/// caller's own vote the same way and a list drawn for nobody lines up like one drawn for somebody.
struct VoteTally: View {

  private static let width: CGFloat = 44
  private static let spacing: CGFloat = 2

  /// How much demand the request has, as the server counts it.
  let voteCount: Int

  /// Whether the caller's own vote is among them. Always false with nobody signed in.
  let voted: Bool

  var body: some View {
    VStack(spacing: Self.spacing) {
      Image(systemName: voted ? "chevron.up.circle.fill" : "chevron.up.circle")
        .font(.title3)
      Text(voteCount.formatted())
        .font(.subheadline)
        .fontWeight(.semibold)
        .monospacedDigit()
    }
    .frame(width: Self.width, alignment: .leading)
    .foregroundStyle(tint)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text("\(voteCount) votes", bundle: .module, comment: "VoiceOver count of a request's votes"))
    .accessibilityValue(
      voted
        ? Text("Including yours", bundle: .module, comment: "VoiceOver note that the count includes the reader's own vote")
        : Text(verbatim: "")
    )
  }

  private var tint: AnyShapeStyle {
    if voted {
      return AnyShapeStyle(Color.accentColor)
    }
    return AnyShapeStyle(Color.secondary)
  }
}
