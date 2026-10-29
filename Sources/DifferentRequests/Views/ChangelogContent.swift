import SwiftUI

/// What What's New draws under its title. Whether this app posts updates is answered first, on the
/// screen, so an app that does not never makes a read that can only be refused; then the updates'
/// own read status and the entries it holds pick one of four outcomes. The list is drawn whenever
/// there are entries, reading or not, so a refresh keeps the list that runs it.
struct ChangelogContent: View {

  /// What holds the updates.
  let hub: DifferentRequestsHub

  /// What opens the host's requests list, or nil for no See requests.
  let requestsPresentation: Binding<RequestsPresentation>?

  var body: some View {
    switch hub.changelog.plan.state {
    case .none, .reading:
      ProgressView()
    case .failed(let failure):
      LoadFailure(content: LoadFailureContent(title: failureTitle(), trouble: failure)) {
        await hub.changelog.load()
      }
    case .excluded:
      AbsentSurface(surface: .changelog, requestsPresentation: requestsPresentation)
    case .included:
      if hub.changelog.changelog.entries.isEmpty == false {
        ChangelogList(hub: hub)
      } else {
        switch hub.changelog.status.state {
        case .none, .reading:
          ProgressView()
        case .failed(let trouble):
          LoadFailure(content: LoadFailureContent(title: failureTitle(), trouble: trouble)) {
            await hub.changelog.load()
          }
        case .loaded:
          ChangelogEmpty(requestsPresentation: requestsPresentation)
        }
      }
    }
  }

  /// The heading over a What's New that could not be read.
  private func failureTitle() -> String {
    String(localized: "What's New couldn't load", bundle: .module, comment: "Heading when the What's New screen failed to load")
  }
}
