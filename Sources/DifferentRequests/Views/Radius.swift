import CoreGraphics

/// The corners the SDK draws. A control is a capsule and a group of rows takes the system's corner,
/// so neither has a number here.
enum Radius: CGFloat {

  /// A shape that sits inside a row.
  case inner = 12
}
