import CoreGraphics

/// One line of chips as ``ChipFlow`` builds it: which chips are on it, and how big it is.
struct ChipLine {

  /// The chips on this line, in the order they were offered.
  var indices: [Int]

  /// How wide the line is with its gaps counted.
  var width: CGFloat

  /// The tallest chip on the line, which is the line's own height.
  var height: CGFloat

  init() {
    indices = []
    width = 0
    height = 0
  }

  /// Puts one more chip on this line and grows the line to hold it.
  mutating func add(index: Int, size: CGSize, spacing: CGFloat) {
    if indices.isEmpty == false {
      width += spacing
    }
    indices.append(index)
    width += size.width
    height = max(height, size.height)
  }
}
