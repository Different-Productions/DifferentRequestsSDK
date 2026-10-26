import SwiftUI

/// What sits where the comment field would be in an app that takes no comments: the same words the
/// whole-screen version says, sized to a bar because the request above it is still worth reading.
struct CommentsOff: View {

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.xxSmall.rawValue) {
      Label(PlanSurface.comments.absentTitle, systemImage: PlanSurface.comments.absentSymbol)
        .textRole(.supporting)
        .foregroundStyle(ColorRole.label)

      Text(PlanSurface.comments.absentDescription)
        .textRole(.meta)
        .foregroundStyle(ColorRole.secondaryLabel)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
