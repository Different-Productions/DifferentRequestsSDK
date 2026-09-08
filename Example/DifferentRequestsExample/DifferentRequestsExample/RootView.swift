import DifferentRequests
import SwiftUI

/// The app's root: a host app with somewhere to open feedback from.
///
/// This is what an integration looks like. The SDK is not the app — it is a set of screens
/// presented over one, reached from rows a host puts wherever they make sense.
///
/// Nothing here decides anything. Which rows exist, what the badge says, and which screen is up are
/// all read off ``Session``; this draws them and navigates.
struct RootView: View {
  private let session: Session

  init(session: Session) {
    self.session = session
  }

  var body: some View {
    phaseContent
      .task {
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

    case .ready:
      home
    }
  }

  // MARK: - The host app

  /// A settings list with one row per surface, which is the whole integration.
  private var home: some View {
    NavigationStack {
      List {
        Section {
          ForEach(session.screens) { screen in
            row(for: screen)
          }
        } header: {
          Text("Your app")
        } footer: {
          Text(
            "Everything below this line is drawn by the SDK and presented over your app. "
              + "Nothing about how it looks is written here."
          )
        }
      }
      .navigationTitle("Example")
    }
    .sheet(item: showing) { screen in
      presented(screen)
    }
  }

  /// One row: what it is, what it gives you, and the badge where a badge belongs.
  ///
  /// `.plain` so the row reads as a settings row rather than four lines of tinted text — a button's
  /// style tints every label inside it, including the explanation, which is not a link.
  private func row(for screen: ExampleScreen) -> some View {
    Button {
      session.show(screen)
    } label: {
      HStack(alignment: .firstTextBaseline, spacing: 12) {
        Image(systemName: screen.symbol)
          .foregroundStyle(.tint)
          .frame(width: 22)
        VStack(alignment: .leading, spacing: 3) {
          Text(screen.title)
          Text(screen.explanation)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Spacer()
        if screen == .inbox, session.unreadCount > 0 {
          Text("\(session.unreadCount)")
            .font(.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(Capsule().fill(.red))
        }
        Image(systemName: "chevron.right")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.tertiary)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  /// The SDK screen for a row, each one presented exactly as its documentation shows.
  @ViewBuilder
  private func presented(_ screen: ExampleScreen) -> some View {
    switch screen {
    case .requests:
      DifferentRequestsView(hub: session.hub)
    case .inbox:
      NavigationStack { InboxView(hub: session.hub) }
    case .roadmap:
      NavigationStack { RoadmapView(hub: session.hub) }
    case .changelog:
      NavigationStack { ChangelogView(hub: session.hub) }
    case .diagnostics:
      NavigationStack { DiagnosticsView(session: session) }
    }
  }

  /// What the sheet is bound to.
  ///
  /// A binding rather than a flag per screen: what is open is one fact, and two booleans can both
  /// be true.
  ///
  /// Both directions are recorded. A setter that answered only nil would leave SwiftUI holding one
  /// screen and the store holding another, and the sheet would then re-present whichever it
  /// remembered rather than the row that was tapped.
  private var showing: Binding<ExampleScreen?> {
    Binding(
      get: { session.showing },
      set: { screen in
        if let screen {
          session.show(screen)
        } else {
          Task { await session.dismissedWhatWasShowing() }
        }
      }
    )
  }
}
