import SwiftUI

/// What the Roadmap draws under its title. Whether this app has a roadmap is answered first, on the
/// screen, so an app without one never makes a read that can only be refused; then the roadmap's own
/// read state picks one of four outcomes.
struct RoadmapContent: View {

  /// What holds the roadmap.
  let hub: DifferentRequestsHub

  /// What opens the host's requests list, or nil for no See requests.
  let isShowingRequests: Binding<Bool>?

  var body: some View {
    switch hub.roadmap.plan {
    case .unread, .reading:
      ProgressView()
    case .failed(let error):
      LoadFailure(
        title: String(localized: "Roadmap couldn't load", bundle: .module, comment: "Heading when the Roadmap screen failed to load"),
        error: error
      ) {
        await hub.roadmap.load()
      }
    case .excluded:
      AbsentSurface(surface: .roadmap, isShowingRequests: isShowingRequests)
    case .included:
      switch hub.roadmap.read {
      case .unread, .reading:
        ProgressView()
      case .failed(let error):
        LoadFailure(
          title: String(localized: "Roadmap couldn't load", bundle: .module, comment: "Heading when the Roadmap screen failed to load"),
          error: error
        ) {
          await hub.roadmap.load()
        }
      case .empty:
        RoadmapEmpty(isShowingRequests: isShowingRequests)
      case .loaded, .refreshing:
        RoadmapList(hub: hub)
      }
    }
  }
}
