import SwiftUI

/// The Mac sheet's sections: a segmented control centered on the top edge of a box holding the
/// chosen section's screen.
///
/// This is how a Mac tab view looks. It is drawn here rather than with `TabView` because macOS 27.0.1
/// draws the tab view's own tabbed control collapsed, labels on top of one another.
struct SheetTabs: View {

  /// What every section reads from.
  let hub: DifferentRequestsHub

  /// The section being shown.
  @State private var tab = ScreenTab.requests

  var body: some View {
    ZStack(alignment: .top) {
      SheetTabContent(hub: hub, tab: tab)
        .safeAreaPadding(.top, Spacing.small.points())
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: Radius.inner.points()))
        .overlay {
          RoundedRectangle(cornerRadius: Radius.inner.points())
            .strokeBorder(.separator)
        }
        .padding(.top, Spacing.small.points())

      Picker(selection: $tab) {
        ForEach(hub.appConfig.sheetTabs.offered, id: \.self) { offered in
          ScreenTabTitle(tab: offered)
        }
      } label: {
        EmptyView()
      }
      .pickerStyle(.segmented)
      .labelsHidden()
      .fixedSize()
      // The box's border stops at the control, as a tab view's does, instead of showing through
      // its segments.
      .background(.windowBackground, in: Capsule())
    }
  }
}
