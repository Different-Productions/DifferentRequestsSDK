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

  /// Where a tap goes. On iOS it opens over the app and returns the reader where they were; on
  /// macOS there is no such thing, and opening the browser is what a Mac app does.
  static let home = URL(string: "https://differentrequests.com")

  @State private var isShowingHome = false
  @Environment(\.openURL) private var openURL

  var body: some View {
    if appConfig.badge.isCarried, let home = Self.home {
      Button {
        #if os(iOS)
          isShowingHome = true
        #else
          openURL(home)
        #endif
      } label: {
        label
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Powered by Different Requests")
      .accessibilityHint("Opens the Different Requests website")
      #if os(iOS)
        .sheet(isPresented: $isShowingHome) {
          SafariSheet(url: home)
            .ignoresSafeArea()
        }
      #endif
    }
  }

  /// The mark and the words. The mark is drawn rather than shipped as an asset, and it is a filled
  /// square rather than a chevron: a chevron here is the vote control's own glyph, and a badge
  /// wearing it reads as something votable.
  private var label: some View {
    HStack(spacing: 4) {
      RoundedRectangle(cornerRadius: 3, style: .continuous)
        .fill(Color.accentColor)
        .frame(width: 12, height: 12)
      // Two `Text`s in a stack of their own, holding the word space between them rather than the
      // stack's spacing. `Text + Text` said this in one run and is gone in 26.
      HStack(spacing: 0) {
        Text("Powered by ")
          .foregroundStyle(.tertiary)
        Text("Different Requests")
          .foregroundStyle(.secondary)
      }
    }
    .font(.caption2)
  }
}
