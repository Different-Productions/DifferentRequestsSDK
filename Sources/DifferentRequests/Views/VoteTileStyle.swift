import SwiftUI

/// The vote tile: filled with the tint once voted, filled gray until then, dimmed while pressed.
///
/// On macOS it is drawn as a bordered push button with the Mac's control corner.
struct VoteTileStyle: ButtonStyle {

  /// The tile drawn, which is filled with the tint once the caller's own vote is in its count.
  let tile: VoteTile

  func makeBody(configuration: Configuration) -> some View {
    #if os(macOS)
    configuration.label
      .foregroundStyle(tile.voted ? ColorRole.onTint : ColorRole.label)
      .background(
        tile.voted ? ColorRole.tint : ColorRole.fill,
        in: RoundedRectangle(cornerRadius: Radius.macControl.points())
      )
      .overlay {
        RoundedRectangle(cornerRadius: Radius.macControl.points())
          .strokeBorder(.separator)
      }
      .contentShape(RoundedRectangle(cornerRadius: Radius.macControl.points()))
      .opacity(configuration.isPressed ? PressedLook.pressed.opacity() : PressedLook.atRest.opacity())
    #else
    configuration.label
      .foregroundStyle(tile.voted ? ColorRole.onTint : ColorRole.label)
      .background(
        tile.voted ? ColorRole.tint : ColorRole.fill,
        in: RoundedRectangle(cornerRadius: Radius.inner.points())
      )
      .contentShape(RoundedRectangle(cornerRadius: Radius.inner.points()))
      .opacity(configuration.isPressed ? PressedLook.pressed.opacity() : PressedLook.atRest.opacity())
    #endif
  }
}
