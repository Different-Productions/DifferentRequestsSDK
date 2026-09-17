import DifferentRequests

/// Where the example app is in reading what it offers.
///
/// Signing a person in is not one of these. A sign-in that the server refuses is the integration's
/// to fix, not something to draw: the board reads with the app key alone, and the SDK offers no
/// control that acts for a person until one is signed in.
enum LaunchPhase {

  /// No app key was supplied, so there is nothing to read.
  case unconfigured

  case reading

  /// What this app offers, which is what decides its rows.
  case ready(DRAppConfig)

  /// The config could not be read, so which screens exist is unknown. What the server said is in
  /// the log.
  case configUnreadable
}
