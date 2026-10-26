import DifferentRequestsProtos
import SwiftUI

/// The top of one update: its title, its version and age on one line in one style, then its notes
/// at the reading size. An update with no title is headed by its version.
struct ChangelogEntryHeader: View {

  let entry: DRChangelogEntry

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.xSmall.rawValue) {
      if entry.title.isEmpty {
        Text("Version \(entry.version)", bundle: .module, comment: "An update's version; the argument is the version number")
          .textRole(.rowTitle)
          .foregroundStyle(ColorRole.label)
      } else {
        Text(entry.title)
          .textRole(.rowTitle)
          .foregroundStyle(ColorRole.label)
      }

      HStack(alignment: .firstTextBaseline, spacing: Spacing.xSmall.rawValue) {
        if entry.title.isEmpty == false, entry.version.isEmpty == false {
          Text("Version \(entry.version)", bundle: .module, comment: "An update's version; the argument is the version number")
        }
        Spacer(minLength: Spacing.xSmall.rawValue)
        if entry.hasPublishedAt {
          Text(entry.publishedAt.date.ago)
        }
      }
      .textRole(.meta)
      .foregroundStyle(ColorRole.secondaryLabel)

      if entry.body.isEmpty == false {
        Text(entry.body)
          .textRole(.reading)
          .foregroundStyle(ColorRole.label)
          .textSelection(.enabled)
      }
    }
  }
}
