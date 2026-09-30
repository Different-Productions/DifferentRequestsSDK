import SwiftUI

/// What a screen shows in place of a surface this app does not have.
///
/// Not a failure and not an empty result: those are a connection to retry and a surface waiting to
/// be filled. This one is neither, so there is no **Try again** on it — the read that would follow
/// it has one possible answer, and it is the answer the contract says a reader must never be given.
///
/// Sized to replace a screen, which is what a plan-gated surface is: the whole tab, not a row in
/// it. The composer under a request draws the same words in the strip it would have occupied,
/// because there is a request above it that is still worth reading.
struct AbsentSurface: View {

  /// Which surface is not here, and therefore what is said in its place.
  let surface: PlanSurface

  /// What opens the host's requests list, or nil for no **See requests**.
  let isShowingRequests: Binding<Bool>?

  var body: some View {
    ContentUnavailableView {
      Label(surface.absentTitle, systemImage: surface.absentSymbol)
    } description: {
      Text(surface.absentDescription)
    } actions: {
      if let isShowingRequests {
        SeeRequestsButton(isShowingRequests: isShowingRequests)
      }
    }
  }
}
