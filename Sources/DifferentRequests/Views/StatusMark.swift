import SwiftUI

/// A status as a symbol and a word, both in the label color, so no status is told by hue.
struct StatusMark: View {

  /// The status in the phone's language, and the SF Symbol that gives it its shape.
  let content: StatusMarkContent

  var body: some View {
    HStack(spacing: Spacing.xxSmall.points()) {
      Image(systemName: content.symbol)
        .accessibilityHidden(true)
      Text(content.word)
    }
    .textRole(.meta)
    .foregroundStyle(ColorRole.label)
  }
}
