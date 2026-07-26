import DifferentRequestsProtos
import Foundation

/// Backs the submit sheet: the request being written, and the one write that files it.
///
/// The draft lives here rather than in the sheet so a redraw cannot lose what someone typed, and
/// so a blank title is refused before it becomes a round trip.
///
/// The title is seeded at construction from what the reader searched for. Reaching this sheet
/// means the board was searched and did not answer, so that text is the request — retyping it
/// would be the price of having looked first.
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
  var title: String

  /// The detail, which the server accepts empty.
  var body: String = ""

  /// `true` while the request is being written.
  var isSubmitting: Bool = false

  /// What the server filed, once it has answered. It arrives with the author's own vote already
  /// counted, and its presence is what tells a presenter the sheet is done.
  var submitted: DRFeatureRequest?

  /// The failure from the most recent attempt, cleared when the next one starts.
  var submitError: Error?

  // MARK: - Init

  /// - Parameters:
  ///   - client: The client the write goes through.
  ///   - title: What the reader searched for, as the opening title.
  init(client: DifferentRequestsClient, title: String) {
    self.client = client
    self.title = title
  }

  // MARK: - Writing

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
    if isSubmitting { return }
    let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmedTitle.isEmpty { return }
    isSubmitting = true
    submitError = nil
    defer { isSubmitting = false }

    do {
      let written = try await client.submit(
        title: trimmedTitle,
        body: body.trimmingCharacters(in: .whitespacesAndNewlines)
      )
      submitted = written.request
    } catch {
      submitError = error
    }
  }
}
