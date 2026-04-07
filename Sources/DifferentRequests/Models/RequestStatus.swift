import Foundation

/// Status of a feature request.
///
/// Requests move through these statuses as the team triages them.
public enum RequestStatus: String, Sendable {
  /// Newly submitted, awaiting triage.
  case open
  /// The team plans to work on this.
  case planned
  /// Currently being worked on.
  case inProgress = "in_progress"
  /// Released to users.
  case shipped
  /// The team decided not to implement this.
  case declined
}
