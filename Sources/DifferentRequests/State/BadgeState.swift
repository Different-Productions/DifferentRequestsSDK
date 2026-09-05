/// Whether this app's screens carry "Powered by Different Requests", and how far the asking got.
///
/// One value rather than a `Bool`, for the reason ``PlanState`` is one: a read that has not
/// happened, a read that failed, and a read that answered "no" are three different situations, and
/// a `Bool` is two of them at best.
///
/// **A failed read draws nothing.** The two mistakes are not the same size. A badge missing for a
/// moment on a free app costs nothing and nobody notices. A badge drawn on an app that is paying
/// to be rid of it is a support ticket from a customer who is right.
enum BadgeState {

  /// Nothing has been asked.
  case unread

  /// The app's configuration is being read.
  case reading

  /// The configuration did not answer, so whether this app pays is not known.
  ///
  /// The error is here for whoever is debugging, and never reaches the screen — there is no copy
  /// to show, because the badge simply is not drawn.
  case failed(any Error)

  /// The configuration answered and this app pays, so there is no badge.
  case bought

  /// The configuration answered and this app is on the free plan.
  case carried
}

extension BadgeState {

  /// What an answer to `getConfig` says about the badge.
  init(response: DRGetConfigResponse) {
    self = response.config.showBadge ? .carried : .bought
  }

  /// Whether the screens draw it. Every state that is not a definite yes draws nothing.
  var isCarried: Bool {
    switch self {
    case .carried:
      return true
    case .unread, .reading, .failed, .bought:
      return false
    }
  }

  /// Whether asking again would tell us anything. A failed read is worth retrying; an answered one
  /// is not, and the client holds the answer anyway.
  var needsReading: Bool {
    switch self {
    case .unread, .failed:
      return true
    case .reading, .bought, .carried:
      return false
    }
  }
}
