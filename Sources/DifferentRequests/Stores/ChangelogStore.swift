import DifferentRequestsProtos
import Foundation

/// Backs the changelog: published notes about what shipped, newest first.
///
/// Wraps `DifferentRequestsClient.changelog(cursor:)` with cursor pagination driven by the
/// response's `nextCursor`, which the server leaves empty on the last page. The first page comes
/// from `load()` and deeper pages from `loadMore()`; only one page is in flight at a time, so a
/// fast scroll cannot queue duplicate requests.
///
/// Drafts never arrive here — presence of a published stamp is what makes an entry public, and
/// that is decided by the server — so there is nothing to filter on the way in.
///
/// Whether this app publishes release notes at all is asked first. `ListChangelog` is one of
/// exactly two rpcs the server refuses on plan, and an app that does not have this surface would
/// get a refusal written for its developer in place of a screen written for its reader.
///
/// Nothing is written from this surface, so there is no write state to hold.
///
/// Main-actor isolated and observable.
@MainActor
@Observable
final class ChangelogStore {

  // MARK: - Inputs

  /// The client every call goes through.
  let client: DifferentRequestsClient

  // MARK: - State

  /// Whether this app publishes release notes, and how far the asking got.
  var plan: PlanState = .unread

  /// The changelog itself: where its read got to, and the entries it found.
  var read: ReadState<[DRChangelogEntry]> = .unread

  /// Whether there is another page, and what became of the last attempt at one.
  var page: PageState = .more

  // MARK: - Private state

  /// The opaque continuation the previous page handed back.
  private var cursor: String = ""

  // MARK: - Init

  /// - Parameter client: The client the changelog reads through.
  init(client: DifferentRequestsClient) {
    self.client = client
  }

  // MARK: - Loading

  /// Asks what this app includes, then reads the first page if it publishes release notes.
  ///
  /// Returns immediately when a read is already running. Also the retry behind both failures the
  /// screen can show: the configuration is asked for again when the last ask did not answer, and
  /// asked for once when it did.
  func load() async {
    if read.isReading { return }

    await readPlan()
    if plan.isIncluded {
      await readFirstPage()
    }
  }

  /// Asks whether this app publishes release notes.
  ///
  /// The client answers a second ask from the first read, so the cost of every gated surface
  /// asking for itself is one round trip for all of them.
  private func readPlan() async {
    if plan.needsReading == false { return }
    plan = .reading

    do {
      let answer = try await client.config()
      plan = PlanState(surface: .changelog, response: answer)
    } catch {
      plan = .failed(error)
    }
  }

  /// Reads the first page, replacing everything held.
  ///
  /// What is held stays on screen for the length of the read: a pull-to-refresh runs on the list's
  /// own task, and a list cleared at the start of a read would take that task with it.
  private func readFirstPage() async {
    read = read.whileReading
    cursor = ""
    page = .more

    do {
      let answer = try await client.changelog(cursor: nil)
      read = ReadState(page: answer.entries)
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
  /// or when the whole changelog is being re-read.
  func loadMore() async {
    if page.isReading || page.isDone { return }
    if read.isReading { return }
    page = .reading

    do {
      let answer = try await client.changelog(cursor: cursor)
      read = read.appending(answer.entries)
      cursor = answer.nextCursor
      page = PageState(nextCursor: answer.nextCursor)
    } catch {
      // The cursor is left where it was, so the retry asks for this page rather than skipping it.
      page = .failed(error)
    }
  }
}
