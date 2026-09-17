import SwiftUI

/// What the board is drawn in, so it looks like the app it is inside rather than a widget bolted
/// onto it.
///
/// Two things and no more: the color a control is tinted with, and the font everything is set in.
/// They carry most of what makes a screen feel like somebody's app, and neither can make text
/// unreadable — which a full theme can, in a hundred ways nobody would find before shipping.
///
/// Held by the host app and handed over when the hub is built, because it is the host app's own
/// look. Reading it from the console would mean a color change is a deploy of ours and a round trip
/// on every launch, to answer a question the app already knows.
public struct Appearance: Sendable, Equatable {
  /// What a vote, a follow and every prominent button are tinted with.
  public let accent: Color

  /// The family everything is set in, from the system's own: the default, rounded, serif or
  /// monospaced.
  ///
  /// **Not a typeface the host app ships.** SwiftUI applies a named font by replacing the whole
  /// font, which takes every label's size and weight with it — a board where a title, a vote count
  /// and a caption are all one size. A family that keeps text styles intact is what `fontDesign`
  /// is, and it is the honest half of this to offer.
  public let font: Font.Design

  /// The SDK's own look: the system tint and the system font.
  ///
  /// Named rather than implied by a default parameter, so a host app that has not thought about it
  /// says so at the call site instead of getting one silently.
  public static let standard = Appearance(accent: Color.accentColor, font: Font.Design.default)

  /// An accent of your own, with the system's default family.
  public init(accent: Color) {
    self.accent = accent
    self.font = .default
  }

  /// An accent and one of the system's own families.
  public init(accent: Color, font: Font.Design) {
    self.accent = accent
    self.font = font
  }
}
