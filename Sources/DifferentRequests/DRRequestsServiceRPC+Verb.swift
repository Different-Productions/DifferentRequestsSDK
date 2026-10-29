import DifferentRequestsProtos

extension DRRequestsServiceRPC {

  /// The verb this rpc is sent with, as the contract spells it.
  ///
  /// A verb with no spelling is refused rather than sent as something else. endpoint-gen will not
  /// emit an rpc whose route is incomplete, so this cannot happen against a contract this SDK was
  /// built with — and if it ever does, a call that goes nowhere is a better answer than a write
  /// delivered as a read of whatever its path points at.
  func spelledMethod() throws -> String {
    guard let spelled = method.token else {
      throw DifferentRequestsError(unspellableMethod: self)
    }
    return spelled
  }
}
