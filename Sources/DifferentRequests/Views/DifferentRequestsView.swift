import SwiftUI

/// The main entry point for displaying feature requests.
///
/// Shows a paginated, filterable, sortable list of requests with voting,
/// pull-to-refresh, infinite scroll, and a submit button.
///
/// ```swift
/// DifferentRequestsView(client: client)
/// ```
public struct DifferentRequestsView: View {

  @State private var model: RequestListModel
  @State private var showSubmit = false
  private let client: DifferentRequestsClient

  /// Creates the main request list view.
  /// - Parameter client: The DifferentRequests client to use.
  public init(client: DifferentRequestsClient) {
    self.client = client
    self._model = State(initialValue: RequestListModel(client: client))
  }

  public var body: some View {
    NavigationStack {
      Group {
        if model.isLoading && model.requests.isEmpty {
          ProgressView("Loading requests...")
        } else if let error = model.error, model.requests.isEmpty {
          ContentUnavailableView {
            Label("Failed to load", systemImage: "exclamationmark.triangle")
          } description: {
            Text(error.errorDescription ?? "Unknown error")
          } actions: {
            Button("Retry") { Task { await model.load() } }
          }
        } else if model.requests.isEmpty {
          ContentUnavailableView(
            "No requests yet",
            systemImage: "tray",
            description: Text("Feature requests will appear here.")
          )
        } else {
          requestList
        }
      }
      .navigationTitle("Requests")
      .toolbar {
        ToolbarItem(placement: .navigation) {
          Picker("Sort", selection: $model.sort) {
            Text("Recent").tag(SortOrder.recent)
            Text("Top").tag(SortOrder.top)
          }
          .pickerStyle(.segmented)
          .frame(width: 160)
        }
        ToolbarItem(placement: .primaryAction) {
          Button("Submit request", systemImage: "plus") {
            showSubmit = true
          }
        }
      }
      .sheet(isPresented: $showSubmit) {
        SubmitRequestView(client: client) {
          await model.refresh()
        }
      }
      .sheet(item: $model.selectedRequest) { request in
        NavigationStack {
          RequestDetailView(client: client, requestId: request.id)
        }
      }
      .task {
        await model.load()
      }
      .onChange(of: model.sort) {
        Task { await model.load() }
      }
    }
  }

  // MARK: - Subviews

  private var requestList: some View {
    List {
      statusFilterSection

      ForEach(model.requests) { request in
        RequestRow(
          request: request,
          onUpvote: { Task { await model.vote(requestId: request.id, value: .upvote) } },
          onDownvote: { Task { await model.vote(requestId: request.id, value: .downvote) } },
          onTap: { model.selectedRequest = request }
        )
      }

      if model.hasMore {
        ProgressView()
          .frame(maxWidth: .infinity)
          .task { await model.loadMore() }
      }
    }
    .listStyle(.plain)
    .refreshable { await model.refresh() }
  }

  private var statusFilterSection: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        FilterChip(label: "All", isActive: model.statusFilter == nil) {
          model.statusFilter = nil
          Task { await model.load() }
        }
        ForEach(RequestStatus.allCases, id: \.self) { status in
          FilterChip(label: status.label, isActive: model.statusFilter == status) {
            model.statusFilter = status
            Task { await model.load() }
          }
        }
      }
      .padding(.horizontal)
    }
    .listRowInsets(EdgeInsets())
    .listRowSeparator(.hidden)
  }
}

// MARK: - Request Row

private struct RequestRow: View {
  let request: Request
  let onUpvote: () -> Void
  let onDownvote: () -> Void
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack(alignment: .top, spacing: 12) {
        VoteControl(score: request.score, onUpvote: onUpvote, onDownvote: onDownvote)

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

            StatusBadge(status: request.status)

            Spacer()

            Text(DateFormatting.formatted(request.createdAt))
              .font(.caption2)
              .foregroundStyle(.tertiary)
          }
        }
      }
      .padding(.vertical, 4)
    }
    .buttonStyle(.plain)
  }
}

// MARK: - Filter Chip

private struct FilterChip: View {
  let label: String
  let isActive: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(label)
        .font(.caption)
        .fontWeight(isActive ? .semibold : .regular)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isActive ? Color.accentColor.opacity(0.15) : Color(.secondarySystemFill), in: Capsule())
        .foregroundStyle(isActive ? Color.accentColor : .primary)
    }
    .buttonStyle(.plain)
  }
}

// MARK: - RequestStatus CaseIterable

extension RequestStatus: CaseIterable {
  public static var allCases: [RequestStatus] {
    [.open, .planned, .inProgress, .shipped, .declined]
  }
}

// MARK: - Preview

#Preview("Request List") {
  DifferentRequestsView(client: DifferentRequestsClient(apiKey: "preview"))
}
