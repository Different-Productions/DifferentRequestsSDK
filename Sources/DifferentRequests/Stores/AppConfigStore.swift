import DifferentRequestsProtos
import Foundation

/// What this app includes, read once and held for the whole session.
///
/// One store rather than a read per screen. The Powered by row, the look every screen is drawn in
/// and each plan-gated screen are readers of one answer, and a second copy of it is a second thing
/// to keep in step. The client answers a repeated `config` call from its first read, so nothing here costs a
/// round trip of its own.
@Observable
@MainActor
final class AppConfigStore {

  // MARK: - Inputs

  /// The client the configuration is read through.
  let client: DifferentRequestsClient

  // MARK: - State

  /// Whether this app pays, and how far the asking got.
  var badge = BadgeState()

  /// What the app includes. An unread configuration is an empty one, so every surface is absent
  /// until the server says otherwise — which is the honest rendering of not knowing, and the same
  /// rule the badge follows.
  var config = DRAppConfig()

  /// The sections the Mac sheet offers, in order: Requests, then Roadmap and What's New where the
  /// plan includes them, then Inbox. Written by ``load()`` with ``config``, and empty before then:
  /// no sheet is drawn until the configuration has answered.
  var sheetTabs = OfferedTabs()

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
    if badge.needsReading() {
      badge.state = .reading(Reading())

      do {
        let answer = try await client.config()
        config = answer.config
        var tabs: [ScreenTab] = [.requests]
        if answer.config.roadmapEnabled {
          tabs.append(.roadmap)
        }
        if answer.config.changelogEnabled {
          tabs.append(.changelog)
        }
        tabs.append(.inbox)
        sheetTabs.offered = tabs
        badge = BadgeState(response: answer)
      } catch {
        badge.state = .failed(ReadTrouble(error: error))
      }
    }
  }
}
