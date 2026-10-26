import DifferentRequestsProtos
import SwiftUI

/// The top of a request's own screen: its title as the heading, then status, author and age on one
/// line, then what was written.
struct RequestHeader: View {

  let request: DRFeatureRequest

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.small.rawValue) {
      Text(request.title)
        .textRole(.requestTitle)
        .foregroundStyle(ColorRole.label)
        .accessibilityAddTraits(.isHeader)

      if dynamicTypeSize.isAccessibilitySize {
        VStack(alignment: .leading, spacing: Spacing.xxSmall.rawValue) {
          StatusBadge(state: request.state)
          RequestAuthor(request: request)
            .textRole(.meta)
            .foregroundStyle(ColorRole.secondaryLabel)
          if request.hasCreatedAt {
            RequestAge(createdAt: request.createdAt.date)
          }
        }
      } else {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.small.rawValue) {
          StatusBadge(state: request.state)
          RequestAuthor(request: request)
            .textRole(.meta)
            .foregroundStyle(ColorRole.secondaryLabel)
          Spacer(minLength: Spacing.xSmall.rawValue)
          if request.hasCreatedAt {
            RequestAge(createdAt: request.createdAt.date)
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
