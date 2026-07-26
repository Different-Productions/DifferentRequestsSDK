import DifferentRequestsProtos
import Foundation

/// Errors thrown by the DifferentRequests SDK.
///
/// The server's half of this is `ApiError` from the contract, and ``api`` carries it
/// through unflattened: `code` is what a caller branches on, and it is the same value the
/// server sent rather than a re-derivation of it from an HTTP status.
public enum DifferentRequestsError: Error, Sendable, LocalizedError {
  /// The rpc requires an end-user session and none has been created. Raised before the
  /// call is sent, from the audience the contract declares for it.
  case notAuthenticated(RequestsServiceMethod)

  /// The server answered with an error. `error.code` says which.
  case api(ApiError)

  /// A failure response whose body was not a readable `ApiError`, so there is nothing to
  /// branch on. Carries the bytes' length only — the content is not something a caller can
  /// act on and may be an infrastructure page rather than anything of ours.
  case unreadableError(byteCount: Int)

  /// The response body was not the message the rpc returns.
  case decodingFailed(RequestsServiceMethod, underlying: any Error)

  /// A network-level failure: no connection, timeout, TLS.
  case networkError(underlying: any Error)

  /// The response was not HTTP at all.
  case notAnHTTPResponse

  /// The configured base URL cannot have an rpc path resolved against it.
  case invalidBaseURL(URL)

  public var errorDescription: String? {
    switch self {
    case .notAuthenticated(let method):
      return "\(method.path) requires an end-user session. Call createSession first."
    case .api(let error):
      // The contract states this message is written for a developer reading a log, never
      // for an end user, so it is surfaced here and not into UI copy.
      return "\(error.code): \(error.message)"
    case .unreadableError(let byteCount):
      return "The server returned a failure with \(byteCount) bytes that were not an ApiError."
    case .decodingFailed(let method, let underlying):
      return "Could not decode the response to \(method.path): \(underlying.localizedDescription)"
    case .networkError(let underlying):
      return "Network error: \(underlying.localizedDescription)"
    case .notAnHTTPResponse:
      return "The transport returned a non-HTTP response."
    case .invalidBaseURL(let url):
      return "Not a usable API base URL: \(url.absoluteString)"
    }
  }

  /// How long to wait before retrying, when the server said to wait.
  ///
  /// Reads the contract's own field. There is no `Retry-After` header in this protocol to
  /// disagree with it.
  public var retryAfterSeconds: Int? {
    guard case .api(let error) = self, error.code == .rateLimited else {
      return nil
    }
    return Int(error.retryAfterSeconds)
  }
}
