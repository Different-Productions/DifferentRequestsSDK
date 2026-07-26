import DifferentRequestsProtos
import SwiftUI

/// The board: what people have asked for, ranked by demand, and the way in to asking for
/// something new.
///
/// Drop into a `NavigationStack` the host app owns:
///
/// ```swift
/// NavigationStack {
///   DifferentRequestsView(client: client)
/// }
/// ```
///
/// Searching and reading the board are the same screen, because they are the same rpc with the
/// same ranking and the same page shape. There is no bare "new request" button: the search field
/// is the way to the submit sheet, and it carries what was typed with it. The cheapest moment to
/// catch a duplicate is before it is written, and a board nobody searched first is where
/// duplicates come from.
public struct DifferentRequestsView: View {

  /// How long a search settles before it is sent. Long enough that a typed word is one read
  /// rather than five.
  private static let searchSettleDelay: Duration = .milliseconds(300)

  private static let rowSpacing: CGFloat = 12

  private let client: DifferentRequestsClient

  /// Bindable for the search field, which writes the query the board reads on.
  @Bindable private var store: BoardStore

  /// Whether the submit sheet is up.
  @State private var isComposing: Bool = false

  /// - Parameter client: The client the board reads and votes through.
  public init(client: DifferentRequestsClient) {
    self.client = client
    self._store = Bindable(wrappedValue: BoardStore(client: client, statuses: [], sort: .top))
  }

  public var body: some View {
    content
      .navigationTitle("Requests")
      .searchable(text: $store.query, prompt: "Search requests")
      .firstRead(hasLoaded: store.hasLoaded) {
        await store.load()
      }
      .task(id: store.query) {
        await runSearch()
      }
      .sheet(isPresented: $isComposing) {
        SubmitRequestView(client: client, title: store.query) {
          await store.load()
        }
      }
  }

  // MARK: - Searching

  /// Reloads the board for the current query, after letting a burst of typing settle.
  ///
  /// SwiftUI cancels and restarts this on every keystroke, which is what makes the wait a
  /// debounce; a cancelled wait sends nothing. The first read is not a search and does not wait.
  private func runSearch() async {
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

  /// The list stays up while a read is in flight even with nothing in it, and not only because an
  /// empty state that flashes on every refresh is noise: a pull-to-refresh runs on the list's own
  /// task, and a page cleared at the start of a read would take the list — and the read with it.
  @ViewBuilder
  private var content: some View {
    if store.hasLoaded == false {
      ProgressView()
    } else if store.requests.isEmpty == false || store.isLoading {
      list
    } else if store.loadError != nil {
      LoadFailure {
        await store.load()
      }
    } else {
      empty
    }
  }

  /// Nothing to show, for one of two reasons that lead to the same place: ask for it. An empty
  /// board is the one state that offers the sheet without a search behind it, because there is
  /// nothing there to be a duplicate of.
  @ViewBuilder
  private var empty: some View {
    if store.query.isEmpty {
      ContentUnavailableView {
        Label("No requests yet", systemImage: "tray")
      } description: {
        Text("Nobody has asked for anything. Be first.")
      } actions: {
        askButton
      }
    } else {
      ContentUnavailableView {
        Label("Nothing matches", systemImage: "magnifyingglass")
      } description: {
        Text("Nobody has asked for this yet.")
      } actions: {
        askButton
      }
    }
  }

  private var list: some View {
    List {
      ForEach(store.requests, id: \.id) { request in
        row(request)
      }

      if store.hasMore {
        loadMoreRow
      }

      if store.query.isEmpty == false {
        Section {
          askButton
            .frame(maxWidth: .infinity, alignment: .center)
        } footer: {
          Text("Vote for one of these if it already says it — duplicates split the demand.")
        }
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
  private func row(_ request: DRFeatureRequest) -> some View {
    HStack(alignment: .top, spacing: Self.rowSpacing) {
      VoteControl(voteCount: Int(request.voteCount), voted: request.viewer.voted) {
        await store.toggleVote(requestID: request.id)
      }

      NavigationLink {
        RequestDetailView(client: client, requestID: request.id)
      } label: {
        RequestSummary(request: request)
      }
    }
  }

  /// Appears under the last row, and pages when it does.
  private var loadMoreRow: some View {
    ProgressView()
      .frame(maxWidth: .infinity)
      .task {
        await store.loadMore()
      }
  }

  private var askButton: some View {
    Button {
      isComposing = true
    } label: {
      Label("Ask for a feature", systemImage: "plus.bubble")
    }
    .buttonStyle(.borderedProminent)
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
