import DifferentRequestsProtos
import SwiftUI

/// Follow on a request's own screen: a bell and "Follow", or a checkmark and "Following", so the
/// two read apart by shape and word and never by color.
struct FollowButton: View {

  /// The request's own store, which writes the follow.
  let store: RequestDetailStore

  let request: DRFeatureRequest

  var body: some View {
    AsyncButton {
      await store.toggleFollow()
    } label: {
      if request.viewer.isFollowing {
        Label {
          Text("Following", bundle: .module, comment: "Button showing the reader follows a request; a tap unfollows")
        } icon: {
          Image(systemName: "checkmark")
        }
      } else {
        Label {
          Text("Follow", bundle: .module, comment: "Button that follows a request to get updates on it")
        } icon: {
          Image(systemName: "bell")
        }
      }
    }
    .buttonStyle(PillButtonStyle(fill: .gray))
    .disabled(store.write.isWriting())
  }
}
