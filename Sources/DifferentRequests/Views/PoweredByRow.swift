import SwiftUI

/// "Powered by Different Requests", as one row after the last request of a free app, which pushes
/// "What is this?".
///
/// Draw it only while ``BadgeState/isCarried`` says the app carries it.
struct PoweredByRow: View {

  /// What the page behind the row reads the app's name from.
  let appConfig: AppConfigStore

  var body: some View {
    NavigationLink {
      PoweredByPage(appConfig: appConfig)
    } label: {
      HStack(spacing: 0) {
        Text("Powered by ", bundle: .module, comment: "Words before the product name on the badge, with the space before the name")
          .foregroundStyle(ColorRole.secondaryLabel)
        Text(verbatim: "Different Requests")
          .fontWeight(.semibold)
          .foregroundStyle(ColorRole.label)
      }
      .textRole(.meta)
    }
    .accessibilityLabel(
      Text(
        "Powered by Different Requests",
        bundle: .module,
        comment: "VoiceOver label for the badge; Different Requests is the product's name"
      )
    )
    .accessibilityHint(
      Text(
        "Opens a page about Different Requests.",
        bundle: .module,
        comment: "VoiceOver hint for the badge; Different Requests is the product's name"
      )
    )
  }
}
