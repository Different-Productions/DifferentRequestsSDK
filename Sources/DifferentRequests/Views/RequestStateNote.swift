import DifferentRequestsProtos
import SwiftUI

/// What a request's state has to say beyond its name: a decline's reason, or the way to the request
/// a duplicate was folded into. Nothing for every other state.
struct RequestStateNote: View {

  /// What a push to the duplicated request is built against.
  let hub: DifferentRequestsHub

  let request: DRFeatureRequest

  var body: some View {
    switch request.state {
    case .declined(let decline):
      VStack(alignment: .leading, spacing: Spacing.xxSmall.points()) {
        if decline.reason.label.isEmpty == false {
          Text(decline.reason.label)
            .fontWeight(.semibold)
            .foregroundStyle(ColorRole.label)
        }
        if decline.reason.description_p.isEmpty == false {
          Text(decline.reason.description_p)
            .foregroundStyle(ColorRole.secondaryLabel)
        }
        if decline.note.isEmpty == false {
          Text(decline.note)
            .foregroundStyle(ColorRole.secondaryLabel)
        }
      }
      .textRole(.supporting)
      .textSelection(.enabled)
    case .duplicate(let duplicate):
      NavigationLink {
        RequestDetailView(hub: hub, requestID: duplicate.duplicateOfRequestID)
      } label: {
        Label {
          Text(
            "Someone already asked for this. Your vote moved to their request.",
            bundle: .module,
            comment: "Link on a request the team merged into an earlier one"
          )
        } icon: {
          Image(systemName: "arrow.triangle.merge")
        }
        .textRole(.supporting)
      }
    case .open, .planned, .inProgress, .shipped, .none:
      EmptyView()
    }
  }
}
