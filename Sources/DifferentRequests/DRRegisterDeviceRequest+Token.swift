import DifferentRequestsProtos
import Foundation

extension DRRegisterDeviceRequest {

  /// The registration for the raw APNs token `tokenData`, minted in `environment`.
  ///
  /// APNs tokens are conventionally written as lowercase hex, so callers hand over the raw `Data`
  /// and never do this themselves.
  init(tokenData: Data, environment: DRPushEnvironment) {
    self.init()
    token = tokenData.map { byte in
      String(format: "%02x", byte)
    }.joined()
    self.environment = environment
  }
}
