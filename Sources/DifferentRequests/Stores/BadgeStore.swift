import Foundation

/// Whether the screens carry the badge, read once and held for the whole session.
///
/// A store of its own rather than a flag on the board, because two screens draw it and a second
/// copy of the answer is a second thing to keep in step. The client answers a repeated `config`
/// call from its first read, so a screen asking costs no round trip of its own.
@Observable
@MainActor
final class BadgeStore {

  // MARK: - Inputs

  /// The client the configuration is read through.
  let client: DifferentRequestsClient

  // MARK: - State

  /// Whether this app pays, and how far the asking got.
  var state: BadgeState = .unread

  // MARK: - Init

  /// - Parameter client: The client the configuration is read through.
  init(client: DifferentRequestsClient) {
    self.client = client
  }

  // MARK: - Loading

  /// Asks whether this app pays.
  ///
  /// Asks again only after a read that failed. An app does not change plan mid-launch, and the
  /// contract states the configuration is fetched once per launch.
  func load() async {
    if state.needsReading == false { return }
    state = .reading

    do {
      let answer = try await client.config()
      state = BadgeState(response: answer)
    } catch {
      state = .failed(error)
    }
  }
}
