import CoreGraphics

extension Spacing {

  /// The gap this names, in points.
  func points() -> CGFloat {
    switch self {
    case .xxSmall:
      return 4
    case .xSmall:
      return 8
    case .small:
      return 12
    case .medium:
      return 16
    case .large:
      return 20
    case .xLarge:
      return 24
    case .xxLarge:
      return 32
    case .unspecified, .UNRECOGNIZED:
      return 0
    }
  }
}
