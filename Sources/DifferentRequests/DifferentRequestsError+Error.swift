import Foundation

/// What every call through the SDK throws.
///
/// ``reason`` is what a caller branches on. When it is ``DifferentRequestsFault/api``, ``apiError``
/// holds the server's own `DRApiError`, unflattened: the same value the server sent rather than a
/// re-derivation of it from an HTTP status. ``message`` is written for a developer reading a log,
/// never for the person using the app.
extension DifferentRequestsError: Error, LocalizedError {

  public var errorDescription: String? {
    message
  }
}
