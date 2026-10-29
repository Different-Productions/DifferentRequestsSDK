import DifferentRequestsProtos
import SwiftUI

/// What sits where the comment field would be in an app that takes no comments: the same words the
/// whole-screen version says, sized to a bar because the request above it is still worth reading.
struct CommentsOff: View {

  var body: some View {
    if let absence = DRPlanSurface.comments.absence() {
      VStack(alignment: .leading, spacing: Spacing.xxSmall.points()) {
        Label(absence.title, systemImage: absence.symbol)
          .textRole(.supporting)
          .foregroundStyle(ColorRole.label)

        Text(absence.message)
          .textRole(.meta)
          .foregroundStyle(ColorRole.secondaryLabel)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}
