import SwiftUI

/// "What is this?" — what Different Requests is, in an app user's words, behind the "Powered by
/// Different Requests" badge.
struct PoweredByPage: View {

  /// Where "About Different Requests" goes.
  static let home = URL(string: "https://differentrequests.com")

  private static let spacing: CGFloat = 16
  private static let pointSpacing: CGFloat = 14

  /// What this app is called, as its configuration names it.
  let appConfig: AppConfigStore

  /// Whether Safari is up over the page, on iOS.
  @State private var isShowingHome = false

  @Environment(\.dismiss) private var dismiss
  @Environment(\.openURL) private var openURL

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: Self.spacing) {
          introText
            .font(.title3)

          VStack(alignment: .leading, spacing: Self.pointSpacing) {
            Text(
              "**Ask** for something, or vote for what others asked.",
              bundle: .module,
              comment: "What is this? page; Markdown bold on the first word"
            )
            Text(
              "**Follow** a request and you'll be told when it's planned or shipped.",
              bundle: .module,
              comment: "What is this? page; Markdown bold on the first word"
            )
            Text(
              "**Your requests go to the team behind \(appName).** We don't sell or share what you write.",
              bundle: .module,
              comment: "What is this? page; Markdown bold on the first sentence; the argument is the app's name"
            )
          }

          if let home = Self.home {
            Button {
              #if os(iOS)
              isShowingHome = true
              #else
              openURL(home)
              #endif
            } label: {
              Text(
                "About Different Requests",
                bundle: .module,
                comment: "Button that opens the product's website; Different Requests is the product's name"
              )
            }
            .padding(.top, Self.spacing)
            #if os(iOS)
              .sheet(isPresented: $isShowingHome) {
                SafariSheet(url: home)
                  .ignoresSafeArea()
              }
            #endif
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
      }
      .navigationTitle(Text("What is this?", bundle: .module, comment: "Title of the page behind the Powered by badge"))
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button {
            dismiss()
          } label: {
            Text("Done", bundle: .module, comment: "Button that closes the request board")
          }
        }
      }
    }
    .sheetMinimumSize()
  }

  /// The page's first sentence, naming the app when its configuration gave a name.
  private var introText: Text {
    if appConfig.config.app.name.isEmpty {
      return Text(
        "This app uses Different Requests to hear what you want next.",
        bundle: .module,
        comment: "Lead of the What is this? page when the app has no name"
      )
    }
    return Text(
      "\(appConfig.config.app.name) uses Different Requests to hear what you want next.",
      bundle: .module,
      comment: "Lead of the What is this? page; the argument is the app's name"
    )
  }

  /// The app's own name, or "this app" when its configuration gave none.
  private var appName: String {
    if appConfig.config.app.name.isEmpty {
      return String(localized: "this app", bundle: .module, comment: "Stands in for the app's name when it has none")
    }
    return appConfig.config.app.name
  }
}
