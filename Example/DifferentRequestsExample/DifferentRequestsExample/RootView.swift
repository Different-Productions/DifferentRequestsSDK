import DifferentRequests
import SwiftUI

/// The app's root: a host app with somewhere to open feedback from.
///
/// This is what an integration looks like. The SDK is not the app — it is a screen presented over
/// one, reached from a row a host puts wherever it makes sense. Everything inside that screen,
/// including which surfaces are reachable, belongs to the SDK.
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

  /// Whether the SDK's screen is up.
  @State private var isShowingRequests = false

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
      home(for: signedIn)
    }
  }

  // MARK: - The host app

  /// A settings screen with one row on it, which is the whole integration.
  private func home(for signedIn: Session.SignedIn) -> some View {
    NavigationStack {
      List {
        Section {
          Button {
            isShowingRequests = true
          } label: {
            HStack {
              Label("Feature requests", systemImage: "list.bullet")
              Spacer()
              if unreadCount > 0 {
                Text("\(unreadCount)")
                  .font(.caption)
                  .foregroundStyle(.white)
                  .padding(.horizontal, 7)
                  .padding(.vertical, 2)
                  .background(Capsule().fill(.red))
              }
            }
          }
        } header: {
          Text("Your app")
        } footer: {
          Text("Everything the SDK draws is behind this row, presented over the app.")
        }
      }
      .navigationTitle("Example")
    }
    .sheet(isPresented: $isShowingRequests) {
      DifferentRequestsView(hub: session.hub)
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
