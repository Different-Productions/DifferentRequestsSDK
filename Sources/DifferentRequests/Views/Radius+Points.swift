import CoreGraphics

extension Radius {

  /// The corner this names, in points.
  func points() -> CGFloat {
    switch self {
    case .inner:
      return 12
    case .macControl:
      return 7
    case .unspecified, .UNRECOGNIZED:
      return 0
    }
  }
}
