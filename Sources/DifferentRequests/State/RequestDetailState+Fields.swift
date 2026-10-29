import DifferentRequestsProtos

extension RequestDetailState {

  /// The screen for `requestID`, before anything about it has been read.
  init(requestID: String) {
    self.init()
    self.requestID = requestID
  }
}
