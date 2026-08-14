import DifferentRequestsProtos
import SwiftUI

/// The roadmap: what is planned, what is being built, and what shipped.
///
/// ```swift
/// NavigationStack {
///   RoadmapView(hub: requests)
/// }
/// ```
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

  /// - Parameter hub: What the host app built once and holds.
  public init(hub: DifferentRequestsHub) {
    self.hub = hub
    self.store = hub.roadmap
  }

  public var body: some View {
    content
      .navigationTitle("Roadmap")
      .firstRead(store.read) {
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
    case .failed:
      LoadFailure {
        await store.load()
      }
    case .excluded:
      AbsentSurface(surface: .roadmap)
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
    case .failed:
      LoadFailure {
        await store.load()
      }
    case .empty:
      ContentUnavailableView {
        Label("No roadmap yet", systemImage: "map")
      } description: {
        Text("Nothing has been planned publicly.")
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
            Text("Nothing here yet.")
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
      StatusBadge(status: column.status)
      Spacer()
      Text(column.totalCount.formatted())
        .font(.caption)
        .monospacedDigit()
        .foregroundStyle(.secondary)
    }
  }

  /// Columns are ranked by demand, so the count is what orders the rows and belongs on each one.
  /// Voting is not offered here: a roadmap is a summary, and the request's own screen is where a
  /// vote is cast and where the count it changes is authoritative.
  private func row(_ request: DRFeatureRequest) -> some View {
    HStack(spacing: Self.rowSpacing) {
      Text(request.title)
        .font(.subheadline)
        .lineLimit(2)

      Spacer()

      Label(request.voteCount.formatted(), systemImage: "chevron.up")
        .font(.caption)
        .monospacedDigit()
        .foregroundStyle(.secondary)
    }
  }
}
