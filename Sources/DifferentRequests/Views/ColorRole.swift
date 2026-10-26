import SwiftUI

/// What a color is for. Each role is a system color that adapts to light, dark and increased
/// contrast, except the tint, which is the host app's own.
///
/// The screen background, the card behind rows and the lines between rows are drawn by the system's
/// grouped list, so they have no role here.
enum ColorRole: ShapeStyle {

  /// Titles, status, counts, comments.
  case label

  /// Supporting lines and ages.
  case secondaryLabel

  /// Behind a gray button and a vote tile that is not voted.
  case fill

  /// The host app's color: the main action, your own vote, unread.
  case tint

  /// A label drawn on the tint: white where white measures 4.5 to 1 against it, and black where it
  /// does not.
  case onTint

  /// Something failed.
  case failure

  func resolve(in environment: EnvironmentValues) -> AnyShapeStyle {
    switch self {
    case .label:
      return AnyShapeStyle(Color.primary)
    case .secondaryLabel:
      return AnyShapeStyle(Color.secondary)
    case .fill:
      return AnyShapeStyle(FillShapeStyle().tertiary)
    case .tint:
      return AnyShapeStyle(TintShapeStyle())
    case .onTint:
      return labelOnTint(in: environment)
    case .failure:
      return AnyShapeStyle(Color.red)
    }
  }

  /// White, or black when the tint is too light for white to measure 4.5 to 1 against it.
  private func labelOnTint(in environment: EnvironmentValues) -> AnyShapeStyle {
    let tint = Color.accentColor.resolve(in: environment)
    let luminance = LuminanceWeight.red.rawValue * tint.linearRed
      + LuminanceWeight.green.rawValue * tint.linearGreen
      + LuminanceWeight.blue.rawValue * tint.linearBlue
    if luminance > LuminanceWeight.blackContrastThreshold.rawValue {
      return AnyShapeStyle(Color.black)
    }
    return AnyShapeStyle(Color.white)
  }
}
