import DifferentRequestsProtos
import SwiftUI

/// The roadmap: what is planned, what is being built, and what shipped.
///
/// ```swift
/// NavigationStack {
///   RoadmapView(hub: requests, isShowingRequests: $isShowingRequests)
/// }
/// ```
///
/// Handed a binding, an empty roadmap offers **See requests**, which sets it to `true` so the host
/// opens its requests list. Handed `nil`, it offers nothing: pushed from the board, the back button
/// already goes there. Shown as the first screen of a sheet, it draws its own Done.
///
/// A section per column rather than panes side by side. The contract's columns are ordered for
/// display and read left to right, which at phone width would hide two of the three; stacked, all
/// of them are readable and each row is a link into the request itself.
///
/// Each column is a bounded page the server chose, so a count that exceeds what is listed is
/// stated rather than paged — the board is where a long column is read.
public struct RoadmapView: View {

  private static let rowSpacing: CGFloat = 12

  /// What the screen reads from, and what a push from a column is built against.
  private let hub: DifferentRequestsHub

  /// The hub's roadmap state, which outlives this screen and keeps what it has read.
  private let store: RoadmapStore

  /// Set to `true` by **See requests** on an empty roadmap, or nil when the host gave no way there.
  private let isShowingRequests: Binding<Bool>?

  /// - Parameters:
  ///   - hub: What the host app built once and holds.
  ///   - isShowingRequests: What opens the host's requests list, or nil for no **See requests**.
  public init(hub: DifferentRequestsHub, isShowingRequests: Binding<Bool>?) {
    self.hub = hub
    self.store = hub.roadmap
    self.isShowingRequests = isShowingRequests
  }

  public var body: some View {
    content
      .navigationTitle(Text("Roadmap", bundle: .module, comment: "Title of the roadmap screen"))
      .worn(by: hub.appearanceDrawn)
      .sheetDoneButton()
      .sheetMinimumSize()
      .task {
        // Every appearance: a vote cast elsewhere changes the rows' votes, and the roadmap has no
        // pages to lose. What is held stays on screen while it reads.
        await store.load()
      }
  }

  // MARK: - Content

  /// Whether this app has a roadmap is asked before anything is drawn, and answered on the screen
  /// rather than by a read that would come back refused. An app without one is not a failure and
  /// not an empty roadmap: it is a screen that says what is there instead.
  @ViewBuilder
  private var content: some View {
    switch store.plan {
    case .unread, .reading:
      ProgressView()
    case .failed(let error):
      LoadFailure(error: error) {
        await store.load()
      }
    case .excluded:
      AbsentSurface(surface: .roadmap, isShowingRequests: isShowingRequests)
    case .included:
      columns
    }
  }

  /// Four outcomes, from one state. The list stays up through a refresh even while its columns
  /// are being replaced: a pull-to-refresh runs on the list's own task, and a list that
  /// disappears takes that task with it.
  @ViewBuilder
  private var columns: some View {
    switch store.read {
    case .unread, .reading:
      ProgressView()
    case .failed(let error):
      LoadFailure(error: error) {
        await store.load()
      }
    case .empty:
      ContentUnavailableView {
        Label {
          Text("Nothing planned yet", bundle: .module, comment: "Heading when the roadmap has nothing on it")
        } icon: {
          Image(systemName: "map")
        }
      } description: {
        Text("When the team plans something, it shows up here.", bundle: .module, comment: "Message when the roadmap has nothing on it")
      } actions: {
        if let isShowingRequests {
          SeeRequestsButton(isShowingRequests: isShowingRequests)
        }
      }
    case .loaded(let held), .refreshing(let held):
      list(held)
    }
  }

  private func list(_ columns: [DRRoadmapColumn]) -> some View {
    List {
      ForEach(columns, id: \.status.rawValue) { column in
        Section {
          if column.requests.isEmpty {
            Text("Nothing here yet.", bundle: .module, comment: "A roadmap column with no requests in it")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          } else {
            ForEach(column.requests, id: \.id) { request in
              NavigationLink {
                RequestDetailView(hub: hub, requestID: request.id)
              } label: {
                row(request)
              }
            }
          }
        } header: {
          header(column)
        }
      }
    }
    .refreshable {
      await store.load()
    }
  }

  private func header(_ column: DRRoadmapColumn) -> some View {
    HStack {
      StatusBadge(groupedBy: column.status)
      Spacer()
      Text(column.totalCount.formatted())
        .font(.caption)
        .monospacedDigit()
        .foregroundStyle(.secondary)
    }
  }

  /// The count and the caller's own vote, drawn as on the board but not pressable: a roadmap is a
  /// summary, and the request's own screen is where a vote is cast. The divider runs from the
  /// title's edge.
  private func row(_ request: DRFeatureRequest) -> some View {
    HStack(spacing: Self.rowSpacing) {
      VoteTally(voteCount: Int(request.voteCount), voted: request.viewer.voted)

      Text(request.title)
        .font(.subheadline)
        .lineLimit(2)
        .alignmentGuide(.listRowSeparatorLeading) { viewDimensions in
          viewDimensions[.leading]
        }

      Spacer()
    }
  }
}
