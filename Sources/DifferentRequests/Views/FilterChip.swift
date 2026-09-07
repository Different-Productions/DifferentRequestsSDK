import SwiftUI

/// One narrowing on the board's filter bar: a word, whether it is on, and the read that turning it
/// on or off costs.
///
/// A capsule rather than a `Picker` for two reasons. The statuses are a set and not a choice —
/// several are on at once — and a `Picker`'s selection is a binding whose setter would have to
/// carry the re-read, putting dispatch in a view instead of on the store where it belongs.
///
/// An ``AsyncButton``, because setting the filter and reading the board again is one suspending
/// call. That makes it inert for the length of that read, which is why the label states its own
/// selected state rather than leaning on the button style: the tap flips ``isActive`` before the
/// read starts, so the chip has already moved by the time it goes inert and is never inert in
/// secret. `.buttonStyle(.plain)` renders its own label and would otherwise draw a disabled chip
/// exactly like an enabled one.
struct FilterChip: View {

  private static let horizontalPadding: CGFloat = 12
  private static let verticalPadding: CGFloat = 6

  /// What the chip says.
  let label: String

  /// What it is called to someone who cannot see it. "Top" and "New" are a ranking beside each
  /// other and a guess on their own.
  let spokenLabel: String

  /// Whether this narrowing is on.
  let isActive: Bool

  /// Turns it on, or off, and reads the board again.
  let apply: () async -> Void

  var body: some View {
    AsyncButton {
      await apply()
    } label: {
      Text(label)
        .font(.caption)
        .fontWeight(isActive ? .semibold : .regular)
        .padding(.horizontal, Self.horizontalPadding)
        .padding(.vertical, Self.verticalPadding)
        .foregroundStyle(foreground)
        .background(fill, in: Capsule())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(spokenLabel)
    .accessibilityAddTraits(isActive ? [.isButton, .isSelected] : [.isButton])
  }

  /// Filled when on, tinted when off — the pattern every native filter strip uses, and the only
  /// one that survives a palette with no colour in it. A tinted-on state reads as off beside a
  /// tinted-off state.
  private var foreground: AnyShapeStyle {
    if isActive {
      return AnyShapeStyle(BackgroundStyle.background)
    }
    return AnyShapeStyle(HierarchicalShapeStyle.primary)
  }

  private var fill: AnyShapeStyle {
    if isActive {
      return AnyShapeStyle(HierarchicalShapeStyle.primary)
    }
    return AnyShapeStyle(HierarchicalShapeStyle.quaternary)
  }
}
