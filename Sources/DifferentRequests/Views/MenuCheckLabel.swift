import SwiftUI

/// A menu item's words, with a checkmark while what it names is in effect.
struct MenuCheckLabel: View {

  /// What the item says.
  let title: String

  /// Whether what the item names is in effect.
  let isChecked: Bool

  var body: some View {
    if isChecked {
      Label(title, systemImage: "checkmark")
        .accessibilityAddTraits(.isSelected)
    } else {
      Text(title)
    }
  }
}
