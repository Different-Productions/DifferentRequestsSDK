# Filing a request

## What it is

**Since 2026-10-09 (#167) the form is a pushed screen, never a sheet**, by the owner's ruling that
only one sheet is ever up. Where this document says "the sheet" about the form before that date,
read "the pushed form". After Send the form goes and the new request's own screen opens; the green
"Your request is posted" strip that left after four seconds is gone. The form's layout, its discard
question and that hand-off are in `one-request-and-asking-for-one.md`. The store, the seeding from
search and every refusal below are unchanged.

The way someone asks for something that is not on the board yet, and the state that survives them
doing it.

Two halves, shipped together because they are the same walk:

1. **A way in from every state of the board.** The board is a list of what other people have asked
   for, and reading it is how someone discovers that their own thing is missing. Asking has to be
   reachable from that moment — from a full board, mid-scroll, with no search typed.
2. **State that outlives the screen.** A SwiftUI view is a value that is thrown away and rebuilt
   whenever anything above it redraws. Everything the SDK's screens read from now belongs to
   `DifferentRequestsHub`, which the host app builds once and holds, so a redraw cannot take the
   loaded board, the reader's place in it, the text in the search field, the comment being written,
   or the half-typed request in the composer.

The composer opens seeded with whatever is in the search field. Reaching it from a search means the
search did not answer, so those words are already the request; reaching it from an unsearched board
opens it empty.

## Surfaces

Every surface this package ships, and whether filing a request appears on it.

| Surface | Files a request? |
| --- | --- |
| `DifferentRequestsView` — the board | Yes: nav-bar button, end-of-list button, and both empty states |
| `SubmitRequestView` — the pushed form | Yes: this is where it is written and sent |
| `RequestDetailView` — one request | No. Reading one request is not the moment for a new one |
| `RoadmapView` | No |
| `ChangelogView` | No |
| `InboxView` | No |
| `VoteControl` — the component | No |
| `DifferentRequestsClient` — the API, for host apps building their own UI | Yes: `submit(title:body:)` |
| `DifferentRequestsHub` — the object the host holds | Yes: `beginSubmission()` opens the composer |
| Example app (`Example/DifferentRequestsExample`) | Yes, through the board in its Requests tab |
| Command line | None. This package ships no executable |
| Web / console | None. Not in this repository |
| watchOS, tvOS, visionOS | None. `Package.swift` declares iOS 18 and macOS 15 only |
| Widgets, App Intents, Shortcuts | None |
| Push notification | None. Filing sends nothing to anyone's device |

## How to find it, trigger it, and what happens

### On the board (`DifferentRequestsView`)

**Find it.** Top right of the navigation bar, a `plus.bubble` button, present in every state the
board can be in — loading, loaded, empty, failed, searched. Again at the end of the list as a
prominent **New request** button under a footer line, and again inside both empty states.

**Trigger it.** Tapping any of them calls `DifferentRequestsHub.beginSubmission()`, which seeds the
composer's title from `BoardStore.query` and clears everything else, and then raises the sheet.

**What happens.** The composer comes up with the search text as the title (or empty if nothing was
searched), the detail field blank, and **Send** disabled until the title has something other than
whitespace in it. Sending files the request, re-reads the board, and dismisses. A failure keeps the
sheet up with everything still typed in it.

### In the composer (`SubmitRequestView`)

**Find it.** It is presented, not pushed, and carries its own `NavigationStack` for **Cancel** and
**Send**.

**Trigger it.** **Send** in the confirmation slot. It is disabled on a blank title, and disables
itself again while the write is in flight so a second tap cannot file the duplicate this whole flow
exists to prevent.

**What happens.** `DifferentRequestsHub.fileRequest()` writes, and on success re-reads the board
before the sheet dismisses — the board underneath is one request out of date the moment the write
lands, and the sheet does not know who presented it.

### Through the API (`DifferentRequestsClient`)

**Find it.** `submit(title:body:)`, for a host app drawing its own composer.

**Trigger it.** Call it. It needs an end-user session: `createRequest` declares `END_USER` audience,
which is checked before anything is sent.

**What happens.** It answers with `DRCreateRequestResponse`, whose request already carries the
author's own vote.

### In the Example app

**Find it.** The Requests tab, which is a `NavigationStack` wrapping `DifferentRequestsView`. Each
tab has its own stack: the SDK's screens need one and none of them carries one, because a navigation
stack belongs to the app arranging the screens rather than to a package dropped inside one.

**Trigger it.** As on the board above.

**What happens.** As on the board above. The app must be run with `DIFFERENT_REQUESTS_APP_KEY` set
in the scheme, or it never signs in and never reaches the board at all.

## Expectations

### Positive

| What someone does | What they get |
| --- | --- |
| Opens a board with requests on it | A `plus.bubble` **New request** button in the nav bar, and **New request** in the "…" menu. Nothing is drawn at the end of the list: on a board with one row a button there floated in the middle of an empty screen |
| Opens a board with nothing on it | "No requests yet" / "Ask for what you want in this app, and everyone can vote on it." and **New request** |
| Searches for something nobody has asked for | "No requests match your search" / "Nobody has asked for this yet." and **New request** |
| Searches, gets matches, and none of them is theirs | The matches; opening **New request** warns "If a request already says this, vote for it instead, so the votes stay in one place." |
| Taps any way in after searching "dark mode" | The composer, titled `dark mode`, detail blank |
| Taps the nav-bar button with no search typed | The composer, both fields empty, **Send** disabled |
| Types a title and sends | The request is filed with their own vote and follow on it, the board re-reads, the form goes, and the new request's own screen opens (2026-10-09; it replaced a "Your request is posted" strip that faded after four seconds) |
| Taps the "posted" strip while it shows | The request they just filed opens |
| Sends, then opens the composer again | Both fields empty — the last request is not still sitting there |
| Types half a request while something above the board redraws | Both fields still say what they said; the draft belongs to the hub, not to the sheet |
| Scrolls four pages in, opens a request, comes back | The same four pages and the same place in them |
| Types a search while the first page is still loading | The search is read once the page in flight lands, not dropped |
| Leaves the board and comes back | The same page, not a re-read; the store already answers the query in the field |

### Negative

| What happens | What they see |
| --- | --- |
| Title is empty, or only spaces and newlines | **Send** is grayed out and does nothing. No error text — nothing has been attempted |
| The write is in flight | **Send** is grayed out for the duration; a second tap cannot file a second request |
| No end-user session exists (`createSession` was never called) | "Your request didn't send. What you wrote is still here. Choose Send to try again." The thrown `DifferentRequestsError.notAuthenticated(.createRequest)` never reaches the network, and reaches the developer through `SubmitStore.write.failure?.error` |
| The server refuses — plan required, rate limited, anything with a `DRApiError` | "Your request didn't send. What you wrote is still here. Choose Send to try again." The server's own message is written for whoever is debugging and may name internals, so it is not shown |
| The network is unreachable or times out | "Your request didn't send. What you wrote is still here. Choose Send to try again." |
| Any failure at all while sending | The sheet stays up with the title and detail exactly as typed. Dismissing on a failure would throw the words away |
| The request files but re-reading the board fails | The sheet closes — the request was filed — and the board shows "Requests couldn't load" / "Something went wrong on the server. Try again in a moment." with **Try again** |
| The board's first read fails | The same "Requests couldn't load" screen, with the nav-bar way in still there: a board that cannot be read is not a reason to be unable to ask |
| The host app forgets the `NavigationStack` | No title, no nav-bar button, no search field, and rows push nothing. Every SDK screen's doc comment states the requirement; the Example is the worked example |

## The code path

```
Host app (composition root, built once and held)
  DifferentRequestsExampleApp.swift
    let session = Session(hub: DifferentRequestsHub(client:appearance:emptyBoard:))
        │
        ▼
  DifferentRequestsHub.swift ─── init assigns, in dependency order:
    client · board(BoardStore) · roadmap · changelog · inbox
    submission(SubmitStore)
        │
        │  RootView.swift:  NavigationStack { DifferentRequestsView(hub:) }
        ▼
  DifferentRequestsView.swift
    init  ─────────────────────────►  _store = Bindable(hub.board)      (constructs nothing)
    body
     ├── .searchable(text: $store.query) ──► BoardStore.query
     ├── .toolbar { primaryAction: askButton.labelStyle(.iconOnly) }    ── always present
     ├── .firstRead(store.read)  ──► View+FirstRead.swift ──► BoardStore.load()   once per store
     ├── .task(id: store.query)  ──► runSearch()
     │        ├── store.isShowingQuery == true  ──► return   (a redraw is not a search)
     │        ├── query non-empty ──► Task.sleep(300ms)      (canceled by the next keystroke)
     │        └── BoardStore.load()
     │              repeat { loadedQuery = query; fetchPage() } while loadedQuery != query
     │                                    └──► DifferentRequestsClient.requests(...)
     ├── list ──► askButton + askFooter        (end of list, every state)
     ├── empty ──► ContentUnavailableView + askButton   (both empty states)
     └── RequestsScreen.swift .navigationDestination(isPresented: $isComposing) ──► SubmitRequestView(hub:)

  askButton tapped
        │
        ├──► DifferentRequestsHub.beginSubmission()
        │        └──► SubmitStore.begin(title: board.query)
        │                 title = query · body = "" · submitted = nil · write = .idle
        └──► isComposing = true            (the view's only job: navigation)

  SubmitRequestView.swift
    init ──────────────────────────►  _store = Bindable(hub.submission)  (constructs nothing)
    Form
     ├── TextField("What you want, in a few words", text: $store.title)
     ├── TextField("Why you'd use it (optional)", text: $store.body)
     ├── if let failure = store.write.failure ──► WriteFailureNotice.swift
     │        "Your request didn't send. What you wrote is still here. Choose Send to try again."  + Dismiss
     └── toolbar
          ├── Cancel ──► dismiss()
          └── AsyncButton(Send).disabled(store.canSubmit == false)
                    AsyncButton.swift: @State isRunning + .disabled(isRunning)
                        │
                        ▼
                  send()  ──► DifferentRequestsHub.fileRequest()
                                 ├── SubmitStore.submit()
                                 │      guard !write.isWriting · trim title · guard non-empty
                                 │      └──► DifferentRequestsClient.submit(title:body:)
                                 │             └──► perform(.createRequest, body:)
                                 │                    ├── rpc.audience == .endUser && no token
                                 │                    │     └──► throw .notAuthenticated(rpc)
                                 │                    ├── POST, protobuf both ways
                                 │                    ├── non-2xx ──► throw .api(DRApiError)
                                 │                    └── 2xx ──► DRCreateRequestResponse
                                 │      success ──► submitted = written.request
                                 │      failure ──► write = .failed(WriteFailure(.fileRequest,
                                 │                                              error))  (sheet stays up)
                                 └── submitted == nil ? return : BoardStore.load()
                        │
                        ▼
                  store.write.failure == nil ? dismiss() : stay up
                        │
                        ▼
RequestsScreen.swift  (isComposing became false, hub.submission.submitted is held)
                         ──► openedRequestID = submitted.id ; SubmitStore.putAwaySubmitted()
                         ──► .navigationDestination(item:) ──► RequestDetailView.swift
```

Pushing a request off the board gives the screen its own store, Apple's `@State` model pattern:

```
DifferentRequestsView.row ──► RequestDetailView(hub:requestID:)          RequestDetailView.swift
                                 init ──► _store = State(initialValue:
                                            RequestDetailStore(client:requestID:
                                              notificationOffer:firstVoteNote:))   RequestDetailStore.swift
                                 the board redraws ──► SwiftUI keeps the same store
                                 the screen is popped ──► SwiftUI frees it
```

## The screens

```
DifferentRequestsView — loaded, nothing searched
┌──────────────────────────────────────────────┐
│  Requests                             [ ⊕ ]  │ ← always here, every state of the board
│ ┌──────────────────────────────────────────┐ │   (plus.bubble, .labelStyle(.iconOnly))
│ │ 🔍 Search requests                       │ │ ← .searchable; text lives on BoardStore
│ └──────────────────────────────────────────┘ │
│  ⌃    Dark mode everywhere                   │
│ 128   Please. My eyes.                       │
│       [Planned]  💬 12          3 days ago   │
│ ─────────────────────────────────────────── │
│  ⌃    Offline drafts                         │
│  74   …                                      │
│       [Open]                    last week    │
│ ─────────────────────────────────────────── │
│              ( spinner )                     │ ← NextPageRow, while page is not .done
└──────────────────────────────────────────────┘
  asking is the nav bar's [ ⊕ ] and the "…" menu; nothing is drawn after the last row

  searched, with matches → the composer warns instead:
    "If a request already says this, vote for it instead, so the votes stay in one place."

  first read in flight        → centred spinner, nav bar and [ ⊕ ] still there
  read failed, nothing held   → "Requests couldn't load" + "Something went wrong on the server. Try again in a moment." + [Try again]
  loaded, board empty         → "No requests yet" + "Ask for what you want in this app, and
                                 everyone can vote on it." + [ ⊕ New request ]
  loaded, search matched none → "No requests match your search" + "Nobody has asked for this yet."
                                 + [ ⊕ New request ]

SubmitRequestView — presented over the board
┌──────────────────────────────────────────────┐
│ Cancel          New request            Send  │ ← Send grayed while title is blank,
│                                              │   and grayed again while the write runs
│  TITLE                                       │
│ ┌──────────────────────────────────────────┐ │
│ │ dark mode                                │ │ ← seeded from the search field
│ └──────────────────────────────────────────┘ │
│  One sentence. This is what everyone else    │
│  votes on.                                   │
│                                              │
│  DETAILS                                     │
│ ┌──────────────────────────────────────────┐ │
│ │ Why you'd use it (optional)              │ │ ← 3…8 lines, grows as it is typed
│ │                                          │ │
│ └──────────────────────────────────────────┘ │
│  ⚠  Your request didn't send.        Dismiss │ ← only after a failed write, in the details
│     What you wrote is still here.            │   footer; the fields above still hold
│     Choose Send to try again.                │   everything typed
└──────────────────────────────────────────────┘

  in flight  : Send dimmed and inert (AsyncButton's isRunning), fields still editable
  disabled   : Send dimmed whenever the title trims to nothing
  success    : the form goes; the board has re-read, and the new request's own screen opens.
```

## Platform differences

- **iOS 18+ and macOS 15+.** `Package.swift` declares no other platform, so there is no watchOS,
  tvOS or visionOS behavior to describe.
- **The nav-bar way in.** `ToolbarItem(placement: .primaryAction)` lands at the trailing edge of the
  navigation bar on iOS and in the window toolbar on macOS. `.labelStyle(.iconOnly)` is stated
  rather than left to the platform so the glyph is the same in both, and the label text survives as
  the accessibility label either way.
- **The search field.** `.searchable` is a field under the title on iOS and a toolbar search field
  on macOS. Both write the same `BoardStore.query`, so both seed the composer identically.
- **The form.** Pushed onto the Requests tab's own `NavigationStack` on both platforms, with its
  own **Cancel** and **Send** and no back button.
- **The stack around it all.** `DifferentRequestsView` brings one `NavigationStack` per tab. A host
  app that pushes `SubmitRequestView` itself pushes it onto its own.

## Which tests walk the chart

There is no test target — see the server's #144. Walked in the example app on a simulator, against
development.

The walk, and what it answered:

| Step | Answer |
|---|---|
| Open the board with somebody signed in | **New request** is offered |
| Open it with nobody signed in | No ask button anywhere — nothing is offered that can only fail |
| Type a title past 200 characters | "24 characters too many" in red, and Send refused while it is over |
| Cut it back and press Send | The sheet dismisses and the row is on the board, one vote, Open |
| 2026-09-26, iOS 27 simulator: send "Walk: the board says it is posted" | The sheet closed; a green "Your request is posted. You're following it." sat under the filter bar above the new row, and was gone five seconds later |
| 2026-09-27, iOS 27 simulator "DR Permission Walk", development: type a comment on a request, leave the app and come back, then vote (which redraws the board beneath) | The half-written comment is still in the box both times |
| Back out of that request and open it again | A fresh screen: the comment box is empty, the vote is still yours. The screen's store went when it was popped |
| Send with the network down | The composer keeps what was typed and says it did not send |
| 2026-10-09, iOS 26.0 simulator "DR Redesign Walk", local server, a Pro app ("Calls Walk"): tap the plus, type a title, tap Cancel | The form is pushed with Cancel and Send. Cancel asked "Discard this request?" with **Discard request** |
| The same walk: send "Redesign walk: filed from the pushed form" | The form went and that request's own screen opened, with one vote, Following, and a back button to Requests |

