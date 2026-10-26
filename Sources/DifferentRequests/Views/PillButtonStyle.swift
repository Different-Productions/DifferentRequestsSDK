import SwiftUI

/// A full-width capsule button at the large control height: filled with the tint for the choice in
/// effect or the main action, filled gray otherwise, dimmed while pressed or unavailable.
struct PillButtonStyle: ButtonStyle {

  /// Whether the capsule is filled with the tint.
  let isFilled: Bool

  @Environment(\.isEnabled) private var isEnabled

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .textRole(.rowTitle)
      .foregroundStyle(isFilled ? ColorRole.onTint : ColorRole.label)
      .padding(.horizontal, Spacing.medium.rawValue)
      .frame(maxWidth: .infinity, minHeight: ControlHeight.large.rawValue)
      .background(isFilled ? ColorRole.tint : ColorRole.fill, in: Capsule())
      .contentShape(Capsule())
      .opacity(configuration.isPressed || isEnabled == false ? PressedLook.pressed.rawValue : PressedLook.atRest.rawValue)
  }
}
