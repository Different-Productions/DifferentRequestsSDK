import DifferentRequestsProtos
import Foundation

extension DifferentRequestsError {
  /// The failure a response body describes.
  ///
  /// A refusal the server wrote arrives as an encoded `DRApiError` and is carried through
  /// unflattened. Anything else — an infrastructure page, a truncated body — holds nothing a
  /// caller can branch on, so it becomes ``unreadableError(byteCount:)`` with its length and
  /// none of its content.
  init(failureBody: Data) {
    do {
      self = .api(try DRApiError(serializedBytes: [UInt8](failureBody)))
    } catch {
      self = .unreadableError(byteCount: failureBody.count)
    }
  }
}
