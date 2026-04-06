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
            Text(error.localizedDescription)
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
          sortPicker
        }
        ToolbarItem(placement: .primaryAction) {
          Button {
            showSubmit = true
          } label: {
            Image(systemName: "plus")
          }
          .accessibilityLabel("Submit request")
        }
      }
      .sheet(isPresented: $showSubmit) {
        SubmitRequestView(client: client) {
          await model.refresh()
        }
      }
      .task {
        await model.load()
      }
    }
  }

  // MARK: - Subviews

  private var sortPicker: some View {
    Picker("Sort", selection: Binding(
      get: { model.sort },
      set: { newValue in
        model.sort = newValue
        Task { await model.load() }
      }
    )) {
      Text("Recent").tag(SortOrder.recent)
      Text("Top").tag(SortOrder.top)
    }
    .pickerStyle(.segmented)
    .frame(width: 160)
  }

  private var requestList: some View {
    List {
      statusFilterSection

      ForEach(model.requests) { request in
        NavigationLink(value: request.id) {
          RequestRow(request: request) { value in
            await model.vote(requestId: request.id, value: value)
          }
        }
      }

      if model.hasMore {
        ProgressView()
          .frame(maxWidth: .infinity)
          .task { await model.loadMore() }
      }
    }
    .listStyle(.plain)
    .refreshable { await model.refresh() }
    .navigationDestination(for: String.self) { requestId in
      RequestDetailView(client: client, requestId: requestId)
    }
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
  let onVote: (VoteValue) async -> Int?

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      VoteControl(score: request.score, onVote: onVote)

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
