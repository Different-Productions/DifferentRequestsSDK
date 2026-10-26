import SwiftUI

/// A status as a symbol and a word, both in the label color, so no status is told by hue.
struct StatusMark: View {

  /// The status in the phone's language.
  let word: String

  /// The SF Symbol that gives the status its shape.
  let symbol: String

  var body: some View {
    HStack(spacing: Spacing.xxSmall.rawValue) {
      Image(systemName: symbol)
        .accessibilityHidden(true)
      Text(word)
    }
    .textRole(.meta)
    .foregroundStyle(ColorRole.label)
  }
}
