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

  var body: some View {
    ScrollView {
      Text(session.client.describeIntegration())
        .font(.system(.footnote, design: .monospaced))
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
    .navigationTitle("Diagnostics")
    .navigationBarTitleDisplayMode(.inline)
  }
}
