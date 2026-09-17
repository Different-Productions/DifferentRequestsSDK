import Foundation

/// When each request was last heard to have changed.
///
/// A notification exists because something changed, so news about a request is the statement that
/// the copy anybody is holding is out of date. Held here rather than as a flag on each screen: a
/// flag says "refresh me" and has to be cleared by whoever obeys it, while an instant says what
/// happened and stays true — a screen compares it with when its own copy arrived and re-reads when
/// the news is newer.
///
/// Two things put news in here: the inbox, every time it reads a notification, and the host app,
/// when a push lands while it is running. Neither has to know what is holding a stale copy.
///
/// Not observable. A screen asks this while its body is being built, which is the one moment a
/// write to observed state must not happen, and nothing draws it directly.
@MainActor
final class NewsAboutRequests {

  /// The newest instant each request was heard to have changed, by request id.
  private var heardAt: [String: Date] = [:]

  /// Records that this request changed at this instant.
  ///
  /// Older news is dropped rather than written: an inbox re-read hands over every notification it
  /// holds, and the newest is the only one that says anything a held copy does not already know.
  func heard(aboutRequest requestID: String, at instant: Date) {
    guard let already = heardAt[requestID] else {
      heardAt[requestID] = instant
      return
    }
    if instant > already {
      heardAt[requestID] = instant
    }
  }

  /// Whether this request changed after a copy read at `readAt` was taken.
  ///
  /// A copy that was never read is not stale — it is absent, which the screen's own read state
  /// already says.
  func hasNews(aboutRequest requestID: String, newerThan readAt: Date?) -> Bool {
    guard let heard = heardAt[requestID], let readAt else {
      return false
    }
    return heard > readAt
  }
}
