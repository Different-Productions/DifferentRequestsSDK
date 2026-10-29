import DifferentRequestsProtos
import Foundation

extension DifferentRequestsError {

  /// Why a read that threw this did not answer, in the terms the person on the screen can act on.
  func readTrouble() -> ReadTrouble {
    switch reason {
    case .api:
      return apiError.readTrouble()
    case .networkError, .canceled:
      var trouble = ReadTrouble()
      trouble.offline = Offline()
      return trouble
    case .unspecified, .notAuthenticated, .unreadableError, .decodingFailed, .incompleteResponse, .notAnHTTPResponse,
      .invalidBaseURL, .unspellableMethod, .UNRECOGNIZED:
      return ReadTrouble()
    }
  }
}
