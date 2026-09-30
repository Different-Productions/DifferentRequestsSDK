# Declaring what this SDK collects

## What it is

`PrivacyInfo.xcprivacy`, shipped inside the package, saying exactly what this SDK sends and why.

**Nothing was rejected for its absence, and nothing would have been.** This SDK calls one
required-reason API — `UserDefaults`, declared below — and no file timestamps, disk space or boot
time. It is not on Apple's list of SDKs that must ship a manifest.

**What its absence cost was adoption.** Xcode builds a customer's App Store privacy report by adding
up the manifests of their app and every SDK inside it. With none from us, that customer had to read
our source, work out what we send, and declare it themselves — at the exact moment they were deciding
whether to trust an unknown vendor with code inside their shipped app.

## Surfaces

| Surface | Ships this? |
|---|---|
| The Swift package | **Yes** — `Sources/DifferentRequests/PrivacyInfo.xcprivacy`, declared as `.copy` |
| A customer's privacy report | **Yes, automatically.** Xcode picks it up; they read nothing of ours |
| The server | **None.** A manifest describes a client |
| The console | **None** |

Declared `.copy` rather than `.process` because Xcode reads it verbatim when it adds a report up.

## What it declares

| Data | Sent when | Linked | Tracking | Purpose |
|---|---|---|---|---|
| **User ID** — `external_id` | Every `createSession` | Yes | No | App functionality |
| **Email address** | `createSession`, only if the host app passes one | Yes | No | App functionality |
| **Name** — `display_name` | `createSession`, only if the host app passes one | Yes | No | App functionality |
| **Other user content** — request titles and bodies, comments | `submit`, `comment` | Yes | No | App functionality |
| **Device ID** — the APNs token | `registerDevice`, only if the host app calls it | Yes | No | App functionality |

**Linked is honest, not conservative.** `external_id` is deliberately stable across reinstalls — that
is what lets somebody keep their votes — so everything sent with it is linked to a person by design.
Declaring otherwise would be false.

**Tracking is `false`, and that is a claim.** Nothing sent here is joined with data from another
company's apps, and nothing goes to a data broker. `NSPrivacyTrackingDomains` is empty.

**`NSPrivacyAccessedAPITypes` names `UserDefaults`, reason `CA92.1`** — read and written by this
app alone. Two keys, both remembered on this phone and never sent: that the "Get told when this
changes?" card was answered (`DifferentRequests.notificationOfferAnswered`, in
`NotificationOffer.swift`) and that a first vote was made (`DifferentRequests.firstVoteNoted`, in
`FirstVoteNote.swift`). Added 2026-09-26 with the owner's rulings for those two pieces.

**A proof declares nothing new.** `createSession` takes an optional `DRIdentityProof`, which is a
signature over the `external_id` already declared above and the instant it stops being accepted. It
carries no attribute of the person, and it is made on the host developer's own backend rather than
read off the device. So the manifest is the same with a proof as without one.

## Expectations

### It works

| Given | When | Then |
|---|---|---|
| A customer adds this package | They build | The manifest is copied into the bundle |
| A customer generates their privacy report | Xcode adds it up | Our five data types appear, attributed to this SDK |
| A reviewer asks what this SDK sends | They read the manifest | Five types, all App Functionality, all not-tracking |

### It refuses

Nothing. A manifest is a declaration, not a check. **It has no behavior**, and the one way it can be
wrong is by disagreeing with what the code sends — which is why the table above is written from the
rpcs rather than from intent.

## The path

```
  the package
    │
    ├─ Package.swift  resources: [.copy("PrivacyInfo.xcprivacy")]
    │     .copy, not .process — Xcode reads it verbatim
    ▼
  Sources/DifferentRequests/PrivacyInfo.xcprivacy
    │
    ▼
  a customer's app bundle
    │
    ▼
  Xcode's privacy report = their manifest + every SDK's, added up
```

What the manifest must agree with, and where each line comes from:

```
  createSession(externalID:email:displayName:proof:) ...... UserID, EmailAddress, Name
                                                            proof declares nothing: see above
  submit(title:body:) / comment(requestID:body:) .......... OtherUserContent
  registerDevice(token:) .................................. DeviceID
  everything else ......................................... reads only
```

## The screen

```
None. A manifest draws nothing.

Where a customer sees it is their own App Store Connect privacy report, with
our rows attributed to this SDK rather than left for them to work out:

  Data used to provide app functionality
    User ID .............. DifferentRequests
    Email address ........ DifferentRequests
    Name ................. DifferentRequests
    Other user content ... DifferentRequests
    Device ID ............ DifferentRequests
```

## Platform differences

The manifest is read by Xcode for every Apple platform this package supports. It says nothing
platform-specific, because what the SDK sends does not vary by platform.

## Which tests walk the chart

There is no test target in this package. Walked by parsing the manifest with `plistlib` and checking
it against the rpcs above — five declared types, `NSPrivacyTracking` false, both API-type and
tracking-domain arrays empty — and by building the package with the resource declared.

The check that matters over time is not a test but a rule: **a new rpc that sends something new is a
manifest change in the same PR.**

Closes #121.
