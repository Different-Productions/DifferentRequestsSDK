import DifferentRequestsProtos

extension VoteTile {

  /// The tile for `request`, taking no tap while `writing`.
  ///
  /// - Parameters:
  ///   - request: The request whose demand the tile shows.
  ///   - writing: Whether a write is already running on the surface the tile sits on.
  public init(request: DRFeatureRequest, writing: Bool) {
    self.init(request: request)
    self.writing = writing
  }

  /// The demand in `request` and the caller's vote in it, with no write running.
  ///
  /// - Parameter request: The request whose demand the tile shows.
  public init(request: DRFeatureRequest) {
    self.init()
    voteCount = request.voteCount
    voted = request.viewer.voted
  }
}
