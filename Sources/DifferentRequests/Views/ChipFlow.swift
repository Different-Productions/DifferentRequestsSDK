import SwiftUI

/// Lays chips left to right and wraps to a new line when the next one will not fit.
///
/// SwiftUI ships no wrapping stack, and the alternative — a horizontal `ScrollView` — comes to
/// rest wherever the screen ends, so the last chip on screen is a cut word. A filter bar that
/// reads "In Pr" looks broken rather than scrollable.
///
/// Every chip is placed at the size it asks for. Nothing is compressed to make a line fit, because
/// a chip narrower than its own word is the failure this exists to prevent.
struct ChipFlow: Layout {

  /// The gap between two chips on a line.
  let spacing: CGFloat

  /// The gap between two lines.
  let lineSpacing: CGFloat

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
    let width = proposal.width ?? .infinity
    let lines = linesOf(subviews, inWidth: width)

    var height: CGFloat = 0
    var widest: CGFloat = 0
    for (offset, line) in lines.enumerated() {
      if offset > 0 {
        height += lineSpacing
      }
      height += line.height
      widest = max(widest, line.width)
    }
    return CGSize(width: min(widest, width), height: height)
  }

  func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout Void
  ) {
    var y = bounds.minY
    for (offset, line) in linesOf(subviews, inWidth: bounds.width).enumerated() {
      if offset > 0 {
        y += lineSpacing
      }
      var x = bounds.minX
      for index in line.indices {
        let size = subviews[index].sizeThatFits(.unspecified)
        subviews[index].place(
          at: CGPoint(x: x, y: y + (line.height - size.height) / 2),
          proposal: ProposedViewSize(size)
        )
        x += size.width + spacing
      }
      y += line.height
    }
  }

  /// The chips grouped into the lines they land on, measured once and read by both passes.
  private func linesOf(_ subviews: Subviews, inWidth width: CGFloat) -> [ChipLine] {
    var lines: [ChipLine] = []
    var current = ChipLine()

    for index in subviews.indices {
      let size = subviews[index].sizeThatFits(.unspecified)
      let widthWithChip = current.indices.isEmpty
        ? size.width
        : current.width + spacing + size.width

      if current.indices.isEmpty == false, widthWithChip > width {
        lines.append(current)
        current = ChipLine()
        current.add(index: index, size: size, spacing: spacing)
      } else {
        current.add(index: index, size: size, spacing: spacing)
      }
    }

    if current.indices.isEmpty == false {
      lines.append(current)
    }
    return lines
  }
}
