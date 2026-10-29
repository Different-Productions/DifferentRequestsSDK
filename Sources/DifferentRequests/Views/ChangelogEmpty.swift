import SwiftUI

/// What's New with nothing in it, with See requests where the host app gave a way to its list.
struct ChangelogEmpty: View {

  /// What opens the host's requests list, or nil for no See requests.
  let requestsPresentation: Binding<RequestsPresentation>?

  var body: some View {
    ContentUnavailableView {
      Label {
        Text("Nothing new yet", bundle: .module, comment: "Heading on an empty release notes screen")
      } icon: {
        Image(systemName: "sparkles")
      }
    } description: {
      Text(
        "When the app gets something new, you'll read about it here.",
        bundle: .module,
        comment: "Message on an empty release notes screen"
      )
    } actions: {
      if let requestsPresentation {
        SeeRequestsButton(requestsPresentation: requestsPresentation)
      }
    }
  }
}
