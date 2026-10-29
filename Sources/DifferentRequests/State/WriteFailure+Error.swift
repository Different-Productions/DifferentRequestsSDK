import DifferentRequestsProtos

extension WriteFailure {

  /// The write `attempt` that threw `error`, holding the server's answer when there was one.
  init(attempt: WriteAttempt, error: any Error) {
    self.init()
    self.attempt = attempt
    if let known = error as? DifferentRequestsError {
      switch known.reason {
      case .api:
        self.answer = known.apiError
      case .unspecified, .notAuthenticated, .unreadableError, .decodingFailed, .incompleteResponse, .networkError, .canceled,
        .notAnHTTPResponse, .invalidBaseURL, .unspellableMethod, .UNRECOGNIZED:
        clearAnswer()
      }
    }
  }
}
