import DifferentRequestsProtos
import SwiftUI

/// One request on the Requests screen: its vote beside what it says, and the vote above what it
/// says at accessibility text sizes.
///
/// The vote sits beside the link, never inside its label: a button inside a `NavigationLink` label
/// does not receive the tap.
struct RequestRow: View {

  /// What a push from this row is built against.
  let hub: DifferentRequestsHub

  let request: DRFeatureRequest

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  var body: some View {
    if dynamicTypeSize.isAccessibilitySize {
      VStack(alignment: .leading, spacing: Spacing.small.rawValue) {
        RequestVote(hub: hub, request: request)

        NavigationLink {
          RequestDetailView(hub: hub, requestID: request.id)
        } label: {
          RequestSummary(request: request)
        }
      }
    } else {
      HStack(alignment: .top, spacing: Spacing.small.rawValue) {
        RequestVote(hub: hub, request: request)

        NavigationLink {
          RequestDetailView(hub: hub, requestID: request.id)
        } label: {
          RequestSummary(request: request)
        }
        .alignmentGuide(.listRowSeparatorLeading) { dimensions in
          dimensions[.leading]
        }
      }
    }
  }
}
