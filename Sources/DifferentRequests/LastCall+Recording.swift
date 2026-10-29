import DifferentRequestsProtos
import Foundation
import SwiftProtobuf

/// What happened the last time a client reached the server, read from
/// ``DifferentRequestsClient/lastCall``.
///
/// Recorded the way an access log records a request: the rpc's ``method`` and path template in
/// ``route``, the HTTP ``status``, the ``failure`` when there was one, and the time in ``at``. A
/// client that has never called has no ``at``, so ``hasAt`` is false, and that one fact separates
/// "not wired up" from "wired up and refused".
extension LastCall {

  /// A call to `rpc` that answered `status` with the message the rpc returns, just now.
  init(rpc: DRRequestsServiceRPC, status: Int32) {
    self.init()
    method = rpc.method
    route = rpc.template
    self.status = status
    at = Google_Protobuf_Timestamp(date: Date())
  }

  /// A call to `rpc` that ended in `failure` just now, after an answer of `status`, or zero when no
  /// HTTP answer came back.
  init(rpc: DRRequestsServiceRPC, status: Int32, failure: DifferentRequestsError) {
    self.init(rpc: rpc, status: status)
    self.failure = failure
  }
}
