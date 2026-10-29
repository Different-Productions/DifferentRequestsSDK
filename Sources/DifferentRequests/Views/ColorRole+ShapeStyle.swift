import SwiftUI

extension ColorRole: ShapeStyle {

  func resolve(in environment: EnvironmentValues) -> AnyShapeStyle {
    switch self {
    case .label, .unspecified, .UNRECOGNIZED:
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
    let tint = environment.drawnTint.tintColor().resolve(in: environment)
    let luminance = LuminanceWeight.red.weight() * tint.linearRed
      + LuminanceWeight.green.weight() * tint.linearGreen
      + LuminanceWeight.blue.weight() * tint.linearBlue
    if luminance > LuminanceWeight.blackContrastThreshold.weight() {
      return AnyShapeStyle(Color.black)
    }
    return AnyShapeStyle(Color.white)
  }
}
