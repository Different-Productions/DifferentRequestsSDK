import DifferentRequestsProtos
import Foundation

/// Backs the inbox: what a reader has been told, and how much of it they have not read.
///
/// Wraps `DifferentRequestsClient.notifications(cursor:)` with cursor pagination driven by the
/// response's `nextCursor`, which the server leaves empty on the last page. The first page
/// comes from `load()` and deeper pages from `loadMore()`; only one page is in flight at a
/// time, so a fast scroll cannot queue duplicate requests.
///
/// The unread count is read from `unreadCount()` alongside the first page rather than counted
/// from it. The page is one window on a list the same person may be reading on another device,
/// and a badge derived from it starts drifting the moment anything is marked read anywhere else.
/// The one adjustment made without the server is subtracting a row this client has just watched
/// go from unread to read, which is not a guess: the write answered with the stamp on it.
///
/// Main-actor isolated and observable.
@MainActor
@Observable
final class InboxStore {

  // MARK: - Inputs

  /// The client every call goes through.
  let client: DifferentRequestsClient

  /// Where news about a request is recorded, so a screen holding an old copy re-reads it.
  ///
  /// Every notification here exists because a request changed, which makes the inbox the one
  /// place that learns about changes without being told.
  let news: NewsAboutRequests

  // MARK: - State

  /// The notifications the inbox's reads found, newest first, how many the server counts unread,
  /// and where the next page starts.
  var inbox = InboxState()

  /// Where the inbox's read has got to.
  var status = ReadStatus()

  /// Whether there is another page, and what became of the last attempt at one.
  var page = PageState()

  /// What the last read stamp is doing, or what it did instead.
  var write = WriteState()

  // MARK: - Init

  /// - Parameters:
  ///   - client: The client the inbox reads and writes through.
  ///   - news: Where what each notification says about its request is recorded.
  init(client: DifferentRequestsClient, news: NewsAboutRequests) {
    self.client = client
    self.news = news
  }

  /// Records what these notifications say: each one is a request that changed when it was written.
  private func record(_ notifications: [DRNotification]) {
    for notification in notifications {
      news.heard(aboutRequest: notification.requestID, at: notification.createdAt.date)
    }
  }

  // MARK: - Loading

  /// Reads the first page and the unread count, replacing everything held.
  ///
  /// A read asked for while one is running is not started twice: the running read reads again when
  /// it lands, because it may have been sent before the update that prompted the ask. What is held
  /// stays on screen for the length of the read: a pull-to-refresh runs on the list's own task, and
  /// a list cleared at the start of a read would take that task with it.
  ///
  /// Both calls are one read. A page that arrives beside a count that did not is an inbox
  /// rendering a badge nobody vouches for, and the toolbar's Read All appears and disappears on
  /// that badge — so either both answered or the read failed.
  func load() async {
    if status.isReading() {
      inbox.askedAgain = true
    } else {
      repeat {
        inbox.askedAgain = false
        await readFirstPage()
      } while inbox.askedAgain
    }
  }

  /// Reads page one and the unread count, and replaces the inbox with them.
  private func readFirstPage() async {
    status.state = .reading(Reading())
    inbox.cursor = ""
    page = PageState()

    do {
      let answer = try await client.notifications(cursor: inbox.cursor)
      let counted = try await client.unreadCount()
      inbox.unreadCount = counted.unreadCount
      inbox.notifications = answer.notifications
      status.state = .loaded(ReadAnswered())
      inbox.cursor = answer.nextCursor
      page = PageState(nextCursor: answer.nextCursor)
      record(answer.notifications)
    } catch {
      inbox.notifications = []
      status = ReadStatus(readFailure: error)
      page.state = .done(NoMorePages())
    }
  }

  /// Appends the next page.
  ///
  /// Returns immediately when the server reported no further page, when one is already in flight,
  /// or when the whole inbox is being re-read.
  func loadMore() async {
    if page.isReading() == false, page.isDone() == false, status.isReading() == false {
      page.state = .reading(Reading())

      do {
        let answer = try await client.notifications(cursor: inbox.cursor)
        inbox.notifications.append(contentsOf: answer.notifications)
        status.state = .loaded(ReadAnswered())
        inbox.cursor = answer.nextCursor
        page = PageState(nextCursor: answer.nextCursor)
        record(answer.notifications)
      } catch {
        // The cursor is left where it was, so the retry asks for this page rather than skipping it.
        page.state = .failed(ReadTrouble(error: error))
      }
    }
  }

  // MARK: - Writes

  /// Stamps one notification read.
  ///
  /// The row is found again by id after the write answers rather than by an index taken before
  /// it: a reload can replace the list while the call is suspended, and an index from before the
  /// suspension would then address a different row or none at all. A row that is gone is not an
  /// error — it was read, which is what was asked for.
  func markRead(notificationID: String) async {
    let matchingNotification = inbox.notifications.first { notification in
      notification.id == notificationID
    }
    if write.isWriting() == false, let current = matchingNotification {
      let wasUnread = current.hasReadAt == false
      write.state = .writing(.markRead)

      do {
        let written = try await client.markRead(notificationID: notificationID).notification
        inbox.notifications = inbox.notifications.replacingRow(written, identifiedBy: \.id)
        status = status.afterWrite()
        if wasUnread, written.hasReadAt {
          inbox.unreadCount = max(inbox.unreadCount - 1, 0)
        }
        write = WriteState()
      } catch {
        write.state = .failed(WriteFailure(attempt: .markRead, error: error))
      }
    }
  }

  /// Stamps everything read.
  ///
  /// A re-read follows, because the write answers with how many rows it touched rather than with
  /// the rows themselves, and each of those rows now carries a read stamp the inbox renders — as
  /// does the badge. Nothing marked means nothing changed, so there is nothing to re-read.
  func markAllRead() async {
    if write.isWriting() == false {
      write.state = .writing(.markEverythingRead)

      do {
        let marked = try await client.markAllRead().markedCount
        write = WriteState()
        if marked > 0 {
          await load()
        }
      } catch {
        write.state = .failed(WriteFailure(attempt: .markEverythingRead, error: error))
      }
    }
  }

  /// Puts away the notice about the last failed stamp.
  ///
  /// Acknowledgement, not repair: nothing was marked, and the dot that marks it is on screen
  /// either way.
  func acknowledgeWriteFailure() {
    write = WriteState()
  }
}
