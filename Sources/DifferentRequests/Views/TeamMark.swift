import SwiftUI

/// The mark beside a comment the app's team wrote: a seal in the tint and the word in the label
/// color, so an official answer never reads like another reader's guess.
struct TeamMark: View {

  var body: some View {
    HStack(spacing: Spacing.xxSmall.rawValue) {
      Image(systemName: "checkmark.seal.fill")
        .foregroundStyle(ColorRole.tint)
        .accessibilityHidden(true)
      Text("Team", bundle: .module, comment: "Mark beside a comment written by the app's team")
        .foregroundStyle(ColorRole.label)
    }
    .textRole(.supporting)
    .fontWeight(.semibold)
  }
}
