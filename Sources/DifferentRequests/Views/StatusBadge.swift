import DifferentRequestsProtos
import SwiftUI

/// Where a request sits in the tenant's process, as a symbol and a word.
///
/// ```swift
/// StatusBadge(state: request.state)
/// ```
///
/// Takes the state rather than a status beside it, so the badge and whatever is drawn underneath it
/// read one value.
public struct StatusBadge: View {

  /// The state to render. Absent for a request written before the state existed, or by a server
  /// newer than this build.
  public let state: DRFeatureRequest.OneOf_State?

  /// A status with no request behind it, or nil when ``state`` is what is drawn.
  private let tag: DRRequestStatus?

  /// - Parameter state: The state to render.
  public init(state: DRFeatureRequest.OneOf_State?) {
    self.state = state
    self.tag = nil
  }

  /// A status with no request behind it: a roadmap column heading, which is a status group and has
  /// no state to disagree with. Never use this to label a request, which has a state.
  public init(groupedBy status: DRRequestStatus) {
    self.state = nil
    self.tag = status
  }

  public var body: some View {
    switch shownStatus() {
    case .open:
      StatusMark(word: DRRequestStatus.open.localizedLabel, symbol: "circle")
    case .planned:
      StatusMark(word: DRRequestStatus.planned.localizedLabel, symbol: "calendar")
    case .inProgress:
      StatusMark(word: DRRequestStatus.inProgress.localizedLabel, symbol: "circle.lefthalf.filled")
    case .shipped:
      StatusMark(word: DRRequestStatus.shipped.localizedLabel, symbol: "checkmark.circle.fill")
    case .declined:
      StatusMark(word: DRRequestStatus.declined.localizedLabel, symbol: "xmark.circle")
    case .duplicate:
      StatusMark(word: DRRequestStatus.duplicate.localizedLabel, symbol: "arrow.triangle.merge")
    case .unspecified, .UNRECOGNIZED:
      StatusMark(word: DRRequestStatus.unspecified.localizedLabel, symbol: "questionmark.circle")
    }
  }

  /// The heading's status when there is one, and otherwise the status the request's state names.
  private func shownStatus() -> DRRequestStatus {
    if let tag {
      return tag
    }
    switch state {
    case .open: return .open
    case .planned: return .planned
    case .inProgress: return .inProgress
    case .shipped: return .shipped
    case .declined: return .declined
    case .duplicate: return .duplicate
    case .none: return .unspecified
    }
  }
}
