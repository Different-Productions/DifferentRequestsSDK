import SwiftUI

/// "Powered by Different Requests", under the title of a free app's board and inbox.
///
/// Drawn small and quiet on purpose. It sits under the title rather than pinned to the bottom
/// because it is a mark of where the screen came from, not an advertisement placed over somebody
/// else's app — and the developer who resents it least is the one most likely to keep it there
/// long enough to pay for its removal.
///
/// Nothing is drawn until the configuration has answered. See ``BadgeState``.
struct PoweredByBadge: View {

  /// What this app includes. Read rather than passed as a `Bool`, so the badge appears the moment
  /// the configuration answers without the screen arranging it.
  let appConfig: AppConfigStore

  /// Whether "What is this?" is up over the screen.
  @State private var isShowingAbout = false

  var body: some View {
    if appConfig.badge.isCarried {
      Button {
        isShowingAbout = true
      } label: {
        label
      }
      .buttonStyle(.plain)
      .accessibilityLabel(Text("Powered by Different Requests", bundle: .module, comment: "VoiceOver label for the badge; Different Requests is the product's name"))
      .accessibilityHint(Text("Says what Different Requests is", bundle: .module, comment: "VoiceOver hint for the badge; Different Requests is the product's name"))
      .sheet(isPresented: $isShowingAbout) {
        PoweredByPage(appConfig: appConfig)
      }
    }
  }

  /// The words, and nothing else.
  ///
  /// There was a filled square in front of them, drawn here rather than shipped as an asset. It
  /// was not a mark of anything — a square says nothing about this product, and on a board full of
  /// real controls it read as something that had failed to load. The name is the mark.
  private var label: some View {
    // Two `Text`s in a stack of their own, holding the word space between them rather than the
    // stack's spacing. `Text + Text` said this in one run and is gone in 26.
    HStack(spacing: 0) {
      Text("Powered by ", bundle: .module, comment: "Words before the product name on the badge, with the space before the name")
      Text(verbatim: "Different Requests")
        .fontWeight(.semibold)
    }
    .font(.caption)
    .foregroundStyle(.secondary)
  }
}
