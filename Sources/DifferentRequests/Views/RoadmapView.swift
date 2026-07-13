import SwiftUI

/// A view displaying the app's public roadmap: Planned, In Progress, and
/// Shipped requests grouped into sections, pinned items marked with a pin icon.
///
/// Requires the app's plan to include the roadmap (Pro) — shows an upgrade
/// prompt instead of a generic error when the server returns 402.
///
/// ```swift
/// RoadmapView(client: client)
/// ```
public struct RoadmapView: View {

  @State private var model: RoadmapModel
  private let client: DifferentRequestsClient

  /// Creates the roadmap view.
  /// - Parameter client: The DifferentRequests client to use.
  public init(client: DifferentRequestsClient) {
    self.client = client
    self._model = State(initialValue: RoadmapModel(client: client))
  }

  public var body: some View {
    NavigationStack {
      Group {
        if model.isLoading && allColumnsEmpty {
          ProgressView("Loading roadmap...")
        } else if let error = model.error, allColumnsEmpty {
          errorView(error)
        } else if allColumnsEmpty {
          ContentUnavailableView(
            "No roadmap items yet",
            systemImage: "map",
            description: Text("Planned, in-progress, and shipped requests will appear here.")
          )
        } else {
          roadmapList
        }
      }
      .navigationTitle("Roadmap")
      .navigationDestination(for: String.self) { requestId in
        RequestDetailView(client: client, requestId: requestId)
      }
      .task {
        await model.load()
      }
    }
  }

  private var allColumnsEmpty: Bool {
    model.columns.allSatisfy { $0.requests.isEmpty }
  }

  // MARK: - Subviews

  private var roadmapList: some View {
    List {
      ForEach(model.columns) { column in
        if !column.requests.isEmpty {
          Section {
            ForEach(column.requests) { request in
              NavigationLink(value: request.id) {
                RoadmapRow(request: request)
              }
            }
          } header: {
            Text(column.status.label)
          }
        }
      }
    }
    .listStyle(.plain)
    .refreshable { await model.load() }
  }

  @ViewBuilder
  private func errorView(_ error: DifferentRequestsError) -> some View {
    if case .paymentRequired = error {
      ContentUnavailableView {
        Label("Roadmap is a Pro feature", systemImage: "lock")
      } description: {
        Text("Upgrade to a Pro plan to see planned, in-progress, and shipped requests.")
      }
    } else {
      ContentUnavailableView {
        Label("Failed to load", systemImage: "exclamationmark.triangle")
      } description: {
        Text(error.localizedDescription)
      } actions: {
        Button("Retry") { Task { await model.load() } }
      }
    }
  }
}

// MARK: - Roadmap Row

private struct RoadmapRow: View {
  let request: Request

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      if request.roadmapPinned {
        Image(systemName: "pin.fill")
          .font(.caption)
          .foregroundStyle(.orange)
          .padding(.top, 2)
          .accessibilityLabel("Pinned")
      }

      VStack(alignment: .leading, spacing: 4) {
        Text(request.title)
          .font(.headline)
          .lineLimit(1)

        Text(request.body)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .lineLimit(1)

        HStack(spacing: 8) {
          Text(request.authorDisplayName)
            .font(.caption)
            .foregroundStyle(.tertiary)

          Spacer()

          Text("\(request.score) votes")
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
      }
    }
    .padding(.vertical, 4)
  }
}

// MARK: - Preview

#Preview("Roadmap") {
  RoadmapView(client: DifferentRequestsClient(apiKey: "preview"))
}
