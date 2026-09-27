import SwiftUI

/// The field a comment is written in, pinned under a thread.
///
/// The draft it edits belongs to the store, not to this view: a redraw must not be able to lose
/// what someone typed, and whether the draft is worth sending is the store's judgement rather
/// than a second rule written here.
struct CommentComposer: View {

  private static let lineLimit: ClosedRange<Int> = 1...4
  private static let spacing: CGFloat = 8
  private static let verticalPadding: CGFloat = 8

  /// What is being written, held by the store.
  @Binding var draft: String

  /// Whether there is anything worth sending.
  let canSend: Bool

  /// The limit minus what is typed, shown once it is close. Negative once it is over.
  let charactersLeft: Int

  /// `true` while a write on this request is in flight. Only one runs at a time, so the composer
  /// waits out a vote as well as a comment.
  let isWriting: Bool

  /// Posts the draft.
  let send: () async -> Void

  var body: some View {
    HStack(alignment: .bottom, spacing: Self.spacing) {
      TextField(
        text: $draft,
        prompt: Text("Add a comment", bundle: .module, comment: "Placeholder in the comment field under a request"),
        axis: .vertical
      ) {
        Text("Add a comment", bundle: .module, comment: "Placeholder in the comment field under a request")
      }
        .lineLimit(Self.lineLimit)
        .textFieldStyle(.plain)

      CharactersLeft(left: charactersLeft)

      if isWriting {
        ProgressView()
      } else {
        AsyncButton {
          await send()
        } label: {
          Image(systemName: "arrow.up.circle.fill")
            .font(.title2)
        }
        .buttonStyle(.plain)
        .disabled(canSend == false)
        .accessibilityLabel(Text("Send comment", bundle: .module, comment: "VoiceOver label for the button that sends a comment"))
      }
    }
    .padding(.horizontal)
    .padding(.vertical, Self.verticalPadding)
  }
}
