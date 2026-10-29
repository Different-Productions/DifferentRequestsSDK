import SwiftUI

/// "See requests" on an empty Roadmap or What's New: asks the host to open its requests list.
struct SeeRequestsButton: View {

  /// Set showing to ask the host for its requests list.
  @Binding var requestsPresentation: RequestsPresentation

  var body: some View {
    Button {
      requestsPresentation.showing = true
    } label: {
      Text("See requests", bundle: .module, comment: "Button on an empty Roadmap or What's New that opens the request list")
    }
    .buttonStyle(.borderedProminent)
    .controlSize(.large)
  }
}
