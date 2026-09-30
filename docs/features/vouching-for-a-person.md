# Vouching for a person

## What it is

`createSession` carries a proof from the host developer's own backend.

An app key ships inside a binary, so anybody who installs the app can read it and ask for a session
as anyone whose identifier they can guess. A signing secret lives on the developer's server, and a
proof signed with it is that server saying the identifier is theirs.

This SDK only carries the proof. It cannot make one — nothing on the device holds the secret.

| Half | Where |
|---|---|
| Making the proof | The host developer's backend, HMAC-SHA256 |
| Carrying it | `createSession(externalID:email:displayName:proof:)` |
| Checking it | The server, `IdentityProofVerifier` (server #236) |

## Surfaces

| Surface | Ships this? |
|---|---|
| The SDK library | **Yes** — `DifferentRequestsClient.createSession`, `DRIdentityProof+Signed.swift` |
| The SDK's screens | **None.** A refused sign-in draws nothing; the board reads with the app key |
| The example app | **Yes** — `DemoBackend` stands in for a developer's backend |
| The DocC catalog | **Yes** — GettingStarted, "Vouch for a person" |
| The console and its documentation | **None here.** The secret is made in the console (server #236) |
| The server | **None here.** Verifying is server #236 |

## How to find it, trigger it, and what happens

### In an integration

`proof` is required at the call site and `nil` is the right answer until the app has a signing
secret:

```swift
try await requests.client.createSession(
  externalID: currentUser.id,
  email: currentUser.email,
  displayName: currentUser.name,
  proof: nil
)
```

With a secret, the backend signs the identifier and an expiry and the app carries both:

```swift
proof: DRIdentityProof(signature: vouched.signature, expiresAt: vouched.expiresAt)
```

``DRIdentityProof/init(signature:expiresAt:)`` drops fractions of a second, because whole seconds
since the epoch is what was signed.

### In the example app

The secret arrives in the environment, next to the app key, and `DemoBackend` signs with it:

```sh
SIMCTL_CHILD_DIFFERENT_REQUESTS_APP_KEY=<key> \
SIMCTL_CHILD_DIFFERENT_REQUESTS_SIGNING_SECRET=<secret> \
SIMCTL_CHILD_DIFFERENT_REQUESTS_BASE_URL=https://api-dev.differentrequests.com \
  xcrun simctl launch <device> productions.different.DifferentRequestsExample
```

Unset the secret and the app sends no proof, which is what an app without one does.

## Expectations

### What works

| Given | When | Then |
|---|---|---|
| An app with no signing secret, `proof: nil` | Signing in | A session, as before this existed |
| An app with no signing secret, a proof sent anyway | Signing in | A session. The server has nothing to check it against and ignores it |
| An app with a secret, a proof signed with it | Signing in | A session, and the person's email and name are refreshed |
| A proof expiring in five minutes | Signing in | Accepted. An hour is the longest the server accepts |
| A `Date` carrying fractions of a second | Building the proof | The whole second is sent — the number that was signed |

### What does not happen

**Nobody is shown any of these.** Every one is the integration's to fix, and the person holding the
phone can act on none of them, so the SDK throws and the host app logs. The board still reads, and
asking, voting and commenting are not offered while nobody is signed in.

| Given | When | Then, in the log | On screen |
|---|---|---|---|
| An app with a secret, `proof: nil` | Signing in | `Sign-in refused: unauthenticated: This app signs its sessions. Send a proof from your backend.` | Nothing |
| A proof whose expiry has passed | Signing in | `Sign-in refused: unauthenticated: That proof has expired.` | Nothing |
| A proof good for a day | Signing in | `Sign-in refused: unauthenticated: That proof lasts too long. Sign one that expires within an hour.` | Nothing |
| A proof signed with a replaced secret | Signing in | `Sign-in refused: unauthenticated: That proof was not signed with this app's secret.` | Nothing |
| A proof signed for somebody else's identifier | Signing in | `Sign-in refused: unauthenticated: That proof was not signed with this app's secret.` | Nothing |
| The SDK asked to sign a proof | Never | There is no API for it. The secret is not on the device | — |

## Flow chart of the real code path

```
host app (or DemoBackend, standing in for one)
  │  HMAC-SHA256 over "<externalID>\n<expiry seconds>", keyed by the signing secret
  │  spelled URL-safe base64                      (DemoBackend.swift, Data+URLSafeBase64.swift)
  ▼
DRIdentityProof(signature:expiresAt:)             (DRIdentityProof+Signed.swift)
  │  Int64(expiresAt.timeIntervalSince1970), nanos 0 — the whole second that was signed
  ▼
DifferentRequestsClient.createSession(…, proof:)  (DifferentRequestsClient.swift)
  │  if let proof { body.proof = proof }          — absent stays absent on the wire
  ▼
perform(.createSession, body:)
  │  X-App-Key, protobuf both ways
  ▼
the server                                        (DifferentRequests-Server, server #236)
  ├─ no secret for this app ──────────────────► answered as before, proof ignored
  ├─ secret, proof adds up ───────────────────► session, email and name refreshed
  └─ secret, proof missing or wrong ──────────► RPCFailure(unauthenticated:)
                                                   │
       DifferentRequestsError.api(DRApiError) ◄────┘
         │  errorDescription = "unauthenticated: <what the server said>"
         ▼
       Session.signIn() catch                     (Session.swift)
         └─ NSLog("Sign-in refused: %@")          — and nothing is drawn
```

## UI map

```
The example app, signed in (a proof was accepted, or the app has no secret)
┌──────────────────────────────────────────────┐
│ Example                                      │
│ Your app                                     │
│  ⌸ Requests                                › │
│  ⌸ Inbox                                 3 › │ ← the badge needs a session
│  ⌸ Diagnostics                             › │
└──────────────────────────────────────────────┘

The same app, sign-in refused — identical, minus what needs a person
┌──────────────────────────────────────────────┐
│ Example                                      │
│ Your app                                     │
│  ⌸ Requests                                › │ ← opens, reads, rows draw
│  ⌸ Inbox                                   › │ ← no badge: nobody to count for
│  ⌸ Diagnostics                             › │ ← says "signed in  nobody"
└──────────────────────────────────────────────┘
No alert, no banner, no red text. The refusal is in the log only.

Inside the board, with nobody signed in
┌──────────────────────────────────────────────┐
│ Requests                                     │
│  ^ 12  Dark mode on the widget               │ ← VoteTally: the count, nothing to press
│  ^  4  Export to CSV                         │
└──────────────────────────────────────────────┘
  no "+", and the "…" menu offers neither New request nor Inbox;
  with no Roadmap or What's New either, the menu is not drawn at all

A request, with nobody signed in
  the count as a VoteTally, no Follow, and no comment strip

The Inbox, with nobody signed in
  "Nothing yet", and nothing is read from the server

In flight
  Starting…            the whole root, while the session and the config are read
  Can't reach Different Requests + Try again    only when the config read fails
```

## Platform differences

| Platform | Difference |
|---|---|
| iOS, macOS | None. The proof is a value in a request; nothing platform-specific touches it |
| The example app on a simulator | `SIMCTL_CHILD_DIFFERENT_REQUESTS_SIGNING_SECRET` passes the secret through `simctl launch` |
| A real backend | Any language. HMAC-SHA256 and URL-safe base64 are all it needs |

## What walks the chart

There is no test target in this package (server #144). The chart is walked against
`api-dev.differentrequests.com` through the example app on a simulator:

Walked 2026-09-17 against `api-dev.differentrequests.com`, app **Identity Walk**
(`app_9124616c43854fd68602952f94bbb9ae`, a signing secret) and **Walk Provisioned App**
(`app_4c57b12890ff457fa8fa0553b423ab99`, none), on a booted iPhone 17 Pro:

| Walk | Result |
|---|---|
| Build the package and the example | `** BUILD SUCCEEDED **` for both; CI builds both on every change |
| Secret on the app, a proof signed with it | `Signed in as usr_be74efa0f8b4441197657a1462433365`, and the console's People page finds `walk-vouched` under the name the call sent |
| Secret on the app, no proof | `Sign-in refused: unauthenticated: This app signs its sessions. Send a proof from your backend.` The screen is pixel for pixel the signed-in one: no alert, no banner, no message |
| Secret on the app, a proof signed with a different secret | `Sign-in refused: unauthenticated: That proof was not signed with this app's secret.` |
| A proof whose expiry has passed | `Sign-in refused: unauthenticated: That proof has expired.` Walked by signing with a negative lifetime, then putting the five minutes back |
| No secret on the app, a proof sent anyway | `Signed in as usr_31ab7ae7f16d4f99948f133074856972` — the server has nothing to check it against and ignores it |

Walked 2026-09-25 in the example app on an iPhone 17 Pro simulator against development, on an app
given a signing secret and launched without a proof (#110):

| Step | What it answered |
|---|---|
| The board | No "+", no "…" menu (a Free app, so it would hold nothing), and each row's count drawn with nothing to press |
| A request | "4 votes" and nothing to press: no Follow, no comment strip |
| The Inbox | "Nothing yet", not "Couldn't load… Check your connection" |
| The secret removed, relaunched | Signed in: "+", "…", Vote, Follow and the comment strip are all back |

Before the fix the same walk found the menu offering New request, and Vote, Follow and the
comment box on screen, each answering "Your vote didn't go through. Try it again." or "That didn't
send. It's still written — send it again." when pressed.
