import DifferentRequestsProtos

extension BadgeState {

  /// What an answer to `getConfig` says about the badge.
  init(response: DRGetConfigResponse) {
    self.init()
    if response.config.badgeRemoved {
      state = .bought(BadgeBought())
    } else {
      state = .carried(BadgeCarried())
    }
  }

  /// Whether the screens draw it. Every state that is not a definite yes draws nothing: a badge on
  /// an app that pays to be rid of it costs more than one missing for a moment on a free app.
  func isCarried() -> Bool {
    switch state {
    case .carried:
      return true
    case .none, .reading, .failed, .bought:
      return false
    }
  }

  /// Whether asking again would tell us anything. A failed read is worth retrying; an answered one
  /// is not.
  func needsReading() -> Bool {
    switch state {
    case .none, .failed:
      return true
    case .reading, .bought, .carried:
      return false
    }
  }
}
