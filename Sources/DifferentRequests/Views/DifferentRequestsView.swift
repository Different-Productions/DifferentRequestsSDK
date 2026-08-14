import DifferentRequestsProtos
import SwiftUI

/// The board: what people have asked for, ranked by demand, and the way in to asking for
/// something new.
///
/// Drop into a `NavigationStack` the host app owns, reading from the hub the host built once:
///
/// ```swift
/// NavigationStack {
///   DifferentRequestsView(hub: requests)
/// }
/// ```
///
/// Searching, ranking, filtering and reading the board are all the same screen, because they are
/// the same rpc with the same page shape. Each of the three narrowings is one query parameter, and
/// the answer to all of them is a list of requests.
///
/// Asking is reachable from every state the board can be in, the populated one included: a board
/// full of other people's requests is exactly where someone finds out that theirs is not on it,
/// and an affordance that appears only once the board is empty, or only once a search has come
/// back with nothing, is missing at the moment it is most wanted. Whatever is in the search field
/// goes into the composer with them, because the cheapest moment to catch a duplicate is before it
/// is written, and a search that did not answer is already the title.
///
/// The filter bar is reachable from every state for the same reason turned inside out. It is drawn
/// above the content rather than within it, so narrowing the board to a status nothing is in leaves
/// the control that undoes the narrowing exactly where it was.
public struct DifferentRequestsView: View {

  /// How long a search settles before it is sent. Long enough that a typed word is one read
  /// rather than five.
  private static let searchSettleDelay: Duration = .milliseconds(300)

  private static let rowSpacing: CGFloat = 12

  /// What the screen reads from, and what its pushes and its sheet are built against.
  private let hub: DifferentRequestsHub

  /// Bindable for the search field, which writes the query the board reads on. The store belongs
  /// to the hub; this only takes bindings from it.
  @Bindable private var store: BoardStore

  /// Whether the composer is up.
  @State private var isComposing: Bool = false

  /// - Parameter hub: What the host app built once and holds. The board's state lives on it.
  public init(hub: DifferentRequestsHub) {
    self.hub = hub
    self._store = Bindable(hub.board)
  }

  public var body: some View {
    VStack(spacing: 0) {
      BoardFilterBar(store: store)

      content
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .navigationTitle("Requests")
    .searchable(text: $store.query, prompt: "Search requests")
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        askButton
          .labelStyle(.iconOnly)
      }
    }
    .firstRead(store.read) {
      await store.load()
    }
    .task(id: store.query) {
      await runSearch()
    }
    .sheet(isPresented: $isComposing) {
      SubmitRequestView(hub: hub)
    }
  }

  // MARK: - Searching

  /// Reloads the board when the field says something the page on screen does not answer, after
  /// letting a burst of typing settle.
  ///
  /// SwiftUI cancels and restarts this on every keystroke, which is what makes the wait a
  /// debounce; a cancelled wait sends nothing. It also runs again every time this view is built
  /// again, which is why it asks the store what it is already showing first: the board outlives
  /// its own screen now, and reloading it on a redraw would throw away every page after the first
  /// along with where the reader had got to.
  ///
  /// Keyed on the search text alone, and only the search text is debounced here. A chip on the
  /// filter bar is one tap rather than a burst of them, so it sets and re-reads through the store
  /// in one call and waits for nothing.
  private func runSearch() async {
    if store.isCurrent { return }
    if store.query.isEmpty == false {
      do {
        try await Task.sleep(for: Self.searchSettleDelay)
      } catch {
        return
      }
    }
    await store.load()
  }

  // MARK: - Content

  /// Four outcomes, from one state. A board that has read and found nothing looks nothing like
  /// one still reading, and the list stays up through a refresh even while its rows are being
  /// replaced — a pull-to-refresh runs on the list's own task, and a list that disappears takes
  /// that task with it.
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
      empty
    case .loaded(let requests), .refreshing(let requests):
      list(requests)
    }
  }

  /// Nothing to show, and four reasons it can be nothing — read off ``BoardNarrowing``, which is
  /// where the sentence for each of them is written.
  ///
  /// A board narrowed to a status has one more thing left to try than a board that is simply
  /// empty, and it is the more likely of the two to work: the requests are there, behind a control
  /// the reader set themselves and may have scrolled past since. So widening leads, and asking
  /// follows it.
  private var empty: some View {
    ContentUnavailableView {
      Label(store.narrowing.emptyTitle, systemImage: store.narrowing.emptyIcon)
    } description: {
      Text(store.narrowing.emptyMessage)
    } actions: {
      if store.narrowing.isStatusFiltered {
        AsyncButton {
          await store.showEveryStatus()
        } label: {
          Text("Show every status")
        }
        .buttonStyle(.borderedProminent)

        askButton
          .buttonStyle(.bordered)
      } else {
        askButton
          .buttonStyle(.borderedProminent)
      }
    }
  }

  private func list(_ requests: [DRFeatureRequest]) -> some View {
    List {
      if let failure = store.write.failure {
        Section {
          WriteFailureNotice(failure: failure) {
            store.acknowledgeWriteFailure()
          }
        }
      }

      ForEach(requests, id: \.id) { request in
        row(request)
      }

      if store.page.isDone == false {
        NextPageRow(state: store.page) {
          await store.loadMore()
        }
      }

      Section {
        askButton
          .buttonStyle(.borderedProminent)
          .frame(maxWidth: .infinity, alignment: .center)
      } footer: {
        Text(store.narrowing.listFooter)
      }
    }
    .listStyle(.plain)
    .refreshable {
      await store.load()
    }
  }

  /// The vote control sits beside the link rather than inside its label: a button inside a
  /// `NavigationLink` label never receives the tap, so a vote there would push the detail
  /// instead.
  ///
  /// Every control on the board goes inert while any one of them is writing, because the store
  /// takes one vote at a time. Without that, a tap on a second row during the first row's round
  /// trip is refused by the store and nothing at all happens on screen — the same silence this
  /// surface exists to stop.
  private func row(_ request: DRFeatureRequest) -> some View {
    HStack(alignment: .top, spacing: Self.rowSpacing) {
      VoteControl(
        voteCount: Int(request.voteCount),
        voted: request.viewer.voted,
        isWriting: store.write.isWriting
      ) {
        await store.toggleVote(requestID: request.id)
      }

      NavigationLink {
        RequestDetailView(hub: hub, requestID: request.id)
      } label: {
        RequestSummary(request: request)
      }
    }
  }

  /// The way in to the composer: in the bar, and again under the list.
  ///
  /// Two places rather than one because they answer different moments. The bar is reachable
  /// without scrolling and is where someone goes who arrived already knowing what they want; the
  /// end of the list is where someone lands who has just read everything that is there and found
  /// nothing of theirs.
  private var askButton: some View {
    Button {
      hub.beginSubmission()
      isComposing = true
    } label: {
      Label("Ask for a feature", systemImage: "plus.bubble")
    }
  }
}

// MARK: - Request Summary

/// What a request says and where it sits, as the tappable half of a board row.
private struct RequestSummary: View {

  private static let metadataSpacing: CGFloat = 8
  private static let bodyLineLimit: Int = 2

  let request: DRFeatureRequest

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(request.title)
        .font(.headline)

      if request.body.isEmpty == false {
        Text(request.body)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .lineLimit(Self.bodyLineLimit)
      }

      HStack(spacing: Self.metadataSpacing) {
        StatusBadge(status: request.status)

        if request.commentCount > 0 {
          Label(request.commentCount.formatted(), systemImage: "bubble.left")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()

        if request.hasCreatedAt {
          Text(request.createdAt.date.formatted(.relative(presentation: .named)))
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
      }
    }
  }
}
