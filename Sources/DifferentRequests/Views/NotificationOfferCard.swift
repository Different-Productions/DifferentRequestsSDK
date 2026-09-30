import SwiftUI

/// "Get told when this changes?" with Not now and Turn on, or, when Apple's prompt could not be
/// asked, a sentence saying so.
struct NotificationOfferCard: View {

  private static let spacing: CGFloat = 12
  private static let headingSpacing: CGFloat = 10

  /// The card's state and the two answers.
  let offer: NotificationOffer

  var body: some View {
    VStack(alignment: .leading, spacing: Self.spacing) {
      HStack(spacing: Self.headingSpacing) {
        Image(systemName: "bell")
          .foregroundStyle(.tint)
        Text(
          "Get told when this changes?",
          bundle: .module,
          comment: "Heading of the card offering notifications after a first vote or follow"
        )
        .font(.headline)
      }

      switch offer.state {
      case .hidden, .offered:
        Text(
          "We'll send a notification when it's planned, shipped or someone replies.",
          bundle: .module,
          comment: "Body of the card offering notifications"
        )
        .font(.subheadline)
        .foregroundStyle(.secondary)

        HStack(spacing: Self.headingSpacing) {
          Button {
            offer.decline()
          } label: {
            Text("Not now", bundle: .module, comment: "Button declining notifications")
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.bordered)

          AsyncButton {
            await offer.accept()
          } label: {
            Text("Turn on", bundle: .module, comment: "Button accepting notifications")
              .fontWeight(.semibold)
              .foregroundStyle(.background)
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.borderedProminent)
        }
        .controlSize(.large)
      case .failed:
        Text(
          "Notifications couldn't be turned on. You can turn them on in Settings.",
          bundle: .module,
          comment: "Shown when the system prompt could not be asked"
        )
        .font(.subheadline)
        .foregroundStyle(.secondary)

        Button {
          offer.decline()
        } label: {
          Text("OK", bundle: .module, comment: "Button that closes the notification card")
        }
        .buttonStyle(.bordered)
      }
    }
    .padding(.vertical, Self.headingSpacing)
  }
}
