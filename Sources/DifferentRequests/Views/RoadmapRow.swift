import DifferentRequestsProtos
import SwiftUI

/// One request on the roadmap: its title, and its votes in words under it. The roadmap is a
/// summary, so nothing here looks like the vote button; the request's own screen is where a vote
/// is cast.
struct RoadmapRow: View {

  /// What a push from this row is built against.
  let hub: DifferentRequestsHub

  let request: DRFeatureRequest

  var body: some View {
    NavigationLink {
      RequestDetailView(hub: hub, requestID: request.id)
    } label: {
      VStack(alignment: .leading, spacing: Spacing.xxSmall.points()) {
        Text(request.title)
          .textRole(.reading)
          .foregroundStyle(ColorRole.label)
        Text("\(Int(request.voteCount)) votes", bundle: .module, comment: "VoiceOver count of a request's votes")
          .textRole(.meta)
          .foregroundStyle(ColorRole.secondaryLabel)
      }
    }
  }
}
