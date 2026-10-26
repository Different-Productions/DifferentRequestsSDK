import SwiftUI

/// What's New as one grouped list: one card per update, newest first, each ending in a row per
/// request it answers, and the row for the next page.
struct ChangelogList: View {

  /// What holds the updates, and what a push from a row is built against.
  let hub: DifferentRequestsHub

  var body: some View {
    List {
      ForEach(hub.changelog.read.held, id: \.id) { entry in
        Section {
          ChangelogEntryHeader(entry: entry)

          if entry.answers.isEmpty == false {
            Text("Requests in this update", bundle: .module, comment: "Heading over the requests a What's New entry answers")
              .textRole(.supporting)
              .fontWeight(.semibold)
              .foregroundStyle(ColorRole.label)
              .accessibilityAddTraits(.isHeader)
              .listRowSeparator(.hidden, edges: .bottom)

            ForEach(entry.answers, id: \.requestID) { answer in
              ChangelogAnswerRow(hub: hub, answer: answer)
            }
          }
        }
      }

      if hub.changelog.page.isDone == false {
        Section {
          NextPageRow(
            state: hub.changelog.page,
            failureMessage: String(
              localized: "Couldn't load more of What's New.",
              bundle: .module,
              comment: "Row at the end of the What's New list when the next page failed to load"
            )
          ) {
            await hub.changelog.loadMore()
          }
        }
      }
    }
    .groupedList()
    .refreshable {
      await hub.changelog.load()
    }
  }
}
