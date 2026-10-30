import Foundation

extension SDKClient {

  /// This build of the package, on the system `process` runs on.
  ///
  /// The version is the one place the release is written down, because SwiftPM gives a package no
  /// way to read its own tag at runtime. The release workflow reads it from the line below.
  init(process: ProcessInfo) {
    self.init()
    version = "0.16.1"
    #if os(iOS)
    platform = "iOS"
    #elseif os(macOS)
    platform = "macOS"
    #elseif os(tvOS)
    platform = "tvOS"
    #elseif os(watchOS)
    platform = "watchOS"
    #elseif os(visionOS)
    platform = "visionOS"
    #else
    platform = "unknown"
    #endif
    let system = process.operatingSystemVersion
    osVersion = "\(system.majorVersion).\(system.minorVersion)"
  }

  /// The value of the `X-DR-Client` header, shaped as the contract describes it.
  func header() -> String {
    "differentrequests-swift/\(version) (\(platform) \(osVersion))"
  }
}
