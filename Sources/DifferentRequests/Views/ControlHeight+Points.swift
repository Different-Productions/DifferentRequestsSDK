import CoreGraphics

extension ControlHeight {

  /// The least height this names, in points.
  func points() -> CGFloat {
    switch self {
    case .large:
      return 50
    case .macPush:
      return 28
    case .unspecified, .UNRECOGNIZED:
      return 0
    }
  }
}
