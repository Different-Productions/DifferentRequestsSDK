import DifferentRequestsProtos
import Foundation

/// Backs the inbox: what a reader has been told, and how much of it they have not read.
///
/// Wraps `DifferentRequestsClient.notifications(cursor:)` with cursor pagination driven by the
/// response's `nextCursor`, which the server leaves empty on the last page. The first page
/// comes from `load()` and deeper pages from `loadMore()`; only one page is in flight at a
/// time, so a fast scroll cannot queue duplicate requests.
///
/// The unread count is read from `unreadCount()` rather than counted from the loaded page. The
/// page is one window on a list the same person may be reading on another device, and a badge
/// derived from it starts drifting the moment anything is marked read anywhere else.
///
/// Main-actor isolated and observable.
@MainActor
@Observable
final class InboxStore {

  // MARK: - Inputs

  /// The client every call goes through.
  let client: DifferentRequestsClient

  // MARK: - State

  /// Every notification loaded so far, in server order, with later pages appended.
  var notifications: [DRNotification] = []

  /// How many are unread, as the server counts them.
  var unreadCount: Int = 0

  /// `true` while the first page is being fetched.
  var isLoading: Bool = false

  /// `true` while a deeper page is being fetched.
  var isLoadingMore: Bool = false

  /// Whether the server reported another page. Starts `true` so the first `load()` is allowed.
  var hasMore: Bool = true

  /// Whether a first `load()` has finished, whether or not it succeeded. What separates "not
  /// read yet" from "read, and the inbox is empty".
  var hasLoaded: Bool = false

  /// The failure from the most recent read, cleared when a fresh `load()` starts.
  var loadError: Error?

  /// `true` while a read stamp is being written.
  var isWriting: Bool = false

  /// The failure from the most recent write, cleared when the next write starts.
  var writeError: Error?

  // MARK: - Private state

  /// The opaque continuation the previous page handed back.
  private var cursor: String = ""

  // MARK: - Init

  /// - Parameter client: The client the inbox reads and writes through.
  init(client: DifferentRequestsClient) {
    self.client = client
  }

  // MARK: - Loading

  /// Discards everything loaded and fetches the first page, then the unread count.
  ///
  /// Returns immediately when a first-page load is already running.
  func load() async {
    if isLoading { return }
    isLoading = true
    loadError = nil
    notifications = []
    cursor = ""
    hasMore = true
    defer {
      isLoading = false
      hasLoaded = true
    }
    await fetchPage()
    await refreshUnreadCount()
  }

  /// Appends the next page.
  ///
  /// Returns immediately when the server reported no further page, or when a first-page load or
  /// another append is already running.
  func loadMore() async {
    if !hasMore || isLoading || isLoadingMore { return }
    isLoadingMore = true
    defer { isLoadingMore = false }
    await fetchPage()
  }

  /// Fetches one page at the current cursor, appends it, and advances the cursor.
  ///
  /// A failure publishes `loadError` and leaves the cursor where it was, so the same page is
  /// retried rather than skipped.
  private func fetchPage() async {
    do {
      let requested: String? = cursor.isEmpty ? nil : cursor
      let page = try await client.notifications(cursor: requested)
      notifications.append(contentsOf: page.notifications)
      cursor = page.nextCursor
      hasMore = !page.nextCursor.isEmpty
    } catch {
      loadError = error
    }
  }

  /// Re-reads the badge from the server.
  private func refreshUnreadCount() async {
    do {
      let answer = try await client.unreadCount()
      unreadCount = Int(answer.unreadCount)
    } catch {
      loadError = error
    }
  }

  // MARK: - Writes

  /// Stamps one notification read.
  ///
  /// The row is found again by id after the write answers rather than by an index taken before
  /// it: a reload can replace the array while the call is suspended, and an index from before
  /// the suspension would then address a different row or none at all. A row that is gone is
  /// not an error — it was read, which is what was asked for.
  func markRead(notificationID: String) async {
    if isWriting { return }
    isWriting = true
    writeError = nil
    defer { isWriting = false }

    do {
      let written = try await client.markRead(notificationID: notificationID)
      let read = written.notification
      if let index = notifications.firstIndex(where: { $0.id == read.id }) {
        notifications[index] = read
      }
    } catch {
      writeError = error
      return
    }
    await refreshUnreadCount()
  }

  /// Stamps everything read.
  ///
  /// A reload follows, because the write answers with how many rows it touched rather than with
  /// the rows themselves, and each of those rows now carries a read stamp the inbox renders.
  /// Nothing marked means nothing changed, so there is nothing to re-read.
  func markAllRead() async {
    if isWriting { return }
    isWriting = true
    writeError = nil
    defer { isWriting = false }

    do {
      let written = try await client.markAllRead()
      if written.markedCount == 0 { return }
    } catch {
      writeError = error
      return
    }
    await load()
  }
}
