import DifferentRequestsProtos
import Foundation
import SwiftProtobuf

/// When each request was last heard to have changed.
///
/// A notification exists because something changed, so news about a request is the statement that
/// the copy anybody is holding is out of date. Held here rather than as a flag on each screen: a
/// flag says "refresh me" and has to be cleared by whoever obeys it, while an instant says what
/// happened and stays true — a screen compares it with when its own copy arrived and re-reads when
/// the news is newer.
///
/// Three things put news in here: the inbox, every time it reads a notification; the board, when a
/// vote cast from a row lands; and the host app, when a push lands while it is running. None has to
/// know what is holding a stale copy.
///
/// Observable, so a screen already up re-reads the moment news lands. A body reads this only to key
/// a task; the re-read runs in that task, and only `heard(aboutRequest:at:)` writes, from a store's
/// async work or the hub, never while a body is being built.
@MainActor
@Observable
final class NewsAboutRequests {

  /// The newest instant each request was heard to have changed, by request id.
  private(set) var news = NewsState()

  /// Records that this request changed at this instant.
  ///
  /// News no newer than what is held is dropped without a write: an inbox re-read hands over every
  /// notification it holds, the newest is the only one that says anything a held copy does not
  /// already know, and a re-read that learns nothing wakes no screen.
  func heard(aboutRequest requestID: String, at instant: Date) {
    if lastHeard(aboutRequest: requestID).date < instant {
      news.heardAt[requestID] = Google_Protobuf_Timestamp(date: instant)
    }
  }

  /// When this request was last heard to have changed, or an unset instant when it never was.
  ///
  /// What a request's own screen keys its read on, so news about it reads it again while it is up.
  func lastHeard(aboutRequest requestID: String) -> Google_Protobuf_Timestamp {
    if let heard = news.heardAt[requestID] {
      return heard
    }
    return Google_Protobuf_Timestamp()
  }

  /// Whether the request `detail` holds changed after its copy was read.
  ///
  /// A copy that was never read is not stale — it is absent, which the screen's own read state
  /// already says.
  func hasNews(about detail: RequestDetailState) -> Bool {
    if detail.hasReadAt {
      return isNewer(aboutRequest: detail.requestID, than: detail.readAt)
    }
    return false
  }

  /// Whether any row `board` holds changed after its copy arrived.
  func hasNews(about board: BoardState) -> Bool {
    board.copiedAt.contains { requestID, copied in
      isNewer(aboutRequest: requestID, than: copied)
    }
  }

  /// Whether this request was heard to have changed after `copied`.
  private func isNewer(aboutRequest requestID: String, than copied: Google_Protobuf_Timestamp) -> Bool {
    if let heard = news.heardAt[requestID] {
      return heard.date > copied.date
    }
    return false
  }
}
