import DifferentRequestsProtos
import SwiftUI

/// What a request says and where it sits, as the tappable half of a row: its title, one supporting
/// line, and its facts, all on one leading edge.
///
/// At accessibility text sizes the supporting line wraps, because one line of very large text is a
/// few words.
struct RequestSummary: View {

  let request: DRFeatureRequest

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.xxSmall.rawValue) {
      Text(request.title)
        .textRole(.rowTitle)
        .foregroundStyle(ColorRole.label)
        .lineLimit(2)

      if request.body.isEmpty == false {
        Text(request.body)
          .textRole(.supporting)
          .foregroundStyle(ColorRole.secondaryLabel)
          .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 1)
      }

      RequestFacts(request: request)
    }
  }
}
