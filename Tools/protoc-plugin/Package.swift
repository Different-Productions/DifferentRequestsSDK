// swift-tools-version:6.0
import PackageDescription

// Host build tooling, kept in its own manifest so it can pin swift-protobuf exactly without
// imposing that version on the SDK, which resolves its own runtime.
//
// `swift build --product protoc-gen-swift` here resolves the plugin from this pinned dependency
// rather than from PATH. An ambient plugin at a different version reformats every generated file,
// so the committed output would depend on whatever a given machine happened to install.
//
// Pinned to the version differentrequests-proto and the server pin, so every generated file in
// this org is formatted by one generator.
let package = Package(
  name: "protoc-plugin",
  platforms: [.macOS("15.0")],
  dependencies: [
    .package(url: "https://github.com/apple/swift-protobuf.git", exact: "1.33.3")
  ],
  targets: []
)
