# Declaring what this SDK collects

## What it is

`PrivacyInfo.xcprivacy`, shipped inside the package, saying exactly what this SDK sends and why.

**Nothing was rejected for its absence, and nothing would have been.** This SDK calls no
required-reason API — no `UserDefaults`, no file timestamps, no disk space, no boot time — and is not
on Apple's list of SDKs that must ship a manifest.

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
| **Other data** — `traits` | `createSession`, whatever the host app puts there | Yes | No | App functionality |

**Linked is honest, not conservative.** `external_id` is deliberately stable across reinstalls — that
is what lets somebody keep their votes — so everything sent with it is linked to a person by design.
Declaring otherwise would be false.

**Tracking is `false`, and that is a claim.** Nothing sent here is joined with data from another
company's apps, and nothing goes to a data broker. `NSPrivacyTrackingDomains` is empty.

**`NSPrivacyAccessedAPITypes` is empty**, and that is checkable: this package reads no
required-reason API.

## `traits`, declared generically

**`traits` is an open `[String: String]`**, and a manifest can only name what we can name.

It is declared as `NSPrivacyCollectedDataTypeOtherDataTypes` — Apple's own category for data that
does not fit the named ones. That keeps three things true at once:

- the dictionary is **declared rather than invisible** in a customer's report
- the released API does not change
- a customer who puts a category Apple lists separately — health, location, financial — declares
  that category in their own manifest, which is the only place it can be declared, because they are
  the only party who knows what they put there

The alternatives were closing it to a named set (plan, cohort, install date) or dropping it. Both
change a released API, and neither is needed once the open case is declarable.

Bounded on the server side as of server #166: fifty traits, a hundred characters of key, a thousand
of value.

## Expectations

### It works

| Given | When | Then |
|---|---|---|
| A customer adds this package | They build | The manifest is copied into the bundle |
| A customer generates their privacy report | Xcode adds it up | Our six data types appear, attributed to this SDK |
| A reviewer asks what this SDK sends | They read the manifest | Six types, all App Functionality, all not-tracking |
| A customer fills `traits` | They generate a report | Covered generically as other data. A category Apple names separately is still **theirs to declare** |

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
  createSession(externalID:email:displayName:traits:) ..... UserID, EmailAddress, Name,
                                                            OtherDataTypes (traits)
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
    Other data ........... DifferentRequests
    Device ID ............ DifferentRequests
```

## Platform differences

The manifest is read by Xcode for every Apple platform this package supports. It says nothing
platform-specific, because what the SDK sends does not vary by platform.

## Which tests walk the chart

There is no test target in this package. Walked by parsing the manifest with `plistlib` and checking
it against the rpcs above — six declared types, `NSPrivacyTracking` false, both API-type and
tracking-domain arrays empty — and by building the package with the resource declared.

The check that matters over time is not a test but a rule: **a new rpc that sends something new is a
manifest change in the same PR.**

Closes #121.
