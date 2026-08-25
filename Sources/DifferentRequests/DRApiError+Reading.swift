import DifferentRequestsProtos

extension DRApiError {
  /// How a refusal reads to a developer: the reason's own name, and the message beside it.
  ///
  /// The name comes from the generated `fieldName`, so this knows nothing about which reasons
  /// exist and a reason added to the contract needs no edit here. What it adds is the one thing
  /// the generated table cannot: what to say when there is no reason at all, which is a server
  /// newer than this build of the SDK.
  ///
  /// The contract states the message is written for whoever is debugging and never for an end
  /// user, so this is surfaced into `errorDescription` and never into UI copy.
  var refusalDescription: String {
    if let reason {
      return "\(reason.fieldName): \(message)"
    }
    return "a reason this build does not know: \(message)"
  }
}
