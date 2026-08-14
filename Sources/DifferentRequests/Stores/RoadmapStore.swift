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
/// One state and nothing else: no paging, and nothing is written from this surface.
///
/// Main-actor isolated and observable.
@MainActor
@Observable
final class RoadmapStore {

  // MARK: - Inputs

  /// The client every call goes through.
  let client: DifferentRequestsClient

  // MARK: - State

  /// The roadmap itself: where its read got to, and the columns it found, in display order.
  var read: ReadState<[DRRoadmapColumn]> = .unread

  // MARK: - Init

  /// - Parameter client: The client the roadmap reads through.
  init(client: DifferentRequestsClient) {
    self.client = client
  }

  // MARK: - Loading

  /// Reads the roadmap.
  ///
  /// Returns immediately when a read is already running. The columns already held stay on screen
  /// for the length of the read, and a read that fails replaces them with the failure: columns
  /// left up after a refresh that could not reach the server are a roadmap presenting itself as
  /// current when nobody knows whether it is.
  func load() async {
    if read.isReading { return }
    read = read.whileReading

    do {
      let answer = try await client.roadmap()
      read = ReadState(page: answer.columns)
    } catch {
      read = ReadState(readFailure: error)
    }
  }
}
