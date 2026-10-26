import SwiftUI

/// How much room is left in a field, shown only once somebody is close to the limit. Past it, the
/// line says how much to cut, with a symbol, so the change is never told by color alone.
struct CharactersLeft: View {

  /// The limit minus what is typed. Negative once it is over.
  let left: Int

  var body: some View {
    if left < 0 {
      Label {
        Text("\(-left) characters too many", bundle: .module, comment: "Characters over a field's limit")
      } icon: {
        Image(systemName: "exclamationmark.circle")
      }
      .textRole(.meta)
      .foregroundStyle(ColorRole.failure)
    } else if left <= CharacterCountdown.shownFrom.rawValue {
      Text("\(left) characters left", bundle: .module, comment: "Characters left before a field's limit")
        .textRole(.meta)
        .foregroundStyle(ColorRole.secondaryLabel)
    }
  }
}
