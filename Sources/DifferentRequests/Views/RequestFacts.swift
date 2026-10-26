import DifferentRequestsProtos
import SwiftUI

/// A request's status, comment count and age: on one line, and stacked at accessibility text sizes.
struct RequestFacts: View {

  let request: DRFeatureRequest

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  var body: some View {
    if dynamicTypeSize.isAccessibilitySize {
      VStack(alignment: .leading, spacing: Spacing.xxSmall.rawValue) {
        StatusBadge(state: request.state)
        if request.commentCount > 0 {
          CommentCount(count: Int(request.commentCount))
        }
        if request.hasCreatedAt {
          RequestAge(createdAt: request.createdAt.date)
        }
      }
    } else {
      HStack(alignment: .firstTextBaseline, spacing: Spacing.small.rawValue) {
        StatusBadge(state: request.state)
        if request.commentCount > 0 {
          CommentCount(count: Int(request.commentCount))
        }
        Spacer(minLength: Spacing.xSmall.rawValue)
        if request.hasCreatedAt {
          RequestAge(createdAt: request.createdAt.date)
        }
      }
    }
  }
}
