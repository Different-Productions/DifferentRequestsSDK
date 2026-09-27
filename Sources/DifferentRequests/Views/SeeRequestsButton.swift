import SwiftUI

/// "See requests" on an empty Roadmap or What's New: asks the host to open its requests list.
struct SeeRequestsButton: View {

  /// Set to `true` to ask the host for its requests list.
  @Binding var isShowingRequests: Bool

  var body: some View {
    Button {
      isShowingRequests = true
    } label: {
      Text("See requests", bundle: .module, comment: "Button on an empty Roadmap or What's New that opens the request list")
        .foregroundStyle(.background)
        .frame(maxWidth: CallToActionSize.width)
    }
    .buttonStyle(.borderedProminent)
    .controlSize(.large)
  }
}
