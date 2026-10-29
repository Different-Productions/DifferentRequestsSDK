import DifferentRequestsProtos
import SwiftUI

/// The leading end of a request's row: the vote tile for somebody signed in, and a plain count for
/// nobody.
struct RequestVote: View {

  /// What holds who is signed in and the board the vote is written through.
  let hub: DifferentRequestsHub

  let request: DRFeatureRequest

  var body: some View {
    if hub.whoIsHere.somebodyIsHere() {
      VoteControl(tile: VoteTile(request: request, writing: hub.board.write.isWriting())) {
        await hub.board.toggleVote(requestID: request.id)
      }
    } else {
      VoteTally(tile: VoteTile(request: request))
    }
  }
}
