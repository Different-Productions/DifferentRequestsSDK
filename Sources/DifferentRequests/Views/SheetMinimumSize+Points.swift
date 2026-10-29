import CoreGraphics

extension SheetMinimumSize {

  /// The least size this names, in points.
  func points() -> CGFloat {
    switch self {
    case .width:
      return 520
    case .height:
      return 600
    case .unspecified, .UNRECOGNIZED:
      return 0
    }
  }
}
