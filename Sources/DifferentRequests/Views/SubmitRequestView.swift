import SwiftUI

/// The sheet that files a request.
///
/// Presented, not pushed, so it carries its own `NavigationStack` for the two toolbar actions a
/// sheet needs. The board's own way in seeds the title with whatever was searched for: reaching
/// here from a search means the search did not answer, and retyping the words would be the price
/// of having looked first.
///
/// A host app offering its own way in opens the composer first, then presents this:
///
/// ```swift
/// Button("Request a feature") {
///   requests.beginSubmission()
///   isComposing = true
/// }
/// .sheet(isPresented: $isComposing) {
///   SubmitRequestView(hub: requests)
/// }
/// ```
///
/// What is typed here belongs to the hub, so a redraw behind the sheet cannot take it, and the
/// board is re-read for whoever presented it — the sheet does not know who that was.
public struct SubmitRequestView: View {

  private static let detailLineLimit: ClosedRange<Int> = 3...8
  private static let footerSpacing: CGFloat = 8

  /// What the write goes through, and what re-reads the board once it lands.
  private let hub: DifferentRequestsHub

  /// Bindable for the two fields, which edit the draft the hub holds.
  @Bindable private var store: SubmitStore

  @Environment(\.dismiss) private var dismiss

  /// - Parameter hub: What the host app built once and holds. Call
  ///   ``DifferentRequestsHub/beginSubmission()`` before presenting this.
  public init(hub: DifferentRequestsHub) {
    self.hub = hub
    self._store = Bindable(hub.submission)
  }

  public var body: some View {
    NavigationStack {
      Form {
        if let warning = hub.board.narrowing.composerWarning {
          Section {
            Label(warning, systemImage: "line.3.horizontal.decrease.circle")
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
        }

        Section {
          TextField(
            text: $store.title,
            prompt: Text("In a few words", bundle: .module, comment: "Placeholder in a new request's title field")
          ) {
            Text("Title", bundle: .module, comment: "VoiceOver name of a new request's title field")
          }
        } header: {
          Text("What do you want?", bundle: .module, comment: "Header over a new request's title field")
        } footer: {
          HStack {
            Text("One sentence. This is what everyone else votes on.", bundle: .module, comment: "Note under a new request's title field")
            Spacer()
            CharactersLeft(left: store.titleCharactersLeft)
          }
        }

        Section {
          TextField(
            text: $store.body,
            prompt: Text("Why you'd use it (optional)", bundle: .module, comment: "Placeholder in a new request's detail field"),
            axis: .vertical
          ) {
            Text("Detail", bundle: .module, comment: "VoiceOver name of a new request's detail field")
          }
          .lineLimit(Self.detailLineLimit)
        } header: {
          Text("Anything else?", bundle: .module, comment: "Header over a new request's detail field")
        } footer: {
          // Right under the fields it is about, where the eye goes after tapping Send.
          VStack(alignment: .leading, spacing: Self.footerSpacing) {
            HStack {
              Spacer()
              CharactersLeft(left: store.bodyCharactersLeft)
            }
            if let failure = store.write.failure {
              WriteFailureNotice(failure: failure) {
                store.acknowledgeWriteFailure()
              }
              .foregroundStyle(.primary)
            }
          }
        }
      }
      .navigationTitle(Text("New request", bundle: .module, comment: "Title of the form for a new feature request"))
      .worn(by: hub.appearanceDrawn)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button {
            dismiss()
          } label: {
            Text("Cancel", bundle: .module, comment: "Button that closes the new request form without sending")
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          AsyncButton {
            await send()
          } label: {
            Text("Send", bundle: .module, comment: "Button that sends a new request or a comment")
          }
          .disabled(store.canSubmit == false)
        }
      }
    }
  }

  /// Files it, then closes only if it was filed. A failed write leaves the sheet up with what was
  /// typed still in it; the board's "posted" notice clears `submitted` on a timer, so the write's
  /// own state is what says whether it landed.
  private func send() async {
    await hub.fileRequest()
    if store.write.failure == nil {
      dismiss()
    }
  }
}
