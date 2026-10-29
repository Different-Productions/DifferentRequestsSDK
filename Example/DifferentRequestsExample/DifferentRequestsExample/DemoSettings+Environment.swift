import DifferentRequests
import Foundation

extension DemoSettings {

  /// What `environment` says, read once at launch.
  ///
  /// The app key comes from the environment rather than from an edited constant: this repository is
  /// public, and a placeholder a developer is invited to replace in a tracked file is a placeholder
  /// that eventually gets committed with a real value in it. Without one the app still builds and
  /// launches, and says what to set.
  ///
  /// A named endpoint that is not https is refused here rather than dialed: every call carries the
  /// app key, and over plain http it would cross the wire in the clear while appearing to work. It
  /// is not defaulted back to production either, since somebody who named a staging endpoint and
  /// silently got production would be reading the wrong board and believing it was theirs.
  init(environment: [String: String]) {
    self.init()
    if let key = DemoVariable.appKey.setting(in: environment) {
      appKey = key
      appKeySupplied = true
    } else {
      appKey = "YOUR_APP_KEY"
    }

    if let stated = DemoVariable.baseURL.setting(in: environment) {
      guard let url = URL(string: stated) else {
        preconditionFailure("The base URL variable is not a URL: \(stated)")
      }
      do {
        baseURL = try SecureBaseURL(url)
      } catch {
        preconditionFailure("The base URL variable must be https, and is: \(stated)")
      }
    } else {
      baseURL = SecureBaseURL(service: .production)
    }

    if let externalID = DemoVariable.externalID.setting(in: environment) {
      externalUserID = externalID
    } else {
      externalUserID = "demo-user"
    }

    if let name = DemoVariable.displayName.setting(in: environment) {
      displayName = name
    } else {
      displayName = "Demo User"
    }

    emptyBoard = EmptyBoard(
      symbol: "sparkles",
      title: "What would make this app better?",
      message: "Ask for it here, and anyone else who wants it can add a vote.",
      button: "Ask for it"
    )

    #if DEBUG
    pushEnvironment = .sandbox
    #else
    pushEnvironment = .production
    #endif
  }
}
