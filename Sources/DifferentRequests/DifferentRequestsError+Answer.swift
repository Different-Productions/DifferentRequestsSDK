import DifferentRequestsProtos

/// What a caller asks of a failure, read off the server's own `DRApiError` and never off a status
/// code. A failure the server did not answer holds no `apiError`, so it answers no to each.
extension DifferentRequestsError {

  /// Whether the server said the thing being read is not there.
  ///
  /// An answer rather than an outage: a link to a request that has since gone is not a connection to
  /// retry, and a surface that offers "Try again" for it sends someone to retry a read that will
  /// never succeed.
  public func isNotFound() -> Bool {
    switch apiError.reason {
    case .notFound:
      return true
    case .invalidArgument, .malformed, .failedPrecondition, .conflict, .permissionDenied, .planRequired, .unauthenticated,
      .rateLimited, .internalFailure, .none:
      return false
    }
  }

  /// Whether the server refused what was written, rather than failing to receive it.
  ///
  /// A call that did not arrive is worth sending again, and a call the server read and refused is
  /// not: the same words refused once are refused every time. Rate limiting is not one of these. It
  /// passes with time, and carries its own wait in ``retryAfterSeconds()``.
  public func isRefusal() -> Bool {
    switch apiError.reason {
    case .invalidArgument, .malformed, .failedPrecondition, .conflict, .permissionDenied, .planRequired, .notFound:
      return true
    case .unauthenticated, .rateLimited, .internalFailure, .none:
      return false
    }
  }

  /// How long to wait before retrying, when the server said to wait. Nil for any other failure.
  ///
  /// Read from the contract's own field on the rate limit, so there is no `Retry-After` header to
  /// disagree with it.
  public func retryAfterSeconds() -> Int? {
    switch apiError.reason {
    case .rateLimited(let limited):
      return Int(limited.retryAfterSeconds)
    case .invalidArgument, .malformed, .failedPrecondition, .conflict, .permissionDenied, .planRequired, .notFound,
      .unauthenticated, .internalFailure, .none:
      return nil
    }
  }

  /// Whether the call was called off rather than failed.
  func isCanceled() -> Bool {
    switch reason {
    case .canceled:
      return true
    case .unspecified, .notAuthenticated, .api, .unreadableError, .decodingFailed, .incompleteResponse, .networkError,
      .notAnHTTPResponse, .invalidBaseURL, .unspellableMethod, .UNRECOGNIZED:
      return false
    }
  }
}
