import SwiftUI

/// The roadmap as one grouped list: a section per status, in the order the server gives them, each
/// under its heading. A status with nothing in it says so under its heading.
struct RoadmapList: View {

  /// What holds the roadmap, and what a push from a row is built against.
  let hub: DifferentRequestsHub

  var body: some View {
    List {
      ForEach(hub.roadmap.read.held, id: \.status.rawValue) { column in
        Section {
          if column.requests.isEmpty {
            Text("No requests here yet.", bundle: .module, comment: "A roadmap column with no requests in it")
              .textRole(.supporting)
              .foregroundStyle(ColorRole.secondaryLabel)
          } else {
            ForEach(column.requests, id: \.id) { request in
              RoadmapRow(hub: hub, request: request)
            }
          }
        } header: {
          RoadmapHeading(column: column)
        }
      }
    }
    .groupedList()
    .refreshable {
      await hub.roadmap.load()
    }
  }
}
