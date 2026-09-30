import DifferentRequestsProtos
import SwiftUI

/// What a request says and where it sits, as the tappable half of a board row.
struct RequestSummary: View {

  private static let metadataSpacing: CGFloat = 8
  private static let bodyLineLimit: Int = 2

  let request: DRFeatureRequest

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(request.title)
        .font(.headline)

      if request.body.isEmpty == false {
        Text(request.body)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .lineLimit(Self.bodyLineLimit)
      }

      HStack(spacing: Self.metadataSpacing) {
        StatusBadge(state: request.state)

        if request.commentCount > 0 {
          Label(request.commentCount.formatted(), systemImage: "bubble.left")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()

        if request.hasCreatedAt {
          Text(request.createdAt.date.ago)
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
      }
    }
  }
}
