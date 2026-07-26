import SwiftUI

/// The sheet that files a request.
///
/// Presented, not pushed, so it carries its own `NavigationStack` for the two toolbar actions a
/// sheet needs. The board opens it with whatever was searched for, already in the title: reaching
/// here means the search did not answer, and retyping the words would be the price of having
/// looked first.
///
/// ```swift
/// SubmitRequestView(client: client, title: searchText) {
///   await store.load()
/// }
/// ```
public struct SubmitRequestView: View {

  private static let detailLineLimit: ClosedRange<Int> = 3...8

  @Bindable private var store: SubmitStore

  /// Called once the request is filed, before the sheet closes, so whatever presented it can
  /// re-read the board the new request is now on.
  private let onSubmitted: () async -> Void

  @Environment(\.dismiss) private var dismiss

  /// - Parameters:
  ///   - client: The client the write goes through.
  ///   - title: What the reader searched for, as the opening title.
  ///   - onSubmitted: Called after a successful write, before the sheet closes.
  public init(
    client: DifferentRequestsClient,
    title: String,
    onSubmitted: @escaping () async -> Void
  ) {
    self._store = Bindable(wrappedValue: SubmitStore(client: client, title: title))
    self.onSubmitted = onSubmitted
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
    await store.submit()
    if store.submitted == nil { return }
    await onSubmitted()
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
