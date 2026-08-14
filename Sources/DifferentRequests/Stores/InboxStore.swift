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

  // MARK: - State

  /// The inbox itself: where its read got to, and the notifications it found.
  var read: ReadState<[DRNotification]> = .unread

  /// Whether there is another page, and what became of the last attempt at one.
  var page: PageState = .more

  /// What the last read stamp is doing, or what it did instead.
  var write: WriteState = .idle

  /// How many are unread, as the server counts them.
  var unreadCount: Int = 0

  // MARK: - Private state

  /// The opaque continuation the previous page handed back.
  private var cursor: String = ""

  // MARK: - Init

  /// - Parameter client: The client the inbox reads and writes through.
  init(client: DifferentRequestsClient) {
    self.client = client
  }

  // MARK: - Loading

  /// Reads the first page and the unread count, replacing everything held.
  ///
  /// Returns immediately when a read is already running. What is held stays on screen for the
  /// length of the read: a pull-to-refresh runs on the list's own task, and a list cleared at the
  /// start of a read would take that task with it.
  ///
  /// Both calls are one read. A page that arrives beside a count that did not is an inbox
  /// rendering a badge nobody vouches for, and the toolbar's Read All appears and disappears on
  /// that badge — so either both answered or the read failed.
  func load() async {
    if read.isReading { return }
    read = read.whileReading
    cursor = ""
    page = .more

    do {
      let answer = try await client.notifications(cursor: nil)
      let counted = try await client.unreadCount()
      unreadCount = Int(counted.unreadCount)
      read = ReadState(page: answer.notifications)
      cursor = answer.nextCursor
      page = PageState(nextCursor: answer.nextCursor)
    } catch {
      read = ReadState(readFailure: error)
      page = .done
    }
  }

  /// Appends the next page.
  ///
  /// Returns immediately when the server reported no further page, when one is already in flight,
  /// or when the whole inbox is being re-read.
  func loadMore() async {
    if page.isReading || page.isDone { return }
    if read.isReading { return }
    page = .reading

    do {
      let answer = try await client.notifications(cursor: cursor)
      read = read.appending(answer.notifications)
      cursor = answer.nextCursor
      page = PageState(nextCursor: answer.nextCursor)
    } catch {
      // The cursor is left where it was, so the retry asks for this page rather than skipping it.
      page = .failed(error)
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
    if write.isWriting { return }
    guard let current = read.held.first(where: { $0.id == notificationID }) else { return }
    let wasUnread = current.hasReadAt == false
    write = .writing(.markRead)

    do {
      let written = try await client.markRead(notificationID: notificationID).notification
      read = read.replacing(written, identifiedBy: { $0.id })
      if wasUnread, written.hasReadAt {
        unreadCount = max(unreadCount - 1, 0)
      }
      write = .idle
    } catch {
      write = .failed(WriteFailure(attempt: .markRead, error: error))
    }
  }

  /// Stamps everything read.
  ///
  /// A re-read follows, because the write answers with how many rows it touched rather than with
  /// the rows themselves, and each of those rows now carries a read stamp the inbox renders — as
  /// does the badge. Nothing marked means nothing changed, so there is nothing to re-read.
  func markAllRead() async {
    if write.isWriting { return }
    write = .writing(.markEverythingRead)

    let marked: Int32
    do {
      marked = try await client.markAllRead().markedCount
      write = .idle
    } catch {
      write = .failed(WriteFailure(attempt: .markEverythingRead, error: error))
      return
    }

    if marked == 0 { return }
    await load()
  }

  /// Puts away the notice about the last failed stamp.
  ///
  /// Acknowledgement, not repair: nothing was marked, and the dot that marks it is on screen
  /// either way.
  func acknowledgeWriteFailure() {
    write = .idle
  }
}
