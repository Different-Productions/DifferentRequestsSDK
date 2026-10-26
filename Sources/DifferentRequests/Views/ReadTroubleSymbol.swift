import SwiftUI

/// The picture over a screen that could not be read: no connection has its own, and every other
/// kind of trouble shares one.
struct ReadTroubleSymbol: View {

  /// Why the read did not answer.
  let trouble: ReadTrouble

  var body: some View {
    switch trouble {
    case .offline:
      Image(systemName: "wifi.slash")
    case .tooManyTries, .other:
      Image(systemName: "exclamationmark.triangle")
    }
  }
}
