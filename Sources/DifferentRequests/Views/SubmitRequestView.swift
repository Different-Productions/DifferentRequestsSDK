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
        Section {
          TextField("Title", text: $store.title)
        } header: {
          Text("What do you want?")
        } footer: {
          Text("One sentence. This is what everyone else votes on.")
        }

        Section {
          TextField("Detail", text: $store.body, axis: .vertical)
            .lineLimit(Self.detailLineLimit)
        } header: {
          Text("Anything else?")
        }

        if store.submitError != nil {
          Section {
            failureNotice
          }
        }
      }
      .navigationTitle("Ask for a feature")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          AsyncButton {
            await send()
          } label: {
            Text("Submit")
          }
          .disabled(store.canSubmit == false)
        }
      }
    }
  }

  /// Files it, then closes only if it was filed. A failed write leaves the sheet up with what was
  /// typed still in it — dismissing on a failure would throw the words away.
  private func send() async {
    await hub.fileRequest()
    if store.submitted == nil { return }
    dismiss()
  }

  /// The server's own message is written for whoever is debugging and may name internals, so it
  /// is not what a reader is told.
  private var failureNotice: some View {
    Label {
      Text("That didn't send. Try again in a moment.")
    } icon: {
      Image(systemName: "exclamationmark.triangle")
    }
    .font(.subheadline)
    .foregroundStyle(.secondary)
  }
}
