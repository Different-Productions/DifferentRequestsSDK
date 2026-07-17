// swift-tools-version: 6.0

import PackageDescription

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
    // Pinned below 1.13.0: from that release the generator emits access-level
    // qualified imports (`package import`) in the generated sources, which
    // clash with the hand-written targets' unqualified imports and fail to
    // compile ("ambiguous implicit access level for import"). 1.13.0 also
    // trips an OpenAPIKit trait-resolution error. `swift build` masked both
    // because Package.resolved is not committed and stale resolutions stayed
    // on a compatible version.
    .package(url: "https://github.com/apple/swift-openapi-generator", "1.7.0" ..< "1.13.0"),
    .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.7.0"),
    .package(url: "https://github.com/apple/swift-openapi-urlsession", from: "1.1.0"),
  ],
  targets: [
    .target(
      name: "DifferentRequests",
      dependencies: [
        .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
        .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
      ],
      plugins: [
        .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator"),
      ]
    ),
    .testTarget(
      name: "DifferentRequestsTests",
      dependencies: ["DifferentRequests"]
    ),
  ]
)
