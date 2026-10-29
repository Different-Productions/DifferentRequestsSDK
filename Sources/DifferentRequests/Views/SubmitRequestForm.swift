import SwiftUI

/// The two fields of a new request: each with a heading above it and its help, its character count
/// and anything that went wrong on their own lines under it.
struct SubmitRequestForm: View {

  /// What holds the draft, and the board whose narrowing may be hiding a duplicate.
  let hub: DifferentRequestsHub

  var body: some View {
    @Bindable var submission = hub.submission

    List {
      if let warning = hub.board.narrowing().composerWarning() {
        Section {
          Label(warning, systemImage: "line.3.horizontal.decrease.circle")
            .textRole(.meta)
            .foregroundStyle(ColorRole.secondaryLabel)
        }
      }

      Section {
        HStack(spacing: Spacing.xSmall.points()) {
          TextField(
            text: $submission.draft.title,
            prompt: Text("What you want, in a few words", bundle: .module, comment: "Placeholder in a new request's title field")
          ) {
            Text("Title", bundle: .module, comment: "VoiceOver name of a new request's title field")
          }
          .textRole(.reading)

          if submission.draft.title.isEmpty == false {
            Button {
              submission.draft.title = ""
            } label: {
              Image(systemName: "xmark.circle.fill")
                .foregroundStyle(ColorRole.secondaryLabel)
                .frame(width: TargetSize.minimum.points(), height: TargetSize.minimum.points())
                .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .tint(Color.secondary)
            .accessibilityLabel(Text("Clear", bundle: .module, comment: "VoiceOver label for the button that empties the title field"))
          }
        }
        .listRowInsets(
          EdgeInsets(top: 0, leading: Spacing.medium.points(), bottom: 0, trailing: Spacing.xxSmall.points())
        )
      } header: {
        Text("Title", bundle: .module, comment: "Header over a new request's title field")
          .textRole(.rowTitle)
          .foregroundStyle(ColorRole.label)
          .textCase(nil)
      } footer: {
        VStack(alignment: .leading, spacing: Spacing.xxSmall.points()) {
          Text("One sentence. This is what everyone else votes on.", bundle: .module, comment: "Note under a new request's title field")
            .textRole(.meta)
            .foregroundStyle(ColorRole.secondaryLabel)
          CharactersLeft(content: submission.titleCharactersLeft())
        }
      }

      Section {
        TextField(
          text: $submission.draft.body,
          prompt: Text("Why you'd use it (optional)", bundle: .module, comment: "Placeholder in a new request's detail field"),
          axis: .vertical
        ) {
          Text("Details", bundle: .module, comment: "VoiceOver name of a new request's detail field")
        }
        .textRole(.reading)
        .lineLimit(3...8)
      } header: {
        Text("Details", bundle: .module, comment: "Header over a new request's detail field")
          .textRole(.rowTitle)
          .foregroundStyle(ColorRole.label)
          .textCase(nil)
      } footer: {
        VStack(alignment: .leading, spacing: Spacing.xxSmall.points()) {
          CharactersLeft(content: submission.bodyCharactersLeft())
          if let failure = submission.write.failure() {
            WriteFailureNotice(failure: failure) {
              submission.acknowledgeWriteFailure()
            }
          }
        }
      }
    }
    .groupedList()
    .scrollDismissesKeyboard(.interactively)
  }
}
