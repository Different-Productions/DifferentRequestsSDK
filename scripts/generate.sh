#!/bin/sh
#
# Regenerates Sources/DifferentRequests/Generated/*.pb.swift from proto/*.proto.
#
# These are the SDK's own messages: the state its screens hold, which no other process reads. The
# contract is a dependency and is never generated here.
#
# protoc-gen-swift is built from the swift-protobuf version pinned in
# Tools/protoc-plugin/Package.swift, never taken from PATH. An ambient plugin at a different version
# reformats every file, so the committed output would depend on whatever the developer happened to
# `brew install`.

set -e

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

if ! command -v protoc >/dev/null 2>&1; then
  echo "error: protoc not found on PATH. Install it with 'brew install protobuf'." >&2
  exit 1
fi

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PACKAGE_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
PLUGIN_PKG="$PACKAGE_ROOT/Tools/protoc-plugin"
OUTPUT_PATH="$PACKAGE_ROOT/Sources/DifferentRequests/Generated"

swift build --package-path "$PLUGIN_PKG" --product protoc-gen-swift -c release
PLUGIN_BIN="$(swift build --package-path "$PLUGIN_PKG" --product protoc-gen-swift -c release --show-bin-path)/protoc-gen-swift"

# The contract package, at the exact version Package.swift pins, taken from its own checkout, so an
# SDK message that holds a contract message is compiled against the schema that declares it.
#
# CONTRACT_PKG names another checkout for the one case that pin cannot serve: a contract change
# that is not tagged yet, held in `swift package edit`, which moves the package out of .build.
CONTRACT_PKG="${CONTRACT_PKG:-$PACKAGE_ROOT/.build/checkouts/differentrequests-proto}"
if [ ! -d "$CONTRACT_PKG/proto" ]; then
  echo "error: the contract package is not checked out at $CONTRACT_PKG. Run 'swift package resolve' first." >&2
  exit 1
fi

# Which Swift module each contract file's messages live in, so an SDK message that holds one
# imports it instead of expecting it in this target.
MODULE_MAPPINGS="$PACKAGE_ROOT/proto/module-mappings.asciipb"

mkdir -p "$OUTPUT_PATH"

# Internal visibility, unlike the contract package's public output: a host app never names the
# state an SDK screen holds.
protoc --proto_path="$PACKAGE_ROOT/proto" \
    --proto_path="$CONTRACT_PKG/proto" \
    --plugin=protoc-gen-swift="$PLUGIN_BIN" \
    --swift_opt=Visibility=Internal \
    --swift_opt=ProtoPathModuleMappings="$MODULE_MAPPINGS" \
    --swift_out="$OUTPUT_PATH" \
    "$PACKAGE_ROOT/proto/differentrequests_sdk_state.proto" \
    "$PACKAGE_ROOT/proto/differentrequests_sdk_screens.proto"

# Public visibility: a host app names every type in this file.
protoc --proto_path="$PACKAGE_ROOT/proto" \
    --proto_path="$CONTRACT_PKG/proto" \
    --plugin=protoc-gen-swift="$PLUGIN_BIN" \
    --swift_opt=Visibility=Public \
    --swift_opt=ProtoPathModuleMappings="$MODULE_MAPPINGS" \
    --swift_out="$OUTPUT_PATH" \
    "$PACKAGE_ROOT/proto/differentrequests_sdk_public.proto"

echo "Generated SDK state and public types to $OUTPUT_PATH"

# The example app's own messages, generated into its own target. They hold SDK public types, so
# the SDK's public file maps to the DifferentRequests module beside the contract's.
EXAMPLE_OUTPUT_PATH="$PACKAGE_ROOT/Example/DifferentRequestsExample/DifferentRequestsExample/Generated"
EXAMPLE_MODULE_MAPPINGS="$PACKAGE_ROOT/proto/example-module-mappings.asciipb"

# The words, symbols and environment names on the example's enums are `(label)`, `(pitch)` and
# `(token)` values, emitted by the contract's own generator at the pinned contract version.
TOKENS_SCRATCH="$PACKAGE_ROOT/.build/drtokens"
swift build --package-path "$CONTRACT_PKG/Tools/protoc-plugin" --product protoc-gen-drtokens \
    -c release --scratch-path "$TOKENS_SCRATCH"
TOKENS_BIN="$(swift build --package-path "$CONTRACT_PKG/Tools/protoc-plugin" \
    --product protoc-gen-drtokens -c release --scratch-path "$TOKENS_SCRATCH" \
    --show-bin-path)/protoc-gen-drtokens"

mkdir -p "$EXAMPLE_OUTPUT_PATH"

protoc --proto_path="$PACKAGE_ROOT/proto" \
    --proto_path="$CONTRACT_PKG/proto" \
    --plugin=protoc-gen-swift="$PLUGIN_BIN" \
    --swift_opt=Visibility=Internal \
    --swift_opt=ProtoPathModuleMappings="$EXAMPLE_MODULE_MAPPINGS" \
    --swift_out="$EXAMPLE_OUTPUT_PATH" \
    "$PACKAGE_ROOT/proto/differentrequests_example.proto"

protoc --proto_path="$PACKAGE_ROOT/proto" \
    --proto_path="$CONTRACT_PKG/proto" \
    --plugin=protoc-gen-drtokens="$TOKENS_BIN" \
    --drtokens_out="$EXAMPLE_OUTPUT_PATH" \
    "$PACKAGE_ROOT/proto/differentrequests_example.proto"

echo "Generated the example app's types to $EXAMPLE_OUTPUT_PATH"
