import Foundation

/// One status column of the public roadmap board (Planned, In Progress, or Shipped).
///
/// ``requests`` preserves the server's ordering — pinned items first, then by
/// manual ``Request/roadmapOrder``, then most recent first. Do not re-sort.
public struct RoadmapColumn: Sendable, Identifiable {
  /// The status this column represents.
  public let status: RequestStatus
  /// Requests in this column, in server order.
  public let requests: [Request]

  /// Identifies the column by its status — a roadmap has at most one column per status.
  public var id: RequestStatus { status }
}
