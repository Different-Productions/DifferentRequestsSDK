import SwiftUI

/// A view displaying the app's published changelog ("What's New") — most
/// recent entries first, with pull-to-refresh and infinite scroll.
///
/// Requires the app's plan to include the changelog (Pro) — shows an upgrade
/// prompt instead of a generic error when the server returns 402.
///
/// ```swift
/// ChangelogView(client: client)
/// ```
public struct ChangelogView: View {

  @State private var model: ChangelogModel
  private let client: DifferentRequestsClient

  /// Creates the changelog view.
  /// - Parameter client: The DifferentRequests client to use.
  public init(client: DifferentRequestsClient) {
    self.client = client
    self._model = State(initialValue: ChangelogModel(client: client))
  }

  public var body: some View {
    NavigationStack {
      Group {
        if model.isLoading && model.entries.isEmpty {
          ProgressView("Loading what's new...")
        } else if let error = model.error, model.entries.isEmpty {
          errorView(error)
        } else if model.entries.isEmpty {
          ContentUnavailableView(
            "Nothing new yet",
            systemImage: "sparkles",
            description: Text("Announcements about shipped requests will appear here.")
          )
        } else {
          changelogList
        }
      }
      .navigationTitle("What's New")
      .navigationDestination(for: String.self) { requestId in
        RequestDetailView(client: client, requestId: requestId)
      }
      .task {
        await model.load()
      }
    }
  }

  // MARK: - Subviews

  private var changelogList: some View {
    List {
      ForEach(model.entries) { entry in
        ChangelogRow(entry: entry)
      }

      if model.hasMore {
        ProgressView()
          .frame(maxWidth: .infinity)
          .task { await model.loadMore() }
      }
    }
    .listStyle(.plain)
    .refreshable { await model.load() }
  }

  @ViewBuilder
  private func errorView(_ error: DifferentRequestsError) -> some View {
    if case .paymentRequired = error {
      ContentUnavailableView {
        Label("What's New is a Pro feature", systemImage: "lock")
      } description: {
        Text("Upgrade to a Pro plan to publish a changelog of shipped requests.")
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

// MARK: - Changelog Row

private struct ChangelogRow: View {
  let entry: ChangelogEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(entry.title)
        .font(.headline)

      Text(entry.body)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .lineLimit(3)

      Text(DateFormatting.formatted(entry.publishedAt))
        .font(.caption2)
        .foregroundStyle(.tertiary)

      if !entry.requestIds.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(entry.requestIds, id: \.self) { requestId in
              NavigationLink(value: requestId) {
                Text("Resolved request")
                  .font(.caption)
                  .padding(.horizontal, 8)
                  .padding(.vertical, 4)
                  .background(Color.accentColor.opacity(0.12), in: Capsule())
              }
              .buttonStyle(.plain)
            }
          }
        }
      }
    }
    .padding(.vertical, 4)
  }
}

// MARK: - Preview

#Preview("What's New") {
  ChangelogView(client: DifferentRequestsClient(apiKey: "preview"))
}
