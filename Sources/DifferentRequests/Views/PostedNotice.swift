import SwiftUI

/// "Your request is posted. You're following it." — above the board for a few seconds after
/// sending, and a way into the request just filed.
struct PostedNotice: View {

  /// How long the notice stands before it fades.
  private static let shownFor: Duration = .seconds(4)

  private static let spacing: CGFloat = 10
  private static let cornerRadius: CGFloat = 12
  private static let fillOpacity: Double = 0.12

  /// What every screen reads from; the request just filed is on its composer.
  let hub: DifferentRequestsHub

  var body: some View {
    if let posted = hub.submission.submitted {
      NavigationLink {
        RequestDetailView(hub: hub, requestID: posted.id)
      } label: {
        HStack(spacing: Self.spacing) {
          Image(systemName: "checkmark")
            .fontWeight(.bold)
          Text("Your request is posted. You're following it.", bundle: .module, comment: "Note on the board after a person sends a request")
            .frame(maxWidth: .infinity, alignment: .leading)
          Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
        }
        .font(.subheadline)
        .foregroundStyle(.green)
        .padding()
        .background(
          .green.opacity(Self.fillOpacity),
          in: RoundedRectangle(cornerRadius: Self.cornerRadius)
        )
      }
      .buttonStyle(.plain)
      .transition(.opacity)
      .task(id: posted.id) {
        await hub.submission.putAwayPosted(after: Self.shownFor)
      }
    }
  }
}
