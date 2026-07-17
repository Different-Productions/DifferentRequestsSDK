import Foundation
import DifferentRequests

/// Loads the requests the signed-in user follows.
///
/// The follow list only carries request IDs, so each is hydrated into a full
/// ``Request`` to show a title and score. A followed request that has since
/// been merged or removed is skipped rather than failing the whole load.
@Observable
@MainActor
final class FollowingModel {
  private(set) var requests: [Request] = []
  private(set) var isLoading = false
  private(set) var errorMessage: String?

  private let client: DifferentRequestsClient
  private let pageSize = 20

  init(client: DifferentRequestsClient) {
    self.client = client
  }

  func load() async {
    isLoading = true
    errorMessage = nil
    do {
      let page = try await client.listFollowedRequests(limit: pageSize, cursor: nil)
      var hydrated: [Request] = []
      for follow in page.follows {
        do {
          let request = try await client.getRequest(id: follow.requestId)
          hydrated.append(request)
        } catch {
          continue
        }
      }
      requests = hydrated
    } catch {
      errorMessage = error.localizedDescription
    }
    isLoading = false
  }
}
