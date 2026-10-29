import CoreGraphics

extension TargetSize {

  /// The side this names, in points.
  func points() -> CGFloat {
    switch self {
    case .minimum:
      return 44
    case .unspecified, .UNRECOGNIZED:
      return 0
    }
  }
}
