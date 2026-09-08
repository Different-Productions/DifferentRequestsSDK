import Foundation

/// What happened the last time this client reached the server.
///
/// Held so `describeIntegration()` can answer the question a developer looking at an empty board
/// actually has, which is whether anything left the device at all.
///
/// Two cases rather than an optional, because **`none` is the most useful answer this can give**:
/// an app that has never called says so, and that one line separates "not wired up" from
/// "wired up and refused".
public enum LastCall: Sendable, Equatable {
  case none

  /// `outcome` is short and for a person: `200`, `401 — no app key`, `network — timed out`.
  case made(rpc: String, outcome: String, at: Date)
}
