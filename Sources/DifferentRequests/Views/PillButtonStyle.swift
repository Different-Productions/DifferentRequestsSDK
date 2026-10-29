import SwiftUI

/// A full-width capsule button at the large control height: filled with the tint for the choice in
/// effect or the main action, filled gray otherwise, dimmed while pressed or unavailable.
///
/// On macOS it is a push button instead: 28 pt high, as wide as its words, with the Mac's control
/// corner and a border, filled the same way.
struct PillButtonStyle: ButtonStyle {

  /// Whether the button is filled with the tint or gray.
  let fill: PillFill

  @Environment(\.isEnabled) private var isEnabled

  func makeBody(configuration: Configuration) -> some View {
    #if os(macOS)
    configuration.label
      .textRole(.reading)
      .foregroundStyle(fill.labelRole())
      .padding(.horizontal, Spacing.small.points())
      .frame(minHeight: ControlHeight.macPush.points())
      .background(
        fill.backgroundRole(),
        in: RoundedRectangle(cornerRadius: Radius.macControl.points())
      )
      .overlay {
        RoundedRectangle(cornerRadius: Radius.macControl.points())
          .strokeBorder(.separator)
      }
      .contentShape(RoundedRectangle(cornerRadius: Radius.macControl.points()))
      .opacity(configuration.isPressed || isEnabled == false ? PressedLook.pressed.opacity() : PressedLook.atRest.opacity())
    #else
    configuration.label
      .textRole(.rowTitle)
      .foregroundStyle(fill.labelRole())
      .padding(.horizontal, Spacing.medium.points())
      .frame(maxWidth: .infinity, minHeight: ControlHeight.large.points())
      .background(fill.backgroundRole(), in: Capsule())
      .contentShape(Capsule())
      .opacity(configuration.isPressed || isEnabled == false ? PressedLook.pressed.opacity() : PressedLook.atRest.opacity())
    #endif
  }
}
