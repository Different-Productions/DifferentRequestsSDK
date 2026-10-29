import SwiftUI

/// The comment field's Send circle, 44 by 44: filled with the tint when there is something to send,
/// filled gray when there is not.
struct SendButtonStyle: ButtonStyle {

  @Environment(\.isEnabled) private var isEnabled

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .textRole(.rowTitle)
      .foregroundStyle(isEnabled ? ColorRole.onTint : ColorRole.secondaryLabel)
      .frame(width: TargetSize.minimum.points(), height: TargetSize.minimum.points())
      .background(isEnabled ? ColorRole.tint : ColorRole.fill, in: Circle())
      .contentShape(Circle())
      .opacity(configuration.isPressed ? PressedLook.pressed.opacity() : PressedLook.atRest.opacity())
  }
}
