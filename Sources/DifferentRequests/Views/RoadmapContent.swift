import SwiftUI

/// What the Roadmap draws under its title. Whether this app has a roadmap is answered first, on the
/// screen, so an app without one never makes a read that can only be refused; then the roadmap's own
/// read status and the columns it holds pick one of four outcomes. The list is drawn whenever there
/// are columns, reading or not, so a refresh keeps the list that runs it.
struct RoadmapContent: View {

  /// What holds the roadmap.
  let hub: DifferentRequestsHub

  /// What opens the host's requests list, or nil for no See requests.
  let requestsPresentation: Binding<RequestsPresentation>?

  var body: some View {
    switch hub.roadmap.plan.state {
    case .none, .reading:
      ProgressView()
    case .failed(let failure):
      LoadFailure(content: LoadFailureContent(title: failureTitle(), trouble: failure)) {
        await hub.roadmap.load()
      }
    case .excluded:
      AbsentSurface(surface: .roadmap, requestsPresentation: requestsPresentation)
    case .included:
      if hub.roadmap.roadmap.columns.isEmpty == false {
        RoadmapList(hub: hub)
      } else {
        switch hub.roadmap.status.state {
        case .none, .reading:
          ProgressView()
        case .failed(let trouble):
          LoadFailure(content: LoadFailureContent(title: failureTitle(), trouble: trouble)) {
            await hub.roadmap.load()
          }
        case .loaded:
          RoadmapEmpty(requestsPresentation: requestsPresentation)
        }
      }
    }
  }

  /// The heading over a roadmap that could not be read.
  private func failureTitle() -> String {
    String(localized: "Roadmap couldn't load", bundle: .module, comment: "Heading when the Roadmap screen failed to load")
  }
}
