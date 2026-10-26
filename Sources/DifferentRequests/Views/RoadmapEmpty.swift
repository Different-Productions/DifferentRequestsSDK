import SwiftUI

/// A roadmap with nothing on it, with See requests where the host app gave a way to its list.
struct RoadmapEmpty: View {

  /// What opens the host's requests list, or nil for no See requests.
  let isShowingRequests: Binding<Bool>?

  var body: some View {
    ContentUnavailableView {
      Label {
        Text("Nothing planned yet", bundle: .module, comment: "Heading when the roadmap has nothing on it")
      } icon: {
        Image(systemName: "map")
      }
    } description: {
      Text("When the team plans something, it shows up here.", bundle: .module, comment: "Message when the roadmap has nothing on it")
    } actions: {
      if let isShowingRequests {
        SeeRequestsButton(isShowingRequests: isShowingRequests)
      }
    }
  }
}
