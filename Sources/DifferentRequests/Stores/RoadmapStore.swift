import DifferentRequestsProtos
import Foundation

/// Backs the roadmap: what is planned, what is being built, and what shipped.
///
/// Wraps `DifferentRequestsClient.roadmap()`, which answers with the whole roadmap in one read.
/// There is no pagination and no cursor here on purpose — a roadmap is a summary, each column is
/// a bounded page the server chose, and a column with four hundred planned items is a question
/// the board answers rather than the roadmap.
///
/// The columns are kept in the order the server sent them. Ordering is the server's to decide so
/// every client's roadmap reads the same way.
///
/// Main-actor isolated and observable.
@MainActor
@Observable
final class RoadmapStore {

  // MARK: - Inputs

  /// The client every call goes through.
  let client: DifferentRequestsClient

  // MARK: - State

  /// The columns, in display order, left to right.
  var columns: [DRRoadmapColumn] = []

  /// `true` while the roadmap is being fetched.
  var isLoading: Bool = false

  /// Whether a first `load()` has finished, whether or not it succeeded. What separates "not
  /// read yet" from "read, and there is nothing on the roadmap".
  var hasLoaded: Bool = false

  /// The failure from the most recent read, cleared when a fresh `load()` starts.
  var loadError: Error?

  // MARK: - Init

  /// - Parameter client: The client the roadmap reads through.
  init(client: DifferentRequestsClient) {
    self.client = client
  }

  // MARK: - Loading

  /// Reads the roadmap.
  ///
  /// Returns immediately when a read is already running. The columns already held survive a
  /// failure, so a refresh that cannot reach the network leaves the roadmap readable.
  func load() async {
    if isLoading { return }
    isLoading = true
    loadError = nil
    defer {
      isLoading = false
      hasLoaded = true
    }

    do {
      let answer = try await client.roadmap()
      columns = answer.columns
    } catch {
      loadError = error
    }
  }
}
