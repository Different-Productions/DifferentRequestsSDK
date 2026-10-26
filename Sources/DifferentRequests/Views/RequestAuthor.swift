import DifferentRequestsProtos
import SwiftUI

/// Who asked: "Deleted user" once the person is deleted, "The team" for a request the app's team
/// filed, the name their app gave, or "Anonymous" when it gave none.
struct RequestAuthor: View {

  let request: DRFeatureRequest

  var body: some View {
    if request.authorDeleted {
      Text("Deleted user", bundle: .module, comment: "Author name for a request whose person was deleted")
    } else if request.hasAuthor == false {
      Text("The team", bundle: .module, comment: "Author name for a request the app's team filed")
    } else if request.author.displayName.isEmpty {
      Text("Anonymous", bundle: .module, comment: "Author name for a request whose person gave no name")
    } else {
      Text(request.author.displayName)
    }
  }
}
