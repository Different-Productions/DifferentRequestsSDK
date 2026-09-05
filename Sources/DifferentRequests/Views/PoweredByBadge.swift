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

  /// Whether this app pays. Read rather than passed as a `Bool`, so the badge appears the moment
  /// the configuration answers without the screen arranging it.
  let badge: BadgeStore

  /// Where a tap goes. On iOS it opens over the app and returns the reader where they were; on
  /// macOS there is no such thing, and opening the browser is what a Mac app does.
  static let home = URL(string: "https://differentrequests.com")

  @State private var isShowingHome = false
  @Environment(\.openURL) private var openURL

  var body: some View {
    if badge.state.isCarried, let home = Self.home {
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

  /// The mark and the words. The mark is drawn rather than shipped as an asset: at this size it is
  /// a chevron on the accent, and an asset catalog would be a second place the icon lives.
  private var label: some View {
    HStack(spacing: 4) {
      Image(systemName: "chevron.up")
        .font(.system(size: 7, weight: .black))
        .foregroundStyle(.white)
        .frame(width: 12, height: 12)
        .background(
          RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(Color.accentColor)
        )
      Text("Powered by ")
        .foregroundStyle(.tertiary)
        + Text("Different Requests")
        .foregroundStyle(.secondary)
    }
    .font(.caption2)
  }
}
