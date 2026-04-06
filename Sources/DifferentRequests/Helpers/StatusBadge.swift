import SwiftUI

/// A capsule-shaped badge displaying a request's status.
///
/// Colors match the DifferentRequests console design tokens.
///
/// ```swift
/// StatusBadge(status: .planned)
/// ```
public struct StatusBadge: View {

  /// The request status to display.
  public let status: RequestStatus

  /// Creates a status badge.
  /// - Parameter status: The status to display.
  public init(status: RequestStatus) {
    self.status = status
  }

  public var body: some View {
    Text(status.label)
      .font(.caption)
      .fontWeight(.semibold)
      .padding(.horizontal, 10)
      .padding(.vertical, 2)
      .foregroundStyle(status.color)
      .background(status.color.opacity(0.12), in: Capsule())
  }
}

// MARK: - RequestStatus Display

extension RequestStatus {

  /// Human-readable label for display.
  var label: String {
    switch self {
    case .open: "Open"
    case .planned: "Planned"
    case .inProgress: "In progress"
    case .shipped: "Shipped"
    case .declined: "Declined"
    }
  }

  /// Display color for the status.
  var color: Color {
    switch self {
    case .open: .blue
    case .planned: .purple
    case .inProgress: .orange
    case .shipped: .green
    case .declined: .red
    }
  }
}

// MARK: - Preview

#Preview("All Statuses") {
  HStack(spacing: 8) {
    StatusBadge(status: .open)
    StatusBadge(status: .planned)
    StatusBadge(status: .inProgress)
    StatusBadge(status: .shipped)
    StatusBadge(status: .declined)
  }
  .padding()
}
