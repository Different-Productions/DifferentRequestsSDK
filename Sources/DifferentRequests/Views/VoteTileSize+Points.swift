import CoreGraphics

extension VoteTileSize {

  /// The least size this names, in points.
  func points() -> CGFloat {
    switch self {
    case .side:
      return 36
    case .width:
      return 48
    case .height:
      return 56
    case .unspecified, .UNRECOGNIZED:
      return 0
    }
  }
}
