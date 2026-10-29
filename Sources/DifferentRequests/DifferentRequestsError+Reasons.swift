import DifferentRequestsProtos
import Foundation

/// Every failure the SDK throws is built here, so each reason's sentence is written once.
extension DifferentRequestsError {

  /// A failure for `reason`, described by `message`.
  init(reason: DifferentRequestsFault, message: String) {
    self.init()
    self.reason = reason
    self.message = message
  }

  /// `rpc` needs an end-user session and none has been created.
  init(notAuthenticated rpc: DRRequestsServiceRPC) {
    self.init(
      reason: .notAuthenticated,
      message: "\(rpc.rawValue) requires an end-user session. Call createSession first."
    )
  }

  /// The server refused, and said why in `answer`.
  ///
  /// The contract states an `ApiError`'s message is written for a developer reading a log, never for
  /// an end user, so it is described here and never drawn on a screen.
  init(answer: DRApiError) {
    self.init(reason: .api, message: answer.refusalDescription())
    apiError = answer
  }

  /// A failure response of `byteCount` bytes that were not an `ApiError`. Only the length is kept:
  /// the content may be an infrastructure page rather than anything of ours.
  init(unreadableByteCount byteCount: Int) {
    self.init(
      reason: .unreadableError,
      message: "The server returned a failure with \(byteCount) bytes that were not an ApiError."
    )
  }

  /// The answer to `rpc` was not the message it returns.
  init(decodingFailed rpc: DRRequestsServiceRPC, underlying: any Error) {
    self.init(
      reason: .decodingFailed,
      message: "Could not decode the response to \(rpc.rawValue): \(underlying.localizedDescription)"
    )
  }

  /// The answer to `rpc` decoded and left out the message it is made of.
  init(incompleteResponse rpc: DRRequestsServiceRPC) {
    self.init(
      reason: .incompleteResponse,
      message: "\(rpc.rawValue) answered without the message its answer is made of."
    )
  }

  /// The session threw `failure` before any response arrived. A call that was called off is
  /// ``DifferentRequestsFault/canceled``, never a network failure.
  init(networkFailure failure: any Error) {
    if failure.isCancellation() {
      self.init(reason: .canceled, message: "Network error: \(failure.localizedDescription)")
    } else {
      self.init(reason: .networkError, message: "Network error: \(failure.localizedDescription)")
    }
  }

  /// `address` cannot have an rpc path resolved against it, or is not `https`.
  init(invalidBaseURL address: String) {
    self.init(reason: .invalidBaseURL, message: "Not a usable API base URL: \(address)")
  }

  /// `rpc` declares a verb the contract does not spell, so it was not sent.
  init(unspellableMethod rpc: DRRequestsServiceRPC) {
    self.init(
      reason: .unspellableMethod,
      message: "\(rpc.rawValue) declares a verb the contract does not spell, so it was not sent."
    )
  }
}
