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
/// holding a link to it is owed that instead of a dead end. A request that has actually gone says
/// so, which is a different screen from one that could not be reached: there is nothing to retry.
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
      .firstRead(store.read) {
        await store.load()
      }
  }

  // MARK: - Content

  /// Four outcomes, from one state. "Gone" and "unreachable" are two of them and not one: a
  /// request the server says is not there gets no Try Again, because there is nothing on the
  /// other side of it to try again for.
  @ViewBuilder
  private var content: some View {
    switch store.read {
    case .unread, .reading:
      ProgressView()
    case .failed:
      LoadFailure {
        await store.load()
      }
    case .empty:
      ContentUnavailableView {
        Label("This request is gone", systemImage: "questionmark.folder")
      } description: {
        Text("It was removed, or the link that got you here is out of date.")
      }
    case .loaded(let request), .refreshing(let request):
      loaded(request)
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
        isWriting: store.write.isWriting
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
        VoteControl(
          voteCount: Int(request.voteCount),
          voted: request.viewer.voted,
          isWriting: store.write.isWriting
        ) {
          await store.toggleVote()
        }

        followButton(request)

        Spacer()
      }

      // Directly under the two controls that write, which is where whoever tapped one is
      // looking. Every write on this screen — vote, follow, comment — reports here.
      if let failure = store.write.failure {
        WriteFailureNotice(failure: failure) {
          store.acknowledgeWriteFailure()
        }
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
    .disabled(store.write.isWriting)
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

  /// Four outcomes again, on the read that is not the request's. A discussion that could not be
  /// read says so and offers to try again; one that is genuinely empty says that instead. Drawn
  /// as one thing they are blank space under a heading that says "Discussion", which reads as a
  /// request nobody has replied to whichever of the two is true.
  @ViewBuilder
  private var thread: some View {
    switch store.thread {
    case .unread, .reading:
      ProgressView()
        .frame(maxWidth: .infinity)
    case .failed:
      RetryRow(message: "Couldn't load the discussion.") {
        await store.load()
      }
    case .empty:
      Text("No comments yet.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    case .loaded(let comments), .refreshing(let comments):
      ForEach(comments, id: \.id) { comment in
        CommentRow(comment: comment)
      }

      if store.page.isDone == false {
        NextPageRow(state: store.page) {
          await store.loadMore()
        }
      }
    }
  }
}
