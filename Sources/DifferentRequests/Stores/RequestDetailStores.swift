import Foundation

/// The stores behind the request screens, one per request, held for as long as the hub is.
///
/// A pushed screen is rebuilt whenever the screen that pushed it redraws, and a store built
/// alongside it would be rebuilt too — emptying a thread someone was reading and dropping the
/// comment they were writing. Handing back the same store for the same id is what lets the screen
/// survive its own view being thrown away.
///
/// Nothing is evicted. An entry is one request and the thread read for it, and the only eviction
/// that would free anything worth freeing is dropping one a screen still on the stack is reading —
/// which is the defect this exists to prevent. They go when the hub goes, at the end of the launch.
///
/// Not observable: it holds no state a screen renders, and a screen asks it for a store while its
/// body is being built, which is the one moment a write to observed state must not happen.
@MainActor
final class RequestDetailStores {

  /// The client each store is built against.
  private let client: DifferentRequestsClient

  /// What has been opened this launch, by request id.
  private var stores: [String: RequestDetailStore] = [:]

  /// - Parameter client: The client the stores read and write through.
  init(client: DifferentRequestsClient) {
    self.client = client
  }

  /// The store for `requestID`: made on the first ask, and the same one on every ask after that.
  func store(requestID: String) -> RequestDetailStore {
    if let held = stores[requestID] {
      return held
    }
    let opened = RequestDetailStore(client: client, requestID: requestID)
    stores[requestID] = opened
    return opened
  }
}
