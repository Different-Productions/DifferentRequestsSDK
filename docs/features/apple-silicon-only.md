# Apple silicon only

## What it is

The example app builds for Apple silicon and nothing else. Its project sets `ARCHS = arm64` at the
project level, for Debug and Release, so no build of it compiles an `x86_64` slice. Intel Macs are
not supported.

Without the setting, Xcode builds a generic destination for every architecture it knows:
`arm64 x86_64` for macOS and for the iOS Simulator. The iOS device build was already `arm64`.

The SDK package itself names no architecture. A developer's app decides which architectures it
compiles the package for.

## Surfaces

| Surface | Ships this? |
|---|---|
| `Example/DifferentRequestsExample/DifferentRequestsExample.xcodeproj/project.pbxproj` | **Yes** — `ARCHS = arm64;` in the project's Debug and Release configurations |
| CI (`.github/workflows/swift.yml`) | **Yes** — the example build inherits the setting from the project; the command line no longer passes `ARCHS` |
| The public copy `DifferentRequestsSDK` | **Yes**, on the next release, which copies the example project |
| The SDK library (`Package.swift`) | **None** — a package does not choose an architecture |
| The server and the console | **None** |

## How to find it, trigger it, and what happens

**Find it.** `project.pbxproj`, in the two configurations of the configuration list for
`PBXProject "DifferentRequestsExample"`.

**Trigger it.** Any build of the `DifferentRequestsExample` scheme. To read the value:

```sh
xcodebuild -project Example/DifferentRequestsExample/DifferentRequestsExample.xcodeproj \
  -scheme DifferentRequestsExample -destination 'generic/platform=macOS' \
  -showBuildSettings | grep '^ *ARCHS ='
```

**What happens.** `ARCHS = arm64`, for Debug and Release, on each of these destinations:

| Destination | Before | After |
|---|---|---|
| `generic/platform=iOS` | `arm64` | `arm64` |
| `generic/platform=iOS Simulator` | `arm64 x86_64` | `arm64` |
| `generic/platform=macOS` | `arm64 x86_64` | `arm64` |

## Expectations

| Given | When | Then |
|---|---|---|
| A clean checkout | `-showBuildSettings` on any destination above | `ARCHS = arm64` |
| An Apple silicon Mac | running the example on macOS or in the simulator | it runs natively |
| An Intel Mac | opening a macOS build of the example | macOS refuses to open it; there is no Intel slice |
| A target that sets its own `ARCHS` | a build of that target | the target's value wins over the project's; search `project.pbxproj` for a second `ARCHS` |

## Platform differences

- **iOS device** — no change; it was already `arm64`.
- **iOS Simulator** — `x86_64` is gone; the simulator on Apple silicon runs `arm64`.
- **macOS** — the example is Apple silicon only.
