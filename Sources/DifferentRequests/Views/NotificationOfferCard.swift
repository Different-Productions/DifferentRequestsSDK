import SwiftUI

/// "Get notified when this request changes?": what would arrive, one button that opens Apple's
/// prompt, and a Dismiss button in the corner. When the prompt could not be asked, a sentence saying
/// so.
///
/// One button, because a second choice beside the one that leads to the system's own question is a
/// question asked twice.
struct NotificationOfferCard: View {

  /// The card's state and its two answers.
  let offer: NotificationOffer

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.small.rawValue) {
      HStack(alignment: .top, spacing: Spacing.xSmall.rawValue) {
        Image(systemName: "bell.fill")
          .foregroundStyle(ColorRole.tint)
          .accessibilityHidden(true)

        Text(
          "Get notified when this request changes?",
          bundle: .module,
          comment: "Heading of the card offering notifications after a first vote or follow"
        )
        .foregroundStyle(ColorRole.label)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)

        DismissButton {
          offer.decline()
        }
        .padding(.top, -Spacing.small.rawValue)
        .padding(.trailing, -Spacing.small.rawValue)
      }
      .textRole(.rowTitle)

      switch offer.state {
      case .hidden, .offered:
        Text(
          "You'll get a notification when this request is planned, shipped or replied to.",
          bundle: .module,
          comment: "Body of the card offering notifications"
        )
        .textRole(.supporting)
        .foregroundStyle(ColorRole.label)

        AsyncButton {
          await offer.accept()
        } label: {
          Text("Turn on notifications", bundle: .module, comment: "Button accepting notifications")
        }
        .buttonStyle(PillButtonStyle(isFilled: true))
      case .failed:
        Text(
          "Notifications couldn't be turned on. You can turn them on in Settings.",
          bundle: .module,
          comment: "Shown when the system prompt could not be asked"
        )
        .textRole(.supporting)
        .foregroundStyle(ColorRole.label)

        Button {
          offer.decline()
        } label: {
          Text("OK", bundle: .module, comment: "Button that closes the notification card")
        }
        .buttonStyle(PillButtonStyle(isFilled: false))
      }
    }
    .padding(.vertical, Spacing.xxSmall.rawValue)
  }
}
