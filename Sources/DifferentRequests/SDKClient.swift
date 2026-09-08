import Foundation

/// What this package tells the server it is, on every rpc.
///
/// A released SDK carries its base URL in the binary, so more than one hostname is live in the wild
/// at once and a failing request cannot otherwise say which build sent it. This is what lets the
/// answer be "you are on 0.4.2, which dials the old name" rather than a support thread.
///
/// **It names the library and never the person.** No identifier, nothing that survives an install,
/// nothing a second request could be joined to a first by — the platform and its version are the
/// same for everyone running the same OS.
enum SDKClient {
  /// The released version of this package.
  ///
  /// The one place it is written down, and it is written down rather than derived because SwiftPM
  /// gives a package no way to read its own tag at runtime. **Bump this in the release commit**;
  /// a version that lags its tag is worse than none, because it is believed.
  static let version = "0.9.0"

  /// The value of the `X-DR-Client` header, shaped as the contract describes it.
  static let header = "differentrequests-swift/\(version) (\(platform) \(osVersion))"

  private static var platform: String {
    #if os(iOS)
    return "iOS"
    #elseif os(macOS)
    return "macOS"
    #elseif os(tvOS)
    return "tvOS"
    #elseif os(watchOS)
    return "watchOS"
    #elseif os(visionOS)
    return "visionOS"
    #else
    return "unknown"
    #endif
  }

  private static var osVersion: String {
    let v = ProcessInfo.processInfo.operatingSystemVersion
    return "\(v.majorVersion).\(v.minorVersion)"
  }
}
