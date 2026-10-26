import SwiftUI

/// "What is this?": what Different Requests is, in an app user's words, pushed from the "Powered by
/// Different Requests" row. Its last row opens the product's site in the browser, so nothing is
/// presented over the sheet.
struct PoweredByPage: View {

  /// What this app is called, as its configuration names it.
  let appConfig: AppConfigStore

  var body: some View {
    List {
      Section {
        if appConfig.config.app.name.isEmpty {
          Text(
            "This app uses Different Requests to hear what you want next.",
            bundle: .module,
            comment: "Lead of the What is this? page when the app has no name"
          )
        } else {
          Text(
            "\(appConfig.config.app.name) uses Different Requests to hear what you want next.",
            bundle: .module,
            comment: "Lead of the What is this? page; the argument is the app's name"
          )
        }
      }
      .textRole(.reading)
      .foregroundStyle(ColorRole.label)

      Section {
        Label {
          Text(
            "**Ask** for something, or vote for what others asked.",
            bundle: .module,
            comment: "What is this? page; Markdown bold on the first word"
          )
        } icon: {
          Image(systemName: "plus.bubble")
        }

        Label {
          Text(
            "**Follow** a request and you'll be told when it's planned or shipped.",
            bundle: .module,
            comment: "What is this? page; Markdown bold on the first word"
          )
        } icon: {
          Image(systemName: "bell")
        }

        Label {
          if appConfig.config.app.name.isEmpty {
            let thisApp = String(localized: "this app", bundle: .module, comment: "Stands in for the app's name when it has none")
            Text(
              "**Your requests go to the team behind \(thisApp).** What you write is never sold or shared.",
              bundle: .module,
              comment: "What is this? page; Markdown bold on the first sentence; the argument is the app's name"
            )
          } else {
            Text(
              "**Your requests go to the team behind \(appConfig.config.app.name).** What you write is never sold or shared.",
              bundle: .module,
              comment: "What is this? page; Markdown bold on the first sentence; the argument is the app's name"
            )
          }
        } icon: {
          Image(systemName: "lock")
        }
      }
      .textRole(.reading)
      .foregroundStyle(ColorRole.label)

      if let home = URL(string: "https://differentrequests.com") {
        Section {
          Link(destination: home) {
            Text(
              "About Different Requests",
              bundle: .module,
              comment: "Button that opens the product's website; Different Requests is the product's name"
            )
            .textRole(.reading)
          }
        }
      }
    }
    .groupedList()
    .navigationTitle(Text("What is this?", bundle: .module, comment: "Title of the page behind the Powered by row"))
  }
}
