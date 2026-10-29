import DifferentRequestsProtos
import SwiftUI

/// The heading over one status on the roadmap: the status as a word, and how many requests it
/// holds, spelled out, so the number is never a bare digit.
struct RoadmapHeading: View {

  let column: DRRoadmapColumn

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: Spacing.xSmall.points()) {
      Text(column.status.localizedLabel())
        .textRole(.rowTitle)
        .foregroundStyle(ColorRole.label)
      Spacer(minLength: Spacing.xSmall.points())
      Text("\(Int(column.totalCount)) requests", bundle: .module, comment: "How many requests a roadmap status holds")
        .textRole(.reading)
        .foregroundStyle(ColorRole.secondaryLabel)
    }
    .textCase(nil)
  }
}
