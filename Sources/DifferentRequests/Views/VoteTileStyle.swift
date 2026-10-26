import SwiftUI

/// The vote tile: filled with the tint once voted, filled gray until then, dimmed while pressed.
struct VoteTileStyle: ButtonStyle {

  /// Whether the caller's own vote is in the count the tile shows.
  let voted: Bool

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundStyle(voted ? ColorRole.onTint : ColorRole.label)
      .background(
        voted ? ColorRole.tint : ColorRole.fill,
        in: RoundedRectangle(cornerRadius: Radius.inner.rawValue)
      )
      .contentShape(RoundedRectangle(cornerRadius: Radius.inner.rawValue))
      .opacity(configuration.isPressed ? PressedLook.pressed.rawValue : PressedLook.atRest.rawValue)
  }
}
