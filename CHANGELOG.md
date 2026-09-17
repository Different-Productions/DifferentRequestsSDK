# Changelog

Every released version, newest first. Versions are tags on the public repository,
`Different-Productions/DifferentRequestsSDK`.

## 0.10.0 — 2026-09-17

**One source change to make: `createSession` takes a `proof`.** Pass `nil` until you ask for a
signing secret; nothing else about signing somebody in changes.

- Your own backend can vouch for a person. Give your app a signing secret in the console, sign the
  identifier and an expiry with it, and hand the app what comes back — `DRIdentityProof(signature:
  expiresAt:)` is what carries it. Once an app has a secret, every session for it needs a proof.
- A refused sign-in is written where a developer reads it and drawn nowhere: the reasons are all the
  integration's, and the board still reads with the app key alone.
- The example app signs its own proof from `DIFFERENT_REQUESTS_SIGNING_SECRET`, standing in for a
  backend, and carries on with nobody signed in when the server refuses.

## 0.9.0 — 2026-09-17

**One source change to make: `DifferentRequestsHub(client:)` is now
`DifferentRequestsHub(client:appearance:)`.** Pass `.standard` for the look 0.8.0 had, or an
`Appearance` with your app's accent and a system font design.

- Every screen wears the host app's accent and font design, set once on the hub.
- A control that acts for a person is offered only when somebody is signed in, so a board with no
  session no longer offers a request that can only fail.
- The composer counts against the title limit the contract declares, and a request the server read
  and refused says what to change instead of "try again".
- The board's filter offers only the statuses a board shows.
- A request opened from a notification reads itself again instead of showing the copy it already
  had.
- A request filed a moment ago says so rather than "in 1 second", one vote reads "1 vote", and
  opening a notification marks it read.
- The badge sits under the board's title instead of pinned over the bottom, and the board draws a
  Done button only where something presented it.
- The documentation lives at differentrequests.com/docs; the README points there.
- Pins contract 0.36.0.
- The SDK and the contract moved to private repositories. Host apps fetch the public copy, which
  holds every release tag at the same commit, so nothing about `.package(url:from:)` changes.
- The example app demonstrates the SDK rather than its own screens, and a read is no longer canceled
  by its own answer.
- The SDK ships a privacy manifest declaring what it collects, and refuses a plain `http` base URL.
- `describeIntegration()` says what the SDK is pointed at, for a diagnostics screen.
- A status and a notification are drawn with the words the contract carries, so this package and the
  console cannot name the same thing differently.
- The board survives one request it cannot read, instead of failing whole.
- A free app carries the "Powered by Different Requests" badge.

## 0.8.0 — 2026-08-28

- A duplicate says what it is, and names the request it was folded into.
- The documentation describes the SDK that exists.

## 0.7.0 — 2026-08-28

**A total break from 0.6.x. Every method was renamed and every model type replaced.** There is no
shim, and 0.6.x does not talk to the current API at all. Move by deleting the old integration and
following the Quick start in the README again.

- The SDK speaks the wire contract instead of describing it a second time in JSON. Every type it
  sends and receives is generated from that contract.
- The host app builds one `DifferentRequestsHub` and hands it to the screens, so a page, a search
  and a half-written request survive a redraw above them.
- The screens the contract describes: board, request detail, composer, roadmap, changelog and inbox.
- A screen asks what the app's plan includes before it draws a surface that needs it, instead of
  drawing one that is refused when tapped.
- A refusal reaches the person who made it: one state per store, and a write that does not land puts
  a line next to the control that was tapped.
- The board can be read before it is shown, so it draws rows on the first frame.
- MIT license stated in the package, as the README already promised.

## 0.6.2 — 2026-07-17

The last JSON client. It does not talk to the current API.
