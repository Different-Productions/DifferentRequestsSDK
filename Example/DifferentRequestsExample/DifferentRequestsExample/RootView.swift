import DifferentRequests
import SwiftUI

/// The app's root. Gates on the sign-in phase and, once ready, presents the SDK surfaces this app's
/// plan includes.
///
/// Which tabs exist comes from `DRAppConfig`, not from this app's own guess. The roadmap and the
/// changelog are Pro surfaces: a tab that answers `PLAN_REQUIRED` when tapped tells the person using
/// the app that something is broken, when nothing is. An absent tab is the honest rendering of an
/// absent feature.
struct RootView: View {
  private let session: Session
  private let pushDelegate: PushRegistrationDelegate

  /// The inbox badge.
  ///
  /// Read through the client rather than from the SDK's own inbox store, because that store is
  /// internal — the SDK exposes screens, not the state behind them. A host app that wants a badge
  /// outside those screens asks the API for the count, which is one read and exactly what the count
  /// route exists for.
  @State private var unreadCount = 0

  init(session: Session, pushDelegate: PushRegistrationDelegate) {
    self.session = session
    self.pushDelegate = pushDelegate
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
    case .unconfigured:
      ContentUnavailableView {
        Label("No app key", systemImage: "key.slash")
      } description: {
        Text(
          """
          Set \(DemoConfig.appKeyEnvironmentVariable) in the scheme's \
          Run › Arguments › Environment Variables, then run again.
          """
        )
      }

    case .creatingSession:
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

    case .ready(let signedIn):
      tabs(for: signedIn)
    }
  }

  // MARK: - Tabs

  private func tabs(for signedIn: Session.SignedIn) -> some View {
    TabView {
      Tab("Requests", systemImage: "list.bullet") {
        DifferentRequestsView(client: session.client)
      }

      if signedIn.config.roadmapEnabled {
        Tab("Roadmap", systemImage: "map") {
          RoadmapView(client: session.client)
        }
      }

      if signedIn.config.changelogEnabled {
        Tab("What's New", systemImage: "sparkles") {
          ChangelogView(client: session.client)
        }
      }

      Tab("Inbox", systemImage: "bell") {
        InboxView(client: session.client)
      }
      .badge(unreadCount)
    }
    .task {
      await refreshUnreadCount()
    }
  }

  /// Reads the badge count once when the tabs appear.
  ///
  /// A failure leaves the count where it was and says nothing: a badge is the least important thing
  /// on screen, and an alert about one would interrupt someone to tell them about a number they had
  /// not looked at.
  private func refreshUnreadCount() async {
    do {
      unreadCount = Int(try await session.client.unreadCount().unreadCount)
    } catch {
      NSLog("Unread count unavailable: %@", error.localizedDescription)
    }
  }
}
