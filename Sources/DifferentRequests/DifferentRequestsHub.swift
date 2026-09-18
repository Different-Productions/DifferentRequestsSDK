import DifferentRequestsProtos
import Foundation

/// Everything the SDK's screens read from, built once by the app that hosts them.
///
/// A SwiftUI view is a value that is thrown away and rebuilt whenever anything above it redraws,
/// so whatever a view constructs is rebuilt with it. State that cannot survive that is not state:
/// a board rebuilt on a parent's redraw loses the pages it had read, where the reader had scrolled
/// to, what they had typed into the search field, and the comment they were halfway through
/// writing. The screens here therefore construct nothing. They are handed this, and it outlives
/// them because the host app is what holds it.
///
/// Build one where the app builds everything else it keeps:
///
/// ```swift
/// @main
/// struct MyApp: App {
///   private let requests = DifferentRequestsHub(client: .make(appKey: "…"))
///
///   var body: some Scene {
///     WindowGroup {
///       NavigationStack {
///         DifferentRequestsView(hub: requests)
///       }
///     }
///   }
/// }
/// ```
///
/// Not observable, and deliberately so: everything worth observing is on the stores this holds, and
/// a host that put this in `@State` would be handing SwiftUI a lifetime the app already owns.
@MainActor
public final class DifferentRequestsHub {

  // MARK: - The API

  /// The client every screen calls through.
  ///
  /// Public because a host app has its own reasons to call the same API — an inbox badge drawn
  /// outside the inbox is one read, and lifting SDK state out of the SDK to get it would be a
  /// second copy of a number the server already answers.
  public let client: DifferentRequestsClient

  /// The host app's own accent and font, as it asked for them.
  ///
  /// Handed over at `init` because it is the host app's look rather than something to fetch. What a
  /// screen is actually drawn in is ``appearanceDrawn``, because the app's plan decides whether this
  /// is used.
  public let appearance: Appearance

  // MARK: - The screens' state

  /// The board's page, its paging cursor, and the text in its search field.
  let board: BoardStore

  /// The roadmap's columns.
  let roadmap: RoadmapStore

  /// The changelog's entries.
  let changelog: ChangelogStore

  /// The inbox's notifications and its unread count.
  let inbox: InboxStore

  /// The composer's draft. One, because one request is written at a time, and the sheet that shows
  /// it is dismissed and re-presented rather than kept.
  let submission: SubmitStore

  /// What this app includes: whether it carries the badge, and which surfaces are reachable.
  /// Read once, by everything that needs it.
  let appConfig: AppConfigStore

  /// One store per request opened, so a pushed screen keeps its thread and its half-written
  /// comment when whatever pushed it redraws.
  let details: RequestDetailStores

  /// When each request was last heard to have changed, so a screen holding an old copy re-reads it
  /// instead of drawing what it read before the change.
  let news: NewsAboutRequests

  /// Who the host app signed in. Read by every screen that offers a control acting for a person.
  let whoIsHere: WhoIsHere

  // MARK: - Init

  /// - Parameter client: The client every screen reads and writes through. Build it with
  ///   ``DifferentRequestsClient/make(appKey:)``.
  ///
  /// This is the SDK's composition root: the one place its long-lived objects are built, each
  /// exactly once and in dependency order. Nothing else in the package constructs a store.
  /// - Parameters:
  ///   - client: The client every screen reads and writes through.
  ///   - appearance: What the screens are drawn in. ``Appearance/standard`` is the SDK's own look,
  ///     named rather than defaulted so an app that has not thought about it says so.
  public init(client: DifferentRequestsClient, appearance: Appearance) {
    self.client = client
    self.appearance = appearance
    self.board = BoardStore(client: client, statuses: [], sort: .top)
    self.roadmap = RoadmapStore(client: client)
    self.changelog = ChangelogStore(client: client)
    self.news = NewsAboutRequests()
    self.whoIsHere = WhoIsHere(client: client)
    self.inbox = InboxStore(client: client, news: news)
    self.submission = SubmitStore(client: client)
    self.appConfig = AppConfigStore(client: client)
    self.details = RequestDetailStores(client: client)
  }

  // MARK: - The look

  /// What every screen is drawn in: the host app's look where this app's plan includes it, and the
  /// SDK's own where it does not.
  ///
  /// Until the configuration has answered, the host app's look is drawn — the same side the badge
  /// errs on, so an app paying for its look never sees ours. Read by each screen as it draws, so the
  /// look follows the configuration the moment it answers.
  var appearanceDrawn: Appearance {
    switch appConfig.badge {
    case .bought, .carried:
      if appConfig.config.appearanceEnabled {
        return appearance
      }
      return .standard
    case .unread, .reading, .failed:
      return appearance
    }
  }

  // MARK: - Reading the board early

  /// Reads the board's first page before a screen asks for it.
  ///
  /// The first page is a round trip. A board that starts one when it appears shows a spinner for
  /// the length of it, and the reader waits having already decided to look. Called while they are
  /// still somewhere else — a settings list, a screen carrying a button that opens this — the page
  /// is held by the time the board is presented, and it draws rows on the first frame.
  ///
  /// Callable as often as a host likes. A board already read is not read again, and a read already
  /// in flight is not started twice, so a button that warms on every appearance costs one round
  /// trip rather than one per appearance.
  public func readTheBoardBeforeItIsShown() async {
    if board.read.hasRead { return }
    await board.load()
  }

  // MARK: - Filing a request

  /// Opens the composer on whatever the board was searched for.
  ///
  /// Seeded rather than blank because reaching the composer from a search means the search did not
  /// answer, and retyping the words would be the price of having looked first. A composer opened
  /// from an unsearched board starts empty, which is the same rule with nothing to carry.
  ///
  /// Public so a host app can offer its own way in — a menu item, a settings row — and get a
  /// composer in the same state the board's own button gives.
  public func beginSubmission() {
    submission.begin(title: board.query)
  }

  /// Files what is in the composer, then re-reads the board it now belongs on.
  ///
  /// The re-read happens here rather than in the sheet because the sheet does not know what
  /// presented it: a request filed from the board's toolbar, from an empty board, or from a host
  /// app's own button all land on the same board, and all of them are looking at a board that is
  /// now one request out of date.
  func fileRequest() async {
    await submission.submit()
    if submission.submitted == nil { return }
    await board.load()
  }

  // MARK: - Reading one request

  /// The store behind one request's screen — the same one every time that request is asked for.
  func detail(requestID: String) -> RequestDetailStore {
    details.store(requestID: requestID)
  }

  // MARK: - News from outside

  /// Tell the SDK that a push about a request landed, so the screen for it reads again rather than
  /// drawing the copy it had before the change.
  ///
  /// Call it from wherever your app receives a notification. The payload carries `requestID`, which
  /// is the id to hand over; a push exists only because that request changed, so the copy anybody
  /// is holding is out of date by definition.
  ///
  /// ```swift
  /// func userNotificationCenter(
  ///   _ center: UNUserNotificationCenter,
  ///   didReceive response: UNNotificationResponse
  /// ) async {
  ///   let payload = response.notification.request.content.userInfo
  ///   if let requestID = payload["requestID"] as? String {
  ///     requests.heardThatARequestChanged(requestID: requestID)
  ///   }
  /// }
  /// ```
  ///
  /// The inbox does the same for itself: every notification it reads says its request changed when
  /// that notification was written, so a reader who opens the inbox instead of the push is served
  /// the same way without your app doing anything.
  public func heardThatARequestChanged(requestID: String) {
    news.heard(aboutRequest: requestID, at: Date())
  }
}
