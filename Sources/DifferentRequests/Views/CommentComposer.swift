import SwiftUI

/// The field a comment is written in and its Send circle, 12 pt apart, with the character count on
/// its own line over them once it is worth showing. On macOS the field is the system's rounded text
/// field and Send is a push button.
///
/// The draft belongs to the store, so a redraw cannot lose what someone typed.
struct CommentComposer: View {

  /// The request's own store, which holds the draft and posts it.
  @Bindable var store: RequestDetailStore

  /// The field holding the keyboard, or none. Given up once a comment lands.
  @FocusState private var focused: ComposerField?

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.xxSmall.points()) {
      CharactersLeft(content: store.commentCharactersLeft())
        .padding(.horizontal, Spacing.medium.points())

      #if os(macOS)
      HStack(alignment: .top, spacing: Spacing.small.points()) {
        TextField(
          text: $store.detail.draft,
          prompt: Text("Add a comment", bundle: .module, comment: "Placeholder in the comment field under a request"),
          axis: .vertical
        ) {
          Text("Add a comment", bundle: .module, comment: "Placeholder in the comment field under a request")
        }
        .lineLimit(1...4)
        .textFieldStyle(.plain)
        .textRole(.reading)
        .focused($focused, equals: .draft)
        // The system's rounded field draws at 24 pt even at the large size; a Mac control is 28.
        .padding(.horizontal, Spacing.xSmall.points())
        .padding(.vertical, Spacing.xxSmall.points())
        .frame(minHeight: ControlHeight.macPush.points())
        .background(.background, in: RoundedRectangle(cornerRadius: Radius.macControl.points()))
        .overlay {
          RoundedRectangle(cornerRadius: Radius.macControl.points())
            .strokeBorder(.separator)
        }

        if store.write.isWriting() {
          ProgressView()
            .controlSize(.small)
            .frame(minHeight: ControlHeight.macPush.points())
        } else {
          AsyncButton {
            await store.postComment()
          } label: {
            Text("Send", bundle: .module, comment: "Button that sends a new request or a comment")
          }
          .buttonStyle(PillButtonStyle(fill: .gray))
          .disabled(store.canPostComment() == false)
          .accessibilityLabel(Text("Send comment", bundle: .module, comment: "VoiceOver label for the button that sends a comment"))
        }
      }
      #else
      HStack(alignment: .bottom, spacing: Spacing.small.points()) {
        TextField(
          text: $store.detail.draft,
          prompt: Text("Add a comment", bundle: .module, comment: "Placeholder in the comment field under a request"),
          axis: .vertical
        ) {
          Text("Add a comment", bundle: .module, comment: "Placeholder in the comment field under a request")
        }
        .lineLimit(1...4)
        .textFieldStyle(.plain)
        .textRole(.reading)
        .focused($focused, equals: .draft)
        .padding(.horizontal, Spacing.medium.points())
        .padding(.vertical, Spacing.xSmall.points())
        .frame(minHeight: TargetSize.minimum.points())
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: TargetSize.minimum.points() / 2))

        if store.write.isWriting() {
          ProgressView()
            .frame(width: TargetSize.minimum.points(), height: TargetSize.minimum.points())
        } else {
          AsyncButton {
            await store.postComment()
          } label: {
            Image(systemName: "arrow.up")
              .fontWeight(.semibold)
          }
          .buttonStyle(SendButtonStyle())
          .disabled(store.canPostComment() == false)
          .accessibilityLabel(Text("Send comment", bundle: .module, comment: "VoiceOver label for the button that sends a comment"))
        }
      }
      #endif
    }
    .onChange(of: store.write.isWriting()) {
      // A refused post leaves the draft as typed, so an empty one after a write means it landed.
      if store.write.isWriting() == false, store.detail.draft.isEmpty {
        focused = nil
      }
    }
  }
}
