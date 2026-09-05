#if os(iOS)

  import SafariServices
  import SwiftUI

  /// Safari, over the host app rather than instead of it.
  ///
  /// `SFSafariViewController` and not `openURL`, because `openURL` leaves the app: the reader is
  /// handed to Safari and has to find their way back. A sheet is dismissed and they are where they
  /// were — which matters when the link is one this SDK put inside somebody else's product.
  ///
  /// iOS only. There is no in-app browser on macOS, and a Mac app opening a link in the browser is
  /// the platform's own behaviour rather than a compromise.
  struct SafariSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
      SFSafariViewController(url: url)
    }

    /// Nothing to update: the controller is made with its URL and the sheet is dismissed and
    /// re-presented rather than pointed somewhere else.
    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
  }

#endif
