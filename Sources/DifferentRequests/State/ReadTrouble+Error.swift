import Foundation

extension ReadTrouble {

  /// Why a read that threw `error` did not answer. Anything the SDK did not throw is left unset.
  init(error: any Error) {
    if let known = error as? DifferentRequestsError {
      self = known.readTrouble()
    } else {
      self.init()
    }
  }
}
