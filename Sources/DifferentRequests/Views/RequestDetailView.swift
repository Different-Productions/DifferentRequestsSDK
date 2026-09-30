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
/// A duplicate answers here rather than 404ing, and says where the vote went — someone
/// holding a link to it is owed that instead of a dead end. A request that has actually gone says
/// so, which is a different screen from one that could not be reached: there is nothing to retry.
///
/// The screen owns its store as `@State`, so it keeps its thread, its place in it and the comment
/// being written while the board that pushed it redraws, and the store is freed when the screen is
/// popped.
public struct RequestDetailView: View {

  private static let headerSpacing: CGFloat = 10
  private static let actionSpacing: CGFloat = 16
  private static let metadataSpacing: CGFloat = 8

  /// What the screen reads from, and what a push from here is built against.
  private let hub: DifferentRequestsHub

  /// This screen's own store, alive exactly as long as the screen is on the navigation stack.
  @State var store: RequestDetailStore

  /// Which request this screen is about, so news about it can be asked for by id.
  private let requestID: String

  /// - Parameters:
  ///   - hub: What the host app built once and holds.
  ///   - requestID: Which request to show.
  public init(hub: DifferentRequestsHub, requestID: String) {
    self.hub = hub
    self.requestID = requestID
    self._store = State(
      initialValue: RequestDetailStore(
        client: hub.client,
        requestID: requestID,
        notificationOffer: hub.notificationOffer,
        firstVoteNote: hub.firstVoteNote
      )
    )
  }

  public var body: some View {
    content
      .navigationTitle(Text("Request", bundle: .module, comment: "Title of one feature request's screen"))
      .worn(by: hub.appearanceDrawn)
      .sheetMinimumSize()
      .onDisappear {
        hub.firstVoteNote.putAway()
      }
      .task {
        await hub.whoIsHere.read()
        // Read when there is nothing, and read again when this request changed after the copy
        // here arrived. An alert exists because it changed, so a screen opened from one would
        // otherwise draw exactly what the alert came to correct.
        if store.read.hasRead == false {
          await store.load()
        } else if hub.news.hasNews(aboutRequest: requestID, newerThan: store.readAt) {
          await store.load()
        }
      }
  }

  // MARK: - Content

  /// Four outcomes, from one state. "Gone" and "unreachable" are two of them and not one: a
  /// request the server says is not there gets no Try again, because there is nothing on the
  /// other side of it to try again for.
  @ViewBuilder
  private var content: some View {
    switch store.read {
    case .unread, .reading:
      ProgressView()
    case .failed(let error):
      LoadFailure(error: error) {
        await store.load()
      }
    case .empty:
      ContentUnavailableView {
        Label {
          Text("This request is gone", bundle: .module, comment: "Heading when a request no longer exists")
        } icon: {
          Image(systemName: "questionmark.folder")
        }
      } description: {
        Text(
          "It was removed, or the link that got you here is out of date.",
          bundle: .module,
          comment: "Message when a request no longer exists"
        )
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

        if hub.notificationOffer.isOffered(on: request.id) {
          Section {
            NotificationOfferCard(offer: hub.notificationOffer)
          }
        }

        Section {
          thread
        } header: {
          Text("Comments", bundle: .module, comment: "Header over a request's comments")
        }
      }
      .scrollDismissesKeyboard(.interactively)
      .refreshable {
        await store.load()
      }

      // Commenting acts for a person, so with nobody signed in the strip is not drawn at all.
      if hub.whoIsHere.somebodyIsHere {
        Divider()

        composer
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
        StatusBadge(state: request.state)

        Text(authorName(request))
          .font(.caption)
          .foregroundStyle(.secondary)

        Spacer()

        if request.hasCreatedAt {
          Text(request.createdAt.date.ago)
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
      case .duplicate(let duplicate):
        theRequestThisDuplicates(duplicate.duplicateOfRequestID)
      case .open, .planned, .inProgress, .shipped:
        EmptyView()
      case .none:
        // Written before the state existed, or by a server newer than this build. The badge above
        // says so; there is nothing further this version knows how to draw.
        EmptyView()
      }

      HStack(spacing: Self.actionSpacing) {
        if hub.whoIsHere.somebodyIsHere {
          VoteControl(
            voteCount: Int(request.voteCount),
            voted: request.viewer.voted,
            isWriting: store.write.isWriting
          ) {
            await store.toggleVote()
          }

          followButton(request)
        } else {
          VoteTally(voteCount: Int(request.voteCount), voted: request.viewer.voted)
        }

        Spacer()
      }

      if hub.firstVoteNote.requestID == request.id {
        Text("You'll be told when this changes.", bundle: .module, comment: "One-time line after a person's first vote on this phone")
          .font(.subheadline)
          .foregroundStyle(.secondary)
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

  private func theRequestThisDuplicates(_ requestID: String) -> some View {
    NavigationLink {
      RequestDetailView(hub: hub, requestID: requestID)
    } label: {
      Label {
        Text(
          "Someone already asked for this. Your vote moved to their request.",
          bundle: .module,
          comment: "Link on a request the team merged into an earlier one"
        )
      } icon: {
        Image(systemName: "arrow.triangle.merge")
      }
      .font(.subheadline)
    }
  }

  /// Filled with a checkmark while following and plain while not, so the two read apart at a
  /// glance rather than by the bell alone.
  @ViewBuilder
  private func followButton(_ request: DRFeatureRequest) -> some View {
    if request.viewer.isFollowing {
      AsyncButton {
        await store.toggleFollow()
      } label: {
        Label {
          Text("Following", bundle: .module, comment: "Button showing the reader follows a request; a tap unfollows")
        } icon: {
          Image(systemName: "checkmark")
        }
        .font(.subheadline)
          .foregroundStyle(.white)
      }
      .buttonStyle(.borderedProminent)
      .disabled(store.write.isWriting)
    } else {
      AsyncButton {
        await store.toggleFollow()
      } label: {
        Label {
          Text("Follow", bundle: .module, comment: "Button that follows a request to get updates on it")
        } icon: {
          Image(systemName: "bell")
        }
        .font(.subheadline)
      }
      .buttonStyle(.bordered)
      .disabled(store.write.isWriting)
    }
  }

  /// "Deleted user" once the person who asked is deleted, "The team" for a request the app's team
  /// filed, the name their app gave, or "Anonymous" when it gave none.
  private func authorName(_ request: DRFeatureRequest) -> String {
    if request.authorDeleted {
      return String(localized: "Deleted user", bundle: .module, comment: "Author name for a request whose person was deleted")
    }
    if request.hasAuthor == false {
      return String(localized: "The team", bundle: .module, comment: "Author name for a request the app's team filed")
    }
    if request.author.displayName.isEmpty {
      return String(localized: "Anonymous", bundle: .module, comment: "Author name for a request whose person gave no name")
    }
    return request.author.displayName
  }
}
