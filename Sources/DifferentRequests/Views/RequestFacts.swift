import DifferentRequestsProtos
import SwiftUI

/// A request's status, comment count and age: on one line, and stacked at accessibility text sizes.
struct RequestFacts: View {

  let request: DRFeatureRequest

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  var body: some View {
    if dynamicTypeSize.isAccessibilitySize {
      VStack(alignment: .leading, spacing: Spacing.xxSmall.points()) {
        StatusBadge(state: request.state)
        if request.commentCount > 0 {
          CommentCount(request: request)
        }
        if request.hasCreatedAt {
          RequestAge(createdAt: request.createdAt)
        }
      }
    } else {
      HStack(alignment: .firstTextBaseline, spacing: Spacing.small.points()) {
        StatusBadge(state: request.state)
        if request.commentCount > 0 {
          CommentCount(request: request)
        }
        Spacer(minLength: Spacing.xSmall.points())
        if request.hasCreatedAt {
          RequestAge(createdAt: request.createdAt)
        }
      }
    }
  }
}
