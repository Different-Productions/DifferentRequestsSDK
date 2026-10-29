import SwiftUI

extension View {

  /// The one list look every SDK screen shares: rows on a card, on the system's grouped background.
  /// macOS has no grouped style, so a list there is inset.
  func groupedList() -> some View {
    #if os(iOS)
    listStyle(.insetGrouped)
      .listSectionSpacing(Spacing.small.points())
      // Added to the system's own gap under a large title, which makes it one small space.
      .contentMargins(.top, Spacing.xxSmall.points(), for: .scrollContent)
    #else
    listStyle(.inset)
    #endif
  }

  /// The grouped list's own background behind a screen that has no list up: reading, empty, failed.
  func groupedBackground() -> some View {
    #if os(iOS)
    background(Color(uiColor: .systemGroupedBackground), ignoresSafeAreaEdges: .all)
    #else
    self
    #endif
  }
}
