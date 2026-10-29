import DifferentRequestsProtos
import Foundation
import SwiftUI

/// Everything the SDK's screens read from, built once by the app that hosts them.
///
/// A SwiftUI view is a value that is thrown away and rebuilt whenever anything above it redraws,
/// so whatever a view constructs is rebuilt with it. State that cannot survive that is not state:
/// a board rebuilt on a parent's redraw loses the pages it had read, where the reader had scrolled
/// to, what they had typed into the search field, and the comment they were halfway through
/// writing. The screens here therefore construct nothing. They are handed this, and it outlives
/// them because the host app is what holds it.
///
/// Build one where the app builds everything else it keeps, and await ``configure()`` at launch:
///
/// ```swift
/// @main
/// struct MyApp: App {
///   private let requests = DifferentRequestsHub(
///     client: DifferentRequestsClient(appKey: "…", baseURL: SecureBaseURL(service: .production)),
///     emptyBoard: EmptyBoard(),
///     notificationPermission: .askedBySdk
///   )
///
///   var body: some Scene {
///     WindowGroup {
///       DifferentRequestsView(hub: requests)
///         .task {
///           await requests.configure()
///         }
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
  /// Public because a host app has its own reasons to call the same API: signing a person in,
  /// registering a device. An inbox badge is not one of them — it is ``unreadCount()``, the number
  /// the SDK's own Inbox tab draws, so the two never disagree.
  public let client: DifferentRequestsClient

  /// What a board with nothing on it says, as the host app asked for it. What is drawn is
  /// ``emptyBoardDrawn()``, because the app's plan decides whether this is used.
  public let emptyBoard: EmptyBoard

  /// Who asks the person for notification permission, as the host app set it.
  public let notificationPermission: NotificationPermission

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

  /// When each request was last heard to have changed, so a screen holding an old copy re-reads it
  /// instead of drawing what it read before the change.
  let news: NewsAboutRequests

  /// Who the host app signed in. Read by every screen that offers a control acting for a person.
  let whoIsHere: WhoIsHere

  /// The "Get notified when this request changes?" card, offered after a first vote or follow.
  let notificationOffer: NotificationOffer

  /// The one-time "You'll get an update in Inbox when this request changes." line after the first
  /// vote on this phone.
  let firstVoteNote: FirstVoteNote

  // MARK: - Init

  /// - Parameter client: The client every screen reads and writes through. Build it with
  ///   ``DifferentRequestsClient/init(appKey:baseURL:)``.
  ///
  /// This is the SDK's composition root: the one place its long-lived objects are built, each
  /// exactly once and in dependency order. The one store built elsewhere is a request screen's own,
  /// which lives as long as that screen does.
  /// - Parameters:
  ///   - client: The client every screen reads and writes through.
  ///   - emptyBoard: What a board with nothing on it says. `EmptyBoard()` is the SDK's own words,
  ///     written out at the call site so an app that has not thought about it says so.
  ///   - notificationPermission: Who asks for notification permission. ``NotificationPermission/askedBySdk``
  ///     lets the SDK offer its card and Apple's prompt; ``NotificationPermission/askedByApp`` leaves
  ///     asking to the host app, and the SDK never prompts.
  public init(
    client: DifferentRequestsClient,
    emptyBoard: EmptyBoard,
    notificationPermission: NotificationPermission
  ) {
    self.client = client
    self.emptyBoard = emptyBoard
    self.notificationPermission = notificationPermission
    self.news = NewsAboutRequests()
    self.appConfig = AppConfigStore(client: client)
    self.notificationOffer = NotificationOffer(
      permission: notificationPermission,
      appConfig: appConfig,
      defaults: .standard
    )
    self.firstVoteNote = FirstVoteNote(defaults: .standard)
    self.board = BoardStore(
      client: client,
      news: news,
      notificationOffer: notificationOffer,
      board: BoardState(sort: .top)
    )
    self.roadmap = RoadmapStore(client: client)
    self.changelog = ChangelogStore(client: client)
    self.whoIsHere = WhoIsHere(client: client)
    self.inbox = InboxStore(client: client, news: news)
    self.submission = SubmitStore(client: client)
  }

  // MARK: - Launch

  /// Reads what this app includes: its plan's screens, the badge, and the tint chosen in the
  /// dashboard.
  ///
  /// Await it once at launch, before your first window, the way you would any other launch work.
  /// No screen is drawn until this has answered, so a screen opened after it draws the right tabs,
  /// badge and color on its first frame:
  ///
  /// ```swift
  /// @main
  /// struct MyApp: App {
  ///   private let requests = DifferentRequestsHub(…)
  ///
  ///   var body: some Scene {
  ///     WindowGroup {
  ///       ContentView(requests: requests)
  ///         .task {
  ///           await requests.configure()
  ///         }
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// A read that fails is read again by the next screen that opens. One that answered is not read
  /// again for the life of the client.
  public func configure() async {
    await appConfig.load()
  }

  // MARK: - The look

  /// The color every screen is tinted with in the mode being drawn: the tint chosen in the
  /// dashboard, or the system tint where none was chosen or the plan leaves the app's own look out.
  func tintDrawn(in colorScheme: ColorScheme) -> DrawnTint {
    appConfig.config.dashboardTint(in: colorScheme)
  }

  /// The family every screen is set in: the one chosen in the dashboard where this app's plan
  /// includes its own look, and the system's default family before the configuration has answered
  /// or where the plan leaves it out.
  func fontDrawn() -> Font.Design {
    if usesHostAppearance() {
      return appConfig.config.fontFamily.fontDesign()
    }
    return Font.Design.default
  }

  /// What a board with nothing on it says: the host app's words where its plan includes its own
  /// look, and the SDK's where it does not. Read only once the configuration has answered: `WornLook`
  /// draws no screen before then.
  func emptyBoardDrawn() -> EmptyBoard {
    if usesHostAppearance() {
      return emptyBoard.filledIn()
    }
    return EmptyBoard().filledIn()
  }

  /// Whether the host app's own look is drawn: the configuration answered and the plan includes it.
  private func usesHostAppearance() -> Bool {
    switch appConfig.badge.state {
    case .bought, .carried:
      return appConfig.config.appearanceEnabled
    case .none, .reading, .failed:
      return false
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
    if board.hasRead() == false {
      await board.load()
    }
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
    submission.begin(title: board.board.query)
  }

  /// Files what is in the composer, then re-reads the board it now belongs on.
  ///
  /// The re-read happens here rather than in the sheet because the sheet does not know what
  /// presented it: a request filed from the board's toolbar, from an empty board, or from a host
  /// app's own button all land on the same board, and all of them are looking at a board that is
  /// now one request out of date.
  func fileRequest() async {
    await submission.submit()
    if submission.draft.hasSubmitted {
      await board.load()
    }
  }

  // MARK: - The inbox

  /// How many updates the signed-in person has not opened, as the server last counted them.
  ///
  /// The one count every Inbox badge draws: the SDK's own Inbox tab, and a host app's row or icon.
  /// Observable — read it in a view's body and the view redraws when it changes. It changes when
  /// the inbox is read, when an update is opened or marked read, and when
  /// ``heardThatARequestChanged(requestID:)`` is told a push landed.
  public func unreadCount() -> Int32 {
    inbox.inbox.unreadCount
  }

  /// Reads the inbox's first page and its unread count, where somebody is signed in.
  ///
  /// Await it once the host app has signed somebody in, so a badge drawn before the Inbox is ever
  /// opened has a count. One asked for while a read is in flight is not started beside it: the
  /// read in flight reads again when it lands.
  public func loadInbox() async {
    await whoIsHere.read()
    if whoIsHere.somebodyIsHere() {
      await inbox.load()
    }
  }

  // MARK: - News from outside

  /// Tell the SDK that a push about a request landed, so every screen holding that request reads it
  /// again, and the inbox and its unread count read the update the push announced.
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
  ///     await requests.heardThatARequestChanged(requestID: requestID)
  ///   }
  /// }
  /// ```
  ///
  /// The inbox does the same for itself: every notification it reads says its request changed when
  /// that notification was written, so a reader who opens the inbox instead of the push is served
  /// the same way without your app doing anything.
  public func heardThatARequestChanged(requestID: String) async {
    news.heard(aboutRequest: requestID, at: Date())
    await loadInbox()
  }
}
