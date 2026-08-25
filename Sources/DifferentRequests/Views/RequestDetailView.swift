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

  /// The height the composer occupies, which whatever stands in for it keeps: a strip that grows
  /// and shrinks as the answer arrives moves the thread above it under the reader's eye.
  private static let composerSpacing: CGFloat = 4
  private static let composerPadding: CGFloat = 8

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

      composer
    }
  }

  // MARK: - Answering

  /// Four outcomes on a question the composer cannot answer for itself: whether this app takes
  /// comments at all.
  ///
  /// A field with a Send that has one possible answer is worse than no field — someone writes a
  /// reply, sends it, and is told by a failure that the discussion was never open. So the slot is
  /// the composer only once the app has said it takes them, and says what is there instead
  /// otherwise. Voting is on the screen above either way, which is what the absent case points at.
  @ViewBuilder
  private var composer: some View {
    switch store.commenting {
    case .unread, .reading:
      ProgressView()
        .frame(maxWidth: .infinity)
        .padding(.vertical, Self.composerPadding)
    case .failed:
      RetryRow(message: "Couldn't tell whether this app takes comments.") {
        await store.loadCommenting()
      }
      .padding(.horizontal)
      .padding(.vertical, Self.composerPadding)
    case .excluded:
      commentsOff
    case .included:
      CommentComposer(
        draft: $store.draft,
        canSend: store.canPostComment,
        isWriting: store.write.isWriting
      ) {
        await store.postComment()
      }
    }
  }

  /// The same words `AbsentSurface` gives a whole screen, in the strip the composer would have
  /// had. A screen-sized empty state cannot go here: there is a request above it that is still
  /// worth reading, and it is what the reader came for.
  private var commentsOff: some View {
    VStack(alignment: .leading, spacing: Self.composerSpacing) {
      Label(PlanSurface.comments.absentTitle, systemImage: PlanSurface.comments.absentSymbol)
        .font(.subheadline)

      Text(PlanSurface.comments.absentDescription)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal)
    .padding(.vertical, Self.composerPadding)
  }

  // MARK: - The request

  @ViewBuilder
  private func header(_ request: DRFeatureRequest) -> some View {
    VStack(alignment: .leading, spacing: Self.headerSpacing) {
      Text(request.title)
        .font(.title3)
        .fontWeight(.semibold)

      HStack(spacing: Self.metadataSpacing) {
        StatusBadge(state: request.state)

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

      // One switch over one state. A refusal is drawn only by the arm that carries one, so the
      // screen that showed a shipped request with a decline notice under it — legal on the wire
      // until the contract made the state one thing — has nowhere to come from.
      switch request.state {
      case .declined(let decline):
        declineNotice(decline)
      case .merged(let merged):
        mergedLink(merged.intoRequestID)
      case .open, .planned, .inProgress, .shipped:
        EmptyView()
      case .none:
        // Written before the state existed, or by a server newer than this build. The badge above
        // says so; there is nothing further this version knows how to draw.
        EmptyView()
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
