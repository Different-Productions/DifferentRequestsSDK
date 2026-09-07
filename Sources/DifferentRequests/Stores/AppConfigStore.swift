import DifferentRequestsProtos
import Foundation

/// What this app includes, read once and held for the whole session.
///
/// One store rather than a read per screen. The badge, and the menu that decides which surfaces are
/// reachable, are two readers of one answer — and a second copy of it is a second thing to keep in
/// step. The client answers a repeated `config` call from its first read, so nothing here costs a
/// round trip of its own.
@Observable
@MainActor
final class AppConfigStore {

  // MARK: - Inputs

  /// The client the configuration is read through.
  let client: DifferentRequestsClient

  // MARK: - State

  /// Whether this app pays, and how far the asking got.
  var badge: BadgeState = .unread

  /// What the app includes. An unread configuration is an empty one, so every surface is absent
  /// until the server says otherwise — which is the honest rendering of not knowing, and the same
  /// rule the badge follows.
  var config = DRAppConfig()

  // MARK: - Init

  /// - Parameter client: The client the configuration is read through.
  init(client: DifferentRequestsClient) {
    self.client = client
  }

  // MARK: - Loading

  /// Asks what this app includes.
  ///
  /// Asks again only after a read that failed. An app does not change plan mid-launch, and the
  /// contract states the configuration is fetched once per launch.
  func load() async {
    if badge.needsReading == false { return }
    badge = .reading

    do {
      let answer = try await client.config()
      config = answer.config
      badge = BadgeState(response: answer)
    } catch {
      badge = .failed(error)
    }
  }
}
