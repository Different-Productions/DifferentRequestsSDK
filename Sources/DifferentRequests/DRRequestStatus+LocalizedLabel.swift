import DifferentRequestsProtos
import Foundation

extension DRRequestStatus {
  /// The status in the phone's language. The contract's `label` is the English, and each case here
  /// says the same word; a case the contract adds breaks this switch until it has a translation.
  var localizedLabel: String {
    switch self {
    case .open: return String(localized: "Waiting", bundle: .module, comment: "Status of a request nobody has answered yet")
    case .planned: return String(localized: "Planned", bundle: .module, comment: "Status of a request the team plans to build")
    case .inProgress: return String(localized: "In progress", bundle: .module, comment: "Status of a request being built")
    case .shipped: return String(localized: "Shipped", bundle: .module, comment: "Status of a request that has been released")
    case .declined: return String(localized: "Declined", bundle: .module, comment: "Status of a request the team won't build")
    case .duplicate: return String(localized: "Duplicate", bundle: .module, comment: "Status of a request merged into another")
    case .unspecified, .UNRECOGNIZED: return String(localized: "Unknown", bundle: .module, comment: "A status this version has no name for")
    }
  }

  /// The inbox headline for a request that moved into this status: "Now planned". One whole phrase
  /// per status, so a language can order the words its own way.
  var movedHeadline: String {
    switch self {
    case .open: return String(localized: "Now waiting", bundle: .module, comment: "Inbox headline: the request moved back to waiting")
    case .planned: return String(localized: "Now planned", bundle: .module, comment: "Inbox headline: the request is now planned")
    case .inProgress: return String(localized: "Now in progress", bundle: .module, comment: "Inbox headline: the request is now being built")
    case .shipped: return String(localized: "Now shipped", bundle: .module, comment: "Inbox headline: the request has been released")
    case .declined: return String(localized: "Now declined", bundle: .module, comment: "Inbox headline: the team won't build the request")
    case .duplicate: return String(localized: "Already asked for", bundle: .module, comment: "Inbox headline: the request was merged into another")
    case .unspecified, .UNRECOGNIZED: return String(localized: "Something changed", bundle: .module, comment: "Inbox headline for news this version can't name")
    }
  }
}
