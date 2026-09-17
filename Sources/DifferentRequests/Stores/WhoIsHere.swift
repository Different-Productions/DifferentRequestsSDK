import DifferentRequestsProtos
import Foundation

/// The person the host app signed in, as the screens read it.
///
/// Reading the board needs only an app key; asking, voting, following and commenting act for
/// somebody. A host app that never calls `createSession` has nobody, and every one of those
/// controls can only fail — which is what happened: Submit answered "That didn't send. Try again in
/// a moment." forever, to a person who had done nothing wrong and could do nothing about it.
///
/// So the screens ask this before they offer a control that acts for a person. It holds the person
/// rather than a flag, because the person is what the rest of the screen wants anyway.
///
/// Main-actor isolated and observable. The client is an actor and a body cannot wait on one, so
/// what it holds is read here on appear and kept.
@MainActor
@Observable
final class WhoIsHere {

  /// The client this reads from.
  let client: DifferentRequestsClient

  /// Who the host app signed in, or nobody. Absent until the first read, which is also nobody as
  /// far as any screen is concerned — there is no third state worth drawing.
  private(set) var person: DREndUser?

  /// - Parameter client: The client holding the session, if there is one.
  init(client: DifferentRequestsClient) {
    self.client = client
  }

  /// Whether a control that acts for a person is worth offering.
  var somebodyIsHere: Bool {
    person != nil
  }

  /// Reads who the client is holding.
  ///
  /// Called by a screen when it appears, because a host app may sign somebody in after the first
  /// screen is already drawn — at launch, or when its own sign-in finishes.
  func read() async {
    person = await client.currentUser
  }
}
