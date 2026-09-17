import Foundation

extension Data {
  /// These bytes spelled URL-safe base64, unpadded — the spelling a proof's signature crosses the
  /// wire in.
  var urlSafeBase64String: String {
    base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }
}
