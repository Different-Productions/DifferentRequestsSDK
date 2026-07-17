import SwiftUI
import DifferentRequests

/// The app's root. Gates on the sign-in phase and, once ready, presents every
/// SDK surface as a tab. Owns a `NotificationCenterModel` purely to drive the
/// Inbox tab's unread badge (the `NotificationCenterView` keeps its own model
/// for the list itself).
struct RootView: View {
  private let session: Session
  private let pushDelegate: PushRegistrationDelegate
  @State private var inbox: NotificationCenterModel

  init(session: Session, pushDelegate: PushRegistrationDelegate) {
    self.session = session
    self.pushDelegate = pushDelegate
    self._inbox = State(initialValue: NotificationCenterModel(client: session.client))
  }

  var body: some View {
    phaseContent
      .task {
        pushDelegate.tokenHandler = { tokenData in
          Task { await session.registerDevice(tokenData: tokenData) }
        }
        await session.start()
      }
  }

  // MARK: - Phases

  @ViewBuilder
  private var phaseContent: some View {
    switch session.phase {
    case .authenticating:
      ProgressView("Signing in…")
    case .failed(let message):
      ContentUnavailableView {
        Label("Sign-in failed", systemImage: "person.crop.circle.badge.exclamationmark")
      } description: {
        Text(message)
      } actions: {
        Button("Try Again") {
          Task { await session.start() }
        }
      }
    case .ready:
      tabs
    }
  }

  // MARK: - Tabs

  private var tabs: some View {
    TabView {
      DifferentRequestsView(client: session.client)
        .tabItem { Label("Requests", systemImage: "list.bullet") }

      FollowingView(client: session.client)
        .tabItem { Label("Following", systemImage: "star") }

      RoadmapView(client: session.client)
        .tabItem { Label("Roadmap", systemImage: "map") }

      ChangelogView(client: session.client)
        .tabItem { Label("What's New", systemImage: "sparkles") }

      NotificationCenterView(client: session.client)
        .tabItem { Label("Inbox", systemImage: "bell") }
        .badge(unreadBadge)
    }
    .task {
      await inbox.refreshUnreadCount()
    }
  }

  /// The Inbox tab badge. Zero renders as no badge, which is also the right
  /// display before the first unread count comes back.
  private var unreadBadge: Int {
    if let count = inbox.unreadCount {
      return count
    }
    return 0
  }
}
