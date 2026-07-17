import SwiftUI
import DifferentRequests

/// Lists the requests the signed-in user follows and lets them toggle following
/// on each. Exercises `listFollowedRequests`, follower counts, and the
/// follow/unfollow toggle through the SDK's `FollowModel`.
struct FollowingView: View {
  @State private var model: FollowingModel
  private let client: DifferentRequestsClient

  init(client: DifferentRequestsClient) {
    self.client = client
    self._model = State(initialValue: FollowingModel(client: client))
  }

  var body: some View {
    NavigationStack {
      content
        .navigationTitle("Following")
        .navigationDestination(for: String.self) { requestId in
          RequestDetailView(client: client, requestId: requestId)
        }
        .task { await model.load() }
    }
  }

  @ViewBuilder
  private var content: some View {
    if model.isLoading && model.requests.isEmpty {
      ProgressView("Loading…")
    } else if let message = model.errorMessage, model.requests.isEmpty {
      ContentUnavailableView {
        Label("Failed to load", systemImage: "exclamationmark.triangle")
      } description: {
        Text(message)
      } actions: {
        Button("Retry") { Task { await model.load() } }
      }
    } else if model.requests.isEmpty {
      ContentUnavailableView(
        "Not following anything",
        systemImage: "star",
        description: Text("Vote on or comment on a request to follow it, then it shows up here.")
      )
    } else {
      List(model.requests) { request in
        FollowRow(client: client, request: request)
      }
      .listStyle(.plain)
      .refreshable { await model.load() }
    }
  }
}

// MARK: - Follow Row

private struct FollowRow: View {
  @State private var follow: FollowModel
  private let request: Request

  init(client: DifferentRequestsClient, request: Request) {
    self.request = request
    self._follow = State(initialValue: FollowModel(client: client, requestId: request.id, isFollowing: true))
  }

  var body: some View {
    HStack(spacing: 12) {
      NavigationLink(value: request.id) {
        VStack(alignment: .leading, spacing: 4) {
          Text(request.title)
            .font(.headline)
            .lineLimit(1)
          subtitle
        }
      }

      Spacer()

      Button {
        Task { await follow.toggle() }
      } label: {
        Image(systemName: follow.isFollowing ? "star.fill" : "star")
          .foregroundStyle(follow.isFollowing ? Color.accentColor : Color.secondary)
      }
      .buttonStyle(.plain)
      .disabled(follow.isToggling)
      .accessibilityLabel(follow.isFollowing ? "Unfollow" : "Follow")
    }
    .task { await follow.load() }
  }

  @ViewBuilder
  private var subtitle: some View {
    if let count = follow.followerCount {
      Text(count == 1 ? "1 follower" : "\(count) followers")
        .font(.caption)
        .foregroundStyle(.secondary)
    } else {
      Text(request.score == 1 ? "1 vote" : "\(request.score) votes")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }
}
