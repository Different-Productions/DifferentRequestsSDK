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
    case .requests: return "Feature requests"
    case .inbox: return "Inbox"
    case .roadmap: return "Roadmap"
    case .changelog: return "What's new"
    case .diagnostics: return "Diagnostics"
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
      return "Ranked by votes, searchable, with the composer built in."
    case .inbox:
      return "Status changes, replies and duplicates on what they follow. Where a push lands."
    case .roadmap:
      return "Planned and in progress, in columns."
    case .changelog:
      return "What shipped, written up, linked to the requests it answers."
    case .diagnostics:
      return "What the SDK says about its own setup. Paste it into a support email."
    }
  }

  /// Whether this is one of the two surfaces a Free app does not carry.
  ///
  /// The answer is not here — it is on the config the server sent, and `Session` reads it. This
  /// only says which two questions to ask.
  var isPaidSurface: Bool {
    switch self {
    case .requests, .inbox, .diagnostics: return false
    case .roadmap, .changelog: return true
    }
  }
}
