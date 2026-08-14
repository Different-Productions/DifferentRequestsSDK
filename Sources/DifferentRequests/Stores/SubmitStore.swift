import DifferentRequestsProtos
import Foundation

/// Backs the submit sheet: the request being written, and the one write that files it.
///
/// The draft lives here rather than in the sheet so a redraw cannot lose what someone typed, and
/// so a blank title is refused before it becomes a round trip.
///
/// One store, opened again for each request rather than built again. ``begin(title:)`` is what
/// starts a composer and the only thing that clears the last one: the sheet showing it is
/// dismissed and re-presented, and a store rebuilt alongside it would be a draft lost to a
/// redraw.
///
/// Nothing is read from this surface, so there is no read state to hold — only the write.
///
/// Main-actor isolated and observable.
@MainActor
@Observable
final class SubmitStore {

  // MARK: - Inputs

  /// The client the write goes through.
  let client: DifferentRequestsClient

  // MARK: - State

  /// What is being asked for, in one line.
  var title: String = ""

  /// The detail, which the server accepts empty.
  var body: String = ""

  /// What the filing is doing, or what it did instead.
  var write: WriteState = .idle

  /// What the server filed, once it has answered. It arrives with the author's own vote already
  /// counted, and its presence is what tells a presenter the sheet is done.
  var submitted: DRFeatureRequest?

  // MARK: - Init

  /// - Parameter client: The client the write goes through.
  init(client: DifferentRequestsClient) {
    self.client = client
  }

  // MARK: - Writing

  /// Starts a request, seeded with what the board was searched for.
  ///
  /// Reaching a composer from a search means the search did not answer, so that text is already
  /// the request — retyping it would be the price of having looked first. From an unsearched
  /// board the title arrives empty, which is the same rule with nothing to carry.
  ///
  /// Everything else is cleared, `submitted` included: it is presence, not a flag, and a composer
  /// opened while it still held the last filed request would look finished before anything was
  /// typed.
  func begin(title: String) {
    self.title = title
    body = ""
    submitted = nil
    write = .idle
  }

  /// Whether there is enough to file. A blank title is refused by the server, so it is refused
  /// here instead of sent.
  var canSubmit: Bool {
    title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
  }

  /// Files the request.
  ///
  /// Returns immediately when a write is already running: a second tap on a slow network would
  /// otherwise file the duplicate this whole flow exists to prevent.
  func submit() async {
    if write.isWriting { return }
    let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmedTitle.isEmpty { return }
    write = .writing(.fileRequest)

    do {
      let written = try await client.submit(
        title: trimmedTitle,
        body: body.trimmingCharacters(in: .whitespacesAndNewlines)
      )
      submitted = written.request
      write = .idle
    } catch {
      write = .failed(WriteFailure(attempt: .fileRequest, error: error))
    }
  }

  /// Puts away the notice about the last failed filing.
  ///
  /// Acknowledgement, not repair: nothing was filed, and Submit is still in the bar with
  /// everything typed still under it.
  func acknowledgeWriteFailure() {
    write = .idle
  }
}
