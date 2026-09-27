import DifferentRequests
import SwiftUI

/// A surface the SDK draws, as a row this example offers.
///
/// Every one of these is a screen the SDK already ships. What this example adds is a way in to each
/// of them from a host app's own settings list, which is the integration a developer is deciding
/// whether to write.
///
/// The board reaches the other three through its own menu. They are here as well because a menu
/// behind an ellipsis is not a demonstration — somebody evaluating this should see what they get
/// without hunting for it.
enum ExampleScreen: String, Identifiable, CaseIterable {
  /// Everything people asked for, ranked, searchable, with the composer behind it.
  case requests

  /// What this reader has been told about the requests they follow. Where a push lands.
  case inbox

  /// What is planned and what is being built, in columns. Pro.
  case roadmap

  /// What shipped, written up. Pro.
  case changelog

  /// What the SDK says about its own setup, which is the first thing to read when a board is empty
  /// and nobody knows why.
  case diagnostics

  var id: String { rawValue }

  /// What the row says.
  var title: String {
    switch self {
    case .requests: return String(localized: "Requests", comment: "Example row that opens the request board")
    case .inbox: return String(localized: "Inbox", comment: "Example row that opens the inbox")
    case .roadmap: return String(localized: "Roadmap", comment: "Example row that opens the roadmap")
    case .changelog: return String(localized: "What's New", comment: "Example row that opens the release notes")
    case .diagnostics: return String(localized: "Diagnostics", comment: "Example row that opens the SDK's own diagnostics")
    }
  }

  var symbol: String {
    switch self {
    case .requests: return "list.bullet"
    case .inbox: return "bell"
    case .roadmap: return "map"
    case .changelog: return "sparkles"
    case .diagnostics: return "stethoscope"
    }
  }

  /// One line saying what the developer gets, because this app exists to be evaluated.
  var explanation: String {
    switch self {
    case .requests:
      return String(
        localized: "Ranked by votes and searchable, with a button to ask for something new.",
        comment: "Example row explanation"
      )
    case .inbox:
      return String(
        localized: "Status changes, replies and duplicates on what they follow. Tapping a notification opens it.",
        comment: "Example row explanation"
      )
    case .roadmap:
      return String(localized: "Planned and in progress, in columns.", comment: "Example row explanation")
    case .changelog:
      return String(localized: "What shipped, written up, linked to the requests it answers.", comment: "Example row explanation")
    case .diagnostics:
      return String(
        localized: "What the SDK says about its own setup. Paste it into a support email.",
        comment: "Example row explanation"
      )
    }
  }

  /// Whether this app carries this screen.
  ///
  /// The two paid surfaces are answered by the config the server sent, so what the rows offer and
  /// what the rpcs behind them allow cannot disagree.
  func isCarried(by config: DRAppConfig) -> Bool {
    switch self {
    case .requests, .inbox, .diagnostics: return true
    case .roadmap: return config.roadmapEnabled
    case .changelog: return config.changelogEnabled
    }
  }
}
