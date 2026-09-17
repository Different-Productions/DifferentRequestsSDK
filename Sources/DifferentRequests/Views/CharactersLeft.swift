import SwiftUI

/// How much room is left in a field, shown only once it is worth knowing.
///
/// Silent until somebody is close, because a counter under an empty field is a limit announced to
/// people who were never going to reach it. Once it is over, the number goes red and says how much
/// to cut — which is the thing the server's refusal could never say, because it arrives after the
/// writing is already lost.
struct CharactersLeft: View {

  /// The limit minus what is typed. Negative once it is over.
  let left: Int

  /// How close somebody has to be before the count appears.
  private static let showFrom = 40

  var body: some View {
    if left < 0 {
      Text("\(-left) too many")
        .font(.footnote)
        .foregroundStyle(.red)
    } else if left <= Self.showFrom {
      Text("\(left) left")
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
  }
}
