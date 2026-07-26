import DifferentRequestsProtos
import SwiftUI

/// Where a request sits in the tenant's process, as a capsule.
///
/// ```swift
/// StatusBadge(status: request.status)
/// ```
public struct StatusBadge: View {

  private static let fillOpacity: Double = 0.12
  private static let horizontalPadding: CGFloat = 10
  private static let verticalPadding: CGFloat = 2

  /// The status to render.
  public let status: DRRequestStatus

  /// - Parameter status: The status to render.
  public init(status: DRRequestStatus) {
    self.status = status
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
