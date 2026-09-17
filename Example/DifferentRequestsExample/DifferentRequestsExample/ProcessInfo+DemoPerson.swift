import Foundation

extension ProcessInfo {
  /// Who the example signs in as: the environment's identifier, or ``DemoConfig/externalUserID``.
  var demoExternalUserID: String {
    if let named = environment[DemoConfig.externalUserIDEnvironmentVariable], named.isEmpty == false {
      return named
    }
    return DemoConfig.externalUserID
  }

  /// The name they sign in with: the environment's, or ``DemoConfig/displayName``.
  var demoDisplayName: String {
    if let named = environment[DemoConfig.displayNameEnvironmentVariable], named.isEmpty == false {
      return named
    }
    return DemoConfig.displayName
  }
}
