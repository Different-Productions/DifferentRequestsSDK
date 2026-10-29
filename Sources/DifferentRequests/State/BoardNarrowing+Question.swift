import DifferentRequestsProtos

extension BoardNarrowing {

  /// What a question is holding back, read off the contract's own request.
  init(question: DRListRequestsRequest) {
    switch (question.query.isEmpty, question.statuses.isEmpty) {
    case (true, true):
      self = .nothing
    case (false, true):
      self = .query
    case (true, false):
      self = .statuses
    case (false, false):
      self = .queryAndStatuses
    }
  }
}
