// swift-tools-version: 6.0

import PackageDescription

// The contract is a dependency, not a file in this repository. DifferentRequestsProtos
// carries every type this SDK sends and receives, generated from
// Different-Productions/differentrequests-proto, and this package neither copies those
// types nor wraps them in types of its own.
//
// Pinned `exact:`. A range would let `swift package update` move the wire contract
// underneath a released SDK version, and that is the one dependency which cannot be
// allowed to drift: an installed app speaks whatever it was built against, forever.
let package = Package(
  name: "DifferentRequestsSDK",
  platforms: [
    .iOS(.v18),
    .macOS(.v15),
  ],
  products: [
    .library(
      name: "DifferentRequests",
      targets: ["DifferentRequests"]
    ),
  ],
  dependencies: [
    .package(
      url: "https://github.com/Different-Productions/differentrequests-proto.git",
      exact: "0.18.0"
    ),
    // Declared directly, not leaned on transitively: this target names `Message` and
    // `serializedData()` itself. The range matches the contract package's own, so one
    // runtime resolves for both.
    .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.30.0"),
  ],
  targets: [
    .target(
      name: "DifferentRequests",
      dependencies: [
        .product(name: "DifferentRequestsProtos", package: "differentrequests-proto"),
        .product(name: "SwiftProtobuf", package: "swift-protobuf"),
      ]
    ),
    .testTarget(
      name: "DifferentRequestsTests",
      dependencies: ["DifferentRequests"]
    ),
  ]
)
