import DifferentRequests
import SwiftUI

/// What the SDK says about its own setup.
///
/// A developer looking at an empty board cannot tell these apart: not shipped yet, wrong key, the
/// old base URL, a surface their plan does not include, or our fault. `describeIntegration()`
/// answers all five from what the server actually said, and reads only state already held — so it
/// makes no call and is safe to draw anywhere.
///
/// Shown here because an example that hides the debugging tool is an example that leaves a
/// developer guessing on their first bad afternoon.
struct DiagnosticsView: View {
  private let session: Session

  init(session: Session) {
    self.session = session
  }

  /// What the client says about itself, read once when the screen appears.
  ///
  /// Held rather than asked for while drawing: the client is an actor, so asking it is a wait, and
  /// a body cannot wait. Read inline it compiled with a warning and would have stopped compiling.
  @State private var described = ""

  var body: some View {
    // Both directions, and never wrapped, so each value stays on its label's line.
    ScrollView([.vertical, .horizontal]) {
      Text(described)
        .font(.system(.footnote, design: .monospaced))
        .textSelection(.enabled)
        .fixedSize(horizontal: true, vertical: false)
        .padding()
    }
    .navigationTitle("Diagnostics")
    #if os(iOS)
    .navigationBarTitleDisplayMode(.inline)
    #endif
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button("Copy") {
          #if os(iOS)
          UIPasteboard.general.string = described
          #else
          NSPasteboard.general.clearContents()
          NSPasteboard.general.setString(described, forType: .string)
          #endif
        }
        .disabled(described.isEmpty)
      }
    }
    .task {
      described = await session.client.describeIntegration()
    }
  }
}
