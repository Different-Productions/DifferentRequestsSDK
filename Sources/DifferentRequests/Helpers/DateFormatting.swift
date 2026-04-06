import Foundation

/// Formats dates for display in request views.
///
/// Uses relative formatting ("2 hours ago") for recent dates
/// and short date formatting for older items.
enum DateFormatting {

  /// The threshold after which dates are shown as absolute rather than relative.
  private static let relativeThreshold: TimeInterval = 7 * 24 * 60 * 60 // 7 days

  /// Format a date for display.
  ///
  /// - Parameter date: The date to format.
  /// - Returns: A human-readable string like "2 hours ago" or "Mar 15, 2026".
  static func formatted(_ date: Date) -> String {
    let elapsed = Date.now.timeIntervalSince(date)

    if elapsed < relativeThreshold {
      let formatter = RelativeDateTimeFormatter()
      formatter.unitsStyle = .abbreviated
      return formatter.localizedString(for: date, relativeTo: .now)
    }

    return date.formatted(.dateTime.month(.abbreviated).day().year())
  }
}
