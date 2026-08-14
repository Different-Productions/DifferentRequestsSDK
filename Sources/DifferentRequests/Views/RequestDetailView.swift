import DifferentRequestsProtos
import SwiftUI

/// One request: what was asked for, where it sits, and what has been said about it.
///
/// Pushed from the board, or opened straight from a notification or a deep link:
///
/// ```swift
/// NavigationStack {
///   RequestDetailView(hub: requests, requestID: id)
/// }
/// ```
///
/// A merged request answers here rather than 404ing, and says where the vote went — someone
/// holding a link to it is owed that instead of a dead end.
///
/// The hub hands back the same store for the same request every time, so a screen pushed from a
/// board that redraws keeps its thread, its place in it, and the comment being written.
public struct RequestDetailView: View {

  private static let headerSpacing: CGFloat = 10
  private static let actionSpacing: CGFloat = 16
  private static let metadataSpacing: CGFloat = 8

  /// What the screen reads from, and what a push from here is built against.
  private let hub: DifferentRequestsHub

  /// Bindable for the composer, which edits the draft the store holds.
  @Bindable private var store: RequestDetailStore

  /// - Parameters:
  ///   - hub: What the host app built once and holds.
  ///   - requestID: Which request to show.
  public init(hub: DifferentRequestsHub, requestID: String) {
    self.hub = hub
    self._store = Bindable(hub.detail(requestID: requestID))
  }

  public var body: some View {
    content
      .navigationTitle("Request")
      .firstRead(hasLoaded: store.hasLoaded) {
        await store.load()
      }
  }

  // MARK: - Content

  @ViewBuilder
  private var content: some View {
    if store.hasLoaded == false {
      ProgressView()
    } else if let request = store.request {
      loaded(request)
    } else {
      LoadFailure {
        await store.load()
      }
    }
  }

  /// The thread scrolls; the composer does not, so a reader who has scrolled up can still answer
  /// without scrolling back.
  private func loaded(_ request: DRFeatureRequest) -> some View {
    VStack(spacing: 0) {
      List {
        Section {
          header(request)
        }

        Section {
          thread
        } header: {
          Text("Discussion")
        }
      }
      .refreshable {
        await store.load()
      }

      Divider()

      CommentComposer(
        draft: $store.draft,
        canSend: store.canPostComment,
        isWriting: store.isWriting
      ) {
        await store.postComment()
      }
    }
  }

  // MARK: - The request

  @ViewBuilder
  private func header(_ request: DRFeatureRequest) -> some View {
    VStack(alignment: .leading, spacing: Self.headerSpacing) {
      Text(request.title)
        .font(.title3)
        .fontWeight(.semibold)

      HStack(spacing: Self.metadataSpacing) {
        StatusBadge(status: request.status)

        Text(authorName(request))
          .font(.caption)
          .foregroundStyle(.secondary)

        Spacer()

        if request.hasCreatedAt {
          Text(request.createdAt.date.formatted(.relative(presentation: .named)))
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
      }

      if request.body.isEmpty == false {
        Text(request.body)
          .font(.body)
      }

      if request.hasDecline {
        declineNotice(request.decline)
      }

      if request.mergedIntoRequestID.isEmpty == false {
        mergedLink(request.mergedIntoRequestID)
      }

      HStack(spacing: Self.actionSpacing) {
        VoteControl(voteCount: Int(request.voteCount), voted: request.viewer.voted) {
          await store.toggleVote()
        }

        followButton(request)

        Spacer()
      }
    }
  }

  /// A decline the author can read. The contract requires a reason in this state, because a
  /// refusal with no reason reads as being ignored.
  @ViewBuilder
  private func declineNotice(_ decline: DRRequestDecline) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      if decline.reason.label.isEmpty == false {
        Text(decline.reason.label)
          .font(.subheadline)
          .fontWeight(.semibold)
      }
      if decline.reason.description_p.isEmpty == false {
        Text(decline.reason.description_p)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      if decline.note.isEmpty == false {
        Text(decline.note)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
  }

  private func mergedLink(_ requestID: String) -> some View {
    NavigationLink {
      RequestDetailView(hub: hub, requestID: requestID)
    } label: {
      Label(
        "Folded into another request — your vote went with it",
        systemImage: "arrow.triangle.merge"
      )
      .font(.subheadline)
    }
  }

  private func followButton(_ request: DRFeatureRequest) -> some View {
    AsyncButton {
      await store.toggleFollow()
    } label: {
      Label(
        request.viewer.isFollowing ? "Following" : "Follow",
        systemImage: request.viewer.isFollowing ? "bell.fill" : "bell"
      )
      .font(.subheadline)
    }
    .buttonStyle(.bordered)
  }

  /// The contract says an author is absent for a deleted account and that this is normal, so it
  /// reads as anonymous rather than as a blank line.
  private func authorName(_ request: DRFeatureRequest) -> String {
    if request.hasAuthor, request.author.displayName.isEmpty == false {
      return request.author.displayName
    }
    return "Anonymous"
  }

  // MARK: - The thread

  @ViewBuilder
  private var thread: some View {
    if store.comments.isEmpty, store.hasMore == false {
      Text("No comments yet.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    } else {
      ForEach(store.comments, id: \.id) { comment in
        CommentRow(comment: comment)
      }

      if store.hasMore {
        ProgressView()
          .frame(maxWidth: .infinity)
          .task {
            await store.loadMore()
          }
      }
    }
  }
}
