# Filing a request

## What it is

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
| `SubmitRequestView` — the composer sheet | Yes: this is where it is written and sent |
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
prominent **Ask for a feature** button under a footer line, and again inside both empty states.

**Trigger it.** Tapping any of them calls `DifferentRequestsHub.beginSubmission()`, which seeds the
composer's title from `BoardStore.query` and clears everything else, and then raises the sheet.

**What happens.** The composer comes up with the search text as the title (or empty if nothing was
searched), the detail field blank, and **Submit** disabled until the title has something other than
whitespace in it. Sending files the request, re-reads the board, and dismisses. A failure keeps the
sheet up with everything still typed in it.

### In the composer (`SubmitRequestView`)

**Find it.** It is presented, not pushed, and carries its own `NavigationStack` for **Cancel** and
**Submit**.

**Trigger it.** **Submit** in the confirmation slot. It is disabled on a blank title, and disables
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
| Opens a board with requests on it | A `plus.bubble` button in the nav bar, and **Ask for a feature** at the end of the list under "Not on the board? Ask for it." |
| Opens a board with nothing on it | "No requests yet" / "Nobody has asked for anything. Be first." and **Ask for a feature** |
| Searches for something nobody has asked for | "Nothing matches" / "Nobody has asked for this yet." and **Ask for a feature** |
| Searches, gets matches, and none of them is theirs | The matches, then **Ask for a feature** under "Vote for one of these if it already says it — duplicates split the demand." |
| Taps any way in after searching "dark mode" | The composer, titled `dark mode`, detail blank |
| Taps the nav-bar button with no search typed | The composer, both fields empty, **Submit** disabled |
| Types a title and sends | The request is filed with their own vote on it, the board re-reads, the sheet closes |
| Sends, then opens the composer again | Both fields empty — the last request is not still sitting there |
| Types half a request while something above the board redraws | Both fields still say what they said; the draft belongs to the hub, not to the sheet |
| Scrolls four pages in, opens a request, comes back | The same four pages and the same place in them |
| Types a search while the first page is still loading | The search is read once the page in flight lands, not dropped |
| Leaves the board and comes back | The same page, not a re-read; the store already answers the query in the field |

### Negative

| What happens | What they see |
| --- | --- |
| Title is empty, or only spaces and newlines | **Submit** is greyed out and does nothing. No error text — nothing has been attempted |
| The write is in flight | **Submit** is greyed out for the duration; a second tap cannot file a second request |
| No end-user session exists (`createSession` was never called) | "That didn't send. Try again in a moment." The thrown `DifferentRequestsError.notAuthenticated(.createRequest)` never reaches the network, and reaches the developer through `SubmitStore.write.failure?.error` |
| The server refuses — plan required, rate limited, anything with a `DRApiError` | "That didn't send. Try again in a moment." The server's own message is written for whoever is debugging and may name internals, so it is not shown |
| The network is unreachable or times out | "That didn't send. Try again in a moment." |
| Any failure at all while sending | The sheet stays up with the title and detail exactly as typed. Dismissing on a failure would throw the words away |
| The request files but re-reading the board fails | The sheet closes — the request was filed — and the board shows "Couldn't load" / "Something went wrong reaching the server. Check your connection and try again." with **Try Again** |
| The board's first read fails | The same "Couldn't load" screen, with the nav-bar way in still there: a board that cannot be read is not a reason to be unable to ask |
| The host app forgets the `NavigationStack` | No title, no nav-bar button, no search field, and rows push nothing. Every SDK screen's doc comment states the requirement; the Example is the worked example |

## The code path

```
Host app (composition root, built once and held)
  DifferentRequestsExampleApp.swift
    let session = Session(hub: DifferentRequestsHub(client: .make(appKey:)))
        │
        ▼
  DifferentRequestsHub.swift ─── init assigns, in dependency order:
    client · board(BoardStore) · roadmap · changelog · inbox
    submission(SubmitStore) · details(RequestDetailStores)
        │
        │  RootView.swift:  NavigationStack { DifferentRequestsView(hub:) }
        ▼
  DifferentRequestsView.swift
    init  ─────────────────────────►  _store = Bindable(hub.board)      (constructs nothing)
    body
     ├── .searchable(text: $store.query) ──► BoardStore.query
     ├── .toolbar { primaryAction: askButton.labelStyle(.iconOnly) }    ── always present
     ├── .firstRead(store.read)  ──► FirstRead.swift ──► BoardStore.load()   once per store
     ├── .task(id: store.query)  ──► runSearch()
     │        ├── store.isShowingQuery == true  ──► return   (a redraw is not a search)
     │        ├── query non-empty ──► Task.sleep(300ms)      (cancelled by the next keystroke)
     │        └── BoardStore.load()
     │              repeat { loadedQuery = query; fetchPage() } while loadedQuery != query
     │                                    └──► DifferentRequestsClient.requests(...)
     ├── list ──► askButton + askFooter        (end of list, every state)
     ├── empty ──► ContentUnavailableView + askButton   (both empty states)
     └── .sheet(isPresented: $isComposing) ──► SubmitRequestView(hub:)

  askButton tapped
        │
        ├──► DifferentRequestsHub.beginSubmission()
        │        └──► SubmitStore.begin(title: board.query)
        │                 title = query · body = "" · submitted = nil · write = .idle
        └──► isComposing = true            (the view's only job: navigation)

  SubmitRequestView.swift
    init ──────────────────────────►  _store = Bindable(hub.submission)  (constructs nothing)
    Form
     ├── TextField("Title",  text: $store.title)
     ├── TextField("Detail", text: $store.body)
     ├── if let failure = store.write.failure ──► WriteFailureNotice.swift
     │        "That didn't send. Try again in a moment."  + Dismiss
     └── toolbar
          ├── Cancel ──► dismiss()
          └── AsyncButton(Submit).disabled(store.canSubmit == false)
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
                  store.submitted == nil ? stay up : dismiss()
```

Pushing a request off the board walks the same lifetime rule:

```
DifferentRequestsView.row ──► RequestDetailView(hub:requestID:)
                                 init ──► hub.detail(requestID:)
                                            └──► RequestDetailStores.store(requestID:)
                                                   held? ──► the same store as last time
                                                   new?  ──► RequestDetailStore(client:requestID:)
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
│ ─────────────────────────────────────────── │
│        ┌────────────────────────────┐        │
│        │ ⊕  Ask for a feature       │        │ ← end of list, every state
│        └────────────────────────────┘        │
│   Not on the board? Ask for it.              │
└──────────────────────────────────────────────┘

  searched, with matches → same list, footer reads instead:
    "Vote for one of these if it already says it — duplicates split the demand."

  first read in flight        → centred spinner, nav bar and [ ⊕ ] still there
  read failed, nothing held   → "Couldn't load" + "Something went wrong reaching the
                                 server. Check your connection and try again." + [Try Again]
  loaded, board empty         → "No requests yet" + "Nobody has asked for anything.
                                 Be first." + [ ⊕ Ask for a feature ]
  loaded, search matched none → "Nothing matches" + "Nobody has asked for this yet."
                                 + [ ⊕ Ask for a feature ]

SubmitRequestView — presented over the board
┌──────────────────────────────────────────────┐
│ Cancel      Ask for a feature        Submit  │ ← Submit greyed while title is blank,
│                                              │   and greyed again while the write runs
│  WHAT DO YOU WANT?                           │
│ ┌──────────────────────────────────────────┐ │
│ │ dark mode                                │ │ ← seeded from the search field
│ └──────────────────────────────────────────┘ │
│  One sentence. This is what everyone else    │
│  votes on.                                   │
│                                              │
│  ANYTHING ELSE?                              │
│ ┌──────────────────────────────────────────┐ │
│ │ Detail                                   │ │ ← 3…8 lines, grows as it is typed
│ │                                          │ │
│ └──────────────────────────────────────────┘ │
│                                              │
│  ⚠  That didn't send. Try again in a moment. │ ← only after a failed write; the fields
└──────────────────────────────────────────────┘   above still hold everything typed

  in flight  : Submit dimmed and inert (AsyncButton's isRunning), fields still editable
  disabled   : Submit dimmed whenever the title trims to nothing
  success    : sheet dismisses; the board underneath has re-read and the new request is on it
```

## Platform differences

- **iOS 18+ and macOS 15+.** `Package.swift` declares no other platform, so there is no watchOS,
  tvOS or visionOS behaviour to describe.
- **The nav-bar way in.** `ToolbarItem(placement: .primaryAction)` lands at the trailing edge of the
  navigation bar on iOS and in the window toolbar on macOS. `.labelStyle(.iconOnly)` is stated
  rather than left to the platform so the glyph is the same in both, and the label text survives as
  the accessibility label either way.
- **The search field.** `.searchable` is a field under the title on iOS and a toolbar search field
  on macOS. Both write the same `BoardStore.query`, so both seed the composer identically.
- **The composer.** A card sheet on iOS, a window-modal sheet on macOS. It carries its own
  `NavigationStack` so **Cancel** and **Submit** have a bar in both.
- **The stack around it all.** The host app owns it on every platform. The SDK ships no
  `NavigationStack` of its own except inside the composer sheet.

## Tests that walk this

`Tests/DifferentRequestsTests/HubTests.swift`, all hermetic — no live network in a required lane, so
they walk everything on the chart up to the client call and nothing past it.

| Test | The leg it walks |
| --- | --- |
| `oneRequestKeepsOneStore` | `hub.detail(requestID:)` → `RequestDetailStores.store(requestID:)` hands back the same store, with the same half-written comment, however many times a rebuilt screen asks |
| `twoRequestsDoNotShareAStore` | The same call for a different id is a different store, and it starts empty |
| `theComposerOpensOnWhatWasSearched` | `beginSubmission()` → `SubmitStore.begin(title:)` seeds the title from `BoardStore.query` |
| `theComposerOpensEmptyFromAnUnsearchedBoard` | The same call with nothing searched, and the previous draft cleared with it |
| `aBlankTitleCannotBeFiled` | `SubmitStore.canSubmit` — the gate behind **Submit**'s disabled state, for empty and whitespace-only titles |
| `nothingIsShownBeforeTheFirstRead` | `BoardStore.isShowingQuery` is false before any read, so `runSearch()` does not mistake a never-read board for one already showing the query |
| `theBoardTheHubBuildsExcludesNoStatus` | Walks `DRRequestStatus.allCases` against the board the hub builds, proving no status is filtered out of it |

Not walked here, and why:

- **Everything past `client.submit(...)`** — the POST, the audience refusal, the `DRApiError`
  branch. Those need a server or a stubbed transport; the audience gate itself is covered by
  `AudienceTests.actingForAPersonRequiresASession`, which asserts `createRequest` requires an
  end-user session.
- **The SwiftUI legs** — the toolbar tap, the sheet presentation, the disabled **Submit**. They need
  a host app; the Example is that host app, and the owner verifies it by running it.
