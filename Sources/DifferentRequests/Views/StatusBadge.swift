import DifferentRequestsProtos
import SwiftUI

/// Where a request sits in the tenant's process, as a capsule.
///
/// ```swift
/// StatusBadge(state: request.state)
/// ```
///
/// Takes the state rather than a status beside it, so the badge and whatever is drawn underneath it
/// read one value. A badge saying "Shipped" over a refusal was a screen this took two arguments to
/// produce.
public struct StatusBadge: View {

  private static let fillOpacity: Double = 0.12
  private static let horizontalPadding: CGFloat = 10
  private static let verticalPadding: CGFloat = 2

  /// The state to render. Absent for a request written before the state existed, or by a server
  /// newer than this build.
  public let state: DRFeatureRequest.OneOf_State?

  /// - Parameter state: The state to render.
  public init(state: DRFeatureRequest.OneOf_State?) {
    self.state = state
    self.tag = nil
  }

  /// A status with no request behind it — a roadmap column heading, which *is* a status group and
  /// has no state to disagree with.
  ///
  /// Never reach for this to label a request. A request has a state, and taking the tag separately
  /// is what let a badge say "Shipped" over a refusal.
  public init(groupedBy status: DRRequestStatus) {
    self.state = nil
    self.tag = status
  }

  private let tag: DRRequestStatus?

  private var status: DRRequestStatus {
    if let tag {
      return tag
    }
    switch state {
    case .open: return .open
    case .planned: return .planned
    case .inProgress: return .inProgress
    case .shipped: return .shipped
    case .declined: return .declined
    case .merged: return .merged
    case .none: return .unspecified
    }
  }

  public var body: some View {
    Text(status.badgeLabel)
      .font(.caption)
      .fontWeight(.semibold)
      .padding(.horizontal, Self.horizontalPadding)
      .padding(.vertical, Self.verticalPadding)
      .foregroundStyle(status.badgeTint)
      .background(status.badgeTint.opacity(Self.fillOpacity), in: Capsule())
  }
}

// MARK: - Presentation

/// How a status reads and colours on these surfaces.
///
/// Prefixed rather than named `label` and `tint`, so a member the contract adds to the enum later
/// cannot collide with one of these and silently change what a badge says.
extension DRRequestStatus {

  /// A status this SDK version does not know reads as unknown rather than being hidden: an app
  /// built before a status existed should say it cannot name the state, not imply there is none.
  var badgeLabel: String {
    switch self {
    case .open: return "Open"
    case .planned: return "Planned"
    case .inProgress: return "In Progress"
    case .shipped: return "Shipped"
    case .declined: return "Declined"
    case .merged: return "Merged"
    case .unspecified, .UNRECOGNIZED: return "Unknown"
    }
  }

  var badgeTint: Color {
    switch self {
    case .open: return .blue
    case .planned: return .purple
    case .inProgress: return .orange
    case .shipped: return .green
    case .declined: return .red
    case .merged: return .gray
    case .unspecified, .UNRECOGNIZED: return .secondary
    }
  }
}
