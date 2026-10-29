import DifferentRequestsProtos
import SwiftUI

/// The top of a request's own screen: its title as the heading, then status, author and age on one
/// line, then what was written.
struct RequestHeader: View {

  let request: DRFeatureRequest

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.small.points()) {
      Text(request.title)
        .textRole(.requestTitle)
        .foregroundStyle(ColorRole.label)
        .accessibilityAddTraits(.isHeader)

      if dynamicTypeSize.isAccessibilitySize {
        VStack(alignment: .leading, spacing: Spacing.xxSmall.points()) {
          StatusBadge(state: request.state)
          RequestAuthor(request: request)
            .textRole(.meta)
            .foregroundStyle(ColorRole.secondaryLabel)
          if request.hasCreatedAt {
            RequestAge(createdAt: request.createdAt)
          }
        }
      } else {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.small.points()) {
          StatusBadge(state: request.state)
          RequestAuthor(request: request)
            .textRole(.meta)
            .foregroundStyle(ColorRole.secondaryLabel)
          Spacer(minLength: Spacing.xSmall.points())
          if request.hasCreatedAt {
            RequestAge(createdAt: request.createdAt)
          }
        }
      }

      if request.body.isEmpty == false {
        Text(request.body)
          .textRole(.reading)
          .foregroundStyle(ColorRole.label)
          .textSelection(.enabled)
      }
    }
  }
}
