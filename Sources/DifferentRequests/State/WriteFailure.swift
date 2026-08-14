import Foundation

/// A write that did not land: which one it was, and what came back instead.
///
/// One value rather than two properties, so that a view binds the whole of a failure in a single
/// pattern. Binding two would mean naming the error at every site that only wants the sentence,
/// and an unused binding is a warning waiting to be silenced with an underscore.
struct WriteFailure {

  /// Which write it was.
  let attempt: WriteAttempt

  /// What the call threw, for whoever is debugging. A host app can cast it to
  /// ``DifferentRequestsError`` and branch on the server's own code.
  let error: any Error

  /// What the person who made the write is told. Written against what they did, never derived
  /// from ``error`` — the contract states the server's message may name internals.
  var message: String {
    attempt.failureMessage
  }
}
