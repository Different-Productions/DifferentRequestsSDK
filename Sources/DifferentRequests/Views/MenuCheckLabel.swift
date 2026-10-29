import SwiftUI

/// A menu item's words, with a checkmark while what it names is in effect.
struct MenuCheckLabel: View {

  /// What the item says, and whether what it names is in effect.
  let content: MenuCheckContent

  var body: some View {
    if content.checked {
      Label(content.title, systemImage: "checkmark")
        .accessibilityAddTraits(.isSelected)
    } else {
      Text(content.title)
    }
  }
}
