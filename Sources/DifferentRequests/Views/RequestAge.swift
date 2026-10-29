import SwiftProtobuf
import SwiftUI

/// How long ago a request was filed, in words.
struct RequestAge: View {

  /// When the request was filed.
  let createdAt: Google_Protobuf_Timestamp

  var body: some View {
    Text(createdAt.ago())
      .textRole(.meta)
      .foregroundStyle(ColorRole.secondaryLabel)
  }
}
