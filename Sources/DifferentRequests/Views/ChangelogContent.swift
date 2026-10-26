import SwiftUI

/// What What's New draws under its title. Whether this app posts updates is answered first, on the
/// screen, so an app that does not never makes a read that can only be refused; then the updates'
/// own read state picks one of four outcomes.
struct ChangelogContent: View {

  /// What holds the updates.
  let hub: DifferentRequestsHub

  /// What opens the host's requests list, or nil for no See requests.
  let isShowingRequests: Binding<Bool>?

  var body: some View {
    switch hub.changelog.plan {
    case .unread, .reading:
      ProgressView()
    case .failed(let error):
      LoadFailure(
        title: String(localized: "What's New couldn't load", bundle: .module, comment: "Heading when the What's New screen failed to load"),
        error: error
      ) {
        await hub.changelog.load()
      }
    case .excluded:
      AbsentSurface(surface: .changelog, isShowingRequests: isShowingRequests)
    case .included:
      switch hub.changelog.read {
      case .unread, .reading:
        ProgressView()
      case .failed(let error):
        LoadFailure(
          title: String(
            localized: "What's New couldn't load",
            bundle: .module,
            comment: "Heading when the What's New screen failed to load"
          ),
          error: error
        ) {
          await hub.changelog.load()
        }
      case .empty:
        ChangelogEmpty(isShowingRequests: isShowingRequests)
      case .loaded, .refreshing:
        ChangelogList(hub: hub)
      }
    }
  }
}
