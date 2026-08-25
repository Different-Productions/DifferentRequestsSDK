import DifferentRequestsProtos
import Foundation

/// Errors thrown by the DifferentRequests SDK.
///
/// The server's half of this is `DRApiError` from the contract, and ``api`` carries it
/// through unflattened: `code` is what a caller branches on, and it is the same value the
/// server sent rather than a re-derivation of it from an HTTP status.
public enum DifferentRequestsError: Error, Sendable, LocalizedError {
  /// The rpc requires an end-user session and none has been created. Raised before the
  /// call is sent, from the audience the contract declares for it.
  case notAuthenticated(DRRequestsServiceRPC)

  /// The server answered with an error. `error.reason` says which, and carries whatever that
  /// reason carries.
  case api(DRApiError)

  /// A failure response whose body was not a readable `DRApiError`, so there is nothing to
  /// branch on. Carries the bytes' length only — the content is not something a caller can
  /// act on and may be an infrastructure page rather than anything of ours.
  case unreadableError(byteCount: Int)

  /// The response body was not the message the rpc returns.
  case decodingFailed(DRRequestsServiceRPC, underlying: any Error)

  /// The response was the message the rpc returns and left out the part it is made of — a
  /// `GetConfigResponse` carrying no `AppConfig`.
  ///
  /// Its own case rather than a decode failure, because the bytes decoded. Its own case rather
  /// than a default-shaped answer, because every flag on an absent message reads as `false`: a
  /// server that said nothing would otherwise be read as a tenant who bought nothing.
  case incompleteResponse(DRRequestsServiceRPC)

  /// A network-level failure: no connection, timeout, TLS.
  case networkError(underlying: any Error)

  /// The response was not HTTP at all.
  case notAnHTTPResponse

  /// The configured base URL cannot have an rpc path resolved against it.
  case invalidBaseURL(URL)

  public var errorDescription: String? {
    switch self {
    case .notAuthenticated(let method):
      return "\(method.rawValue) requires an end-user session. Call createSession first."
    case .api(let error):
      // The contract states this message is written for a developer reading a log, never
      // for an end user, so it is surfaced here and not into UI copy.
      return error.refusalDescription
    case .unreadableError(let byteCount):
      return "The server returned a failure with \(byteCount) bytes that were not an ApiError."
    case .decodingFailed(let method, let underlying):
      return "Could not decode the response to \(method.rawValue): \(underlying.localizedDescription)"
    case .incompleteResponse(let method):
      return "\(method.rawValue) answered without the message its answer is made of."
    case .networkError(let underlying):
      return "Network error: \(underlying.localizedDescription)"
    case .notAnHTTPResponse:
      return "The transport returned a non-HTTP response."
    case .invalidBaseURL(let url):
      return "Not a usable API base URL: \(url.absoluteString)"
    }
  }

  /// Whether the server said the thing being read is not there.
  ///
  /// Distinct from every other failure because it is an answer rather than an outage: a link to
  /// a request that has since gone is not a connection to retry, and a surface that offers
  /// "Try Again" for it sends someone to retry a read that will never succeed.
  public var isNotFound: Bool {
    guard case .api(let error) = self, case .notFound = error.reason else {
      return false
    }
    return true
  }

  /// How long to wait before retrying, when the server said to wait.
  ///
  /// Reads the contract's own field, which lives on the rate limit itself — so there is no asking
  /// a failure of some other kind how long to wait, and no `Retry-After` header in this protocol
  /// to disagree with it either.
  public var retryAfterSeconds: Int? {
    guard case .api(let error) = self, case .rateLimited(let limited) = error.reason else {
      return nil
    }
    return Int(limited.retryAfterSeconds)
  }
}
