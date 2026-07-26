import DifferentRequestsProtos
import SwiftUI

/// The roadmap: what is planned, what is being built, and what shipped.
///
/// ```swift
/// NavigationStack {
///   RoadmapView(client: client)
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

  private let client: DifferentRequestsClient
  private let store: RoadmapStore

  /// - Parameter client: The client the roadmap reads through.
  public init(client: DifferentRequestsClient) {
    self.client = client
    self.store = RoadmapStore(client: client)
  }

  public var body: some View {
    content
      .navigationTitle("Roadmap")
      .firstRead(hasLoaded: store.hasLoaded) {
        await store.load()
      }
  }

  // MARK: - Content

  /// The list stays up while a read is in flight even with nothing in it: a pull-to-refresh runs on
  /// the list's own task, and losing the list mid-read would take the read with it.
  @ViewBuilder
  private var content: some View {
    if store.hasLoaded == false {
      ProgressView()
    } else if store.columns.isEmpty == false || store.isLoading {
      list
    } else if store.loadError != nil {
      LoadFailure {
        await store.load()
      }
    } else {
      ContentUnavailableView {
        Label("No roadmap yet", systemImage: "map")
      } description: {
        Text("Nothing has been planned publicly.")
      }
    }
  }

  private var list: some View {
    List {
      ForEach(store.columns, id: \.status.rawValue) { column in
        Section {
          if column.requests.isEmpty {
            Text("Nothing here yet.")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          } else {
            ForEach(column.requests, id: \.id) { request in
              NavigationLink {
                RequestDetailView(client: client, requestID: request.id)
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
