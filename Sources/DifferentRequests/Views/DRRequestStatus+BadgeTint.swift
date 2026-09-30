import DifferentRequestsProtos
import SwiftUI

/// What color a status takes on these surfaces.
///
/// The word it reads as is not here. `label` comes off the contract, because the server writes a
/// push alert about the same status this badge draws and two hand-written lists would eventually
/// disagree. A color has no second writer, so it stays an SDK decision.
///
/// Prefixed `badge`, so a member the contract adds to the enum later cannot collide with it.
extension DRRequestStatus {

  var badgeTint: Color {
    switch self {
    case .open: return .blue
    case .planned: return .purple
    case .inProgress: return .orange
    case .shipped: return .green
    case .declined: return .red
    case .duplicate: return .gray
    case .unspecified, .UNRECOGNIZED: return .secondary
    }
  }
}
