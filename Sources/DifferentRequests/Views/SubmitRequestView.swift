import SwiftUI

/// The form that files a request, as a screen pushed onto a navigation stack.
///
/// The Requests screen pushes it, so only one sheet is ever up. A host app offering its own way in
/// opens the draft first, then pushes this onto its own stack:
///
/// ```swift
/// Button("Request a feature") {
///   requests.beginSubmission()
///   isComposing = true
/// }
/// .navigationDestination(isPresented: $isComposing) {
///   SubmitRequestView(hub: requests)
/// }
/// ```
///
/// It draws its own Cancel and Send and hides the back button, because leaving with something typed
/// asks first. On macOS they sit in a row at the top of the form. What is typed belongs to the hub,
/// so a redraw cannot take it. Once the request is
/// filed the form dismisses itself, and ``DifferentRequestsHub`` has re-read the board.
public struct SubmitRequestView: View {

  /// What the write goes through, and what re-reads the board once it lands.
  private let hub: DifferentRequestsHub

  /// Whether the question about discarding what was typed is up.
  @State private var submitScreen = SubmitScreenState()

  @Environment(\.dismiss) private var dismiss

  /// - Parameter hub: What the host app built once and holds. Call
  ///   ``DifferentRequestsHub/beginSubmission()`` before pushing this.
  public init(hub: DifferentRequestsHub) {
    self.hub = hub
  }

  public var body: some View {
    SubmitRequestForm(hub: hub)
      .navigationTitle(Text("New request", bundle: .module, comment: "Title of the form for a new feature request"))
      .navigationBarBackButtonHidden()
      #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
      .toolbarVisibility(.hidden, for: .tabBar)
      #endif
      .worn(by: hub)
      #if os(macOS)
      .topRow(
        HStack(spacing: Spacing.small.points()) {
          CancelSubmissionButton(hub: hub, submitScreen: $submitScreen)
          Text("New Request", bundle: .module, comment: "Mac title of the form for a new feature request")
            .textRole(.rowTitle)
            .frame(maxWidth: .infinity)
          SendSubmissionButton(hub: hub, submitScreen: $submitScreen)
        }
        .padding(Spacing.small.points())
      )
      .sheetBarHidden()
      #else
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          CancelSubmissionButton(hub: hub, submitScreen: $submitScreen)
        }
        ToolbarItem(placement: .confirmationAction) {
          SendSubmissionButton(hub: hub, submitScreen: $submitScreen)
        }
      }
      #endif
      .confirmationDialog(
        Text("Discard this request?", bundle: .module, comment: "Question when leaving the new request form with something typed"),
        isPresented: $submitScreen.confirmingDiscard,
        titleVisibility: .visible
      ) {
        Button(role: .destructive) {
          dismiss()
        } label: {
          Text("Discard request", bundle: .module, comment: "Button that leaves the new request form and loses what was typed")
        }
        Button(role: .cancel) {
          submitScreen.confirmingDiscard = false
        } label: {
          Text("Keep writing", bundle: .module, comment: "Button that stays on the new request form")
        }
      }
  }
}
