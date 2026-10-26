import SwiftUI

/// The field a comment is written in and its Send circle, 12 pt apart, with the character count on
/// its own line over them once it is worth showing.
///
/// The draft belongs to the store, so a redraw cannot lose what someone typed.
struct CommentComposer: View {

  /// What is being written, held by the store.
  @Binding var draft: String

  /// Whether there is anything worth sending.
  let canSend: Bool

  /// The limit minus what is typed. Negative once it is over.
  let charactersLeft: Int

  /// Whether a write on this request is in flight. Only one runs at a time.
  let isWriting: Bool

  /// Posts the draft.
  let send: () async -> Void

  /// Whether the field holds the keyboard. Given up once a comment lands.
  @FocusState private var isFocused: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.xxSmall.rawValue) {
      CharactersLeft(left: charactersLeft)
        .padding(.horizontal, Spacing.medium.rawValue)

      HStack(alignment: .bottom, spacing: Spacing.small.rawValue) {
        TextField(
          text: $draft,
          prompt: Text("Add a comment", bundle: .module, comment: "Placeholder in the comment field under a request"),
          axis: .vertical
        ) {
          Text("Add a comment", bundle: .module, comment: "Placeholder in the comment field under a request")
        }
        .lineLimit(1...4)
        .textFieldStyle(.plain)
        .textRole(.reading)
        .focused($isFocused)
        .padding(.horizontal, Spacing.medium.rawValue)
        .padding(.vertical, Spacing.xSmall.rawValue)
        .frame(minHeight: TargetSize.minimum.rawValue)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: TargetSize.minimum.rawValue / 2))

        if isWriting {
          ProgressView()
            .frame(width: TargetSize.minimum.rawValue, height: TargetSize.minimum.rawValue)
        } else {
          AsyncButton {
            await send()
          } label: {
            Image(systemName: "arrow.up")
              .fontWeight(.semibold)
          }
          .buttonStyle(SendButtonStyle())
          .disabled(canSend == false)
          .accessibilityLabel(Text("Send comment", bundle: .module, comment: "VoiceOver label for the button that sends a comment"))
        }
      }
    }
    .onChange(of: isWriting) {
      // A refused post leaves the draft as typed, so an empty one after a write means it landed.
      if isWriting == false, draft.isEmpty {
        isFocused = false
      }
    }
  }
}
