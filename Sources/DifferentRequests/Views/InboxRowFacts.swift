import DifferentRequestsProtos
import SwiftUI

/// The second line of an inbox row: the request the update is about and how long ago it happened,
/// on one line, and stacked at accessibility text sizes.
struct InboxRowFacts: View {

  let notification: DRNotification

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  var body: some View {
    if dynamicTypeSize.isAccessibilitySize {
      VStack(alignment: .leading, spacing: Spacing.xxSmall.rawValue) {
        Text(notification.requestTitle)
        if notification.hasCreatedAt {
          Text(notification.createdAt.date.ago)
        }
      }
      .textRole(.supporting)
      .foregroundStyle(ColorRole.secondaryLabel)
    } else {
      HStack(alignment: .firstTextBaseline, spacing: Spacing.xSmall.rawValue) {
        Text(notification.requestTitle)
          .lineLimit(1)
        Spacer(minLength: Spacing.xSmall.rawValue)
        if notification.hasCreatedAt {
          Text(notification.createdAt.date.ago)
            .layoutPriority(1)
        }
      }
      .textRole(.supporting)
      .foregroundStyle(ColorRole.secondaryLabel)
    }
  }
}
