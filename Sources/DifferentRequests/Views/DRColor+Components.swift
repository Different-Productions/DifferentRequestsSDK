import DifferentRequestsProtos

extension DRColor {

  /// Whether every component is one a component holds, which is every color the dashboard writes.
  func isDashboardColor() -> Bool {
    let largest = ColorComponent.largest.level()
    return red <= largest && green <= largest && blue <= largest
  }
}
