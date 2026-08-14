# Sorting and filtering the board

## What it is

The bar above the board that decides two things about what is on it: how the requests are ranked,
and which statuses they are drawn from. Together with the search field they are the three narrowings
the list rpc takes, and each of them is one query parameter on the same call.

Three things ship together here, because they are one behaviour:

1. **A bar that offers what the contract can send, and only that.** What appears on it is
   `DRRequestSort.allCases` and `DRRequestStatus.allCases` filtered to the values that have a
   `urlToken`. A value with no declared spelling cannot be put in a query string, which is what
   keeps `unspecified` — the zero every proto enum decodes to by default — off the bar and out of
   the URL. Nothing in this package lists a status or a ranking, so one added to the contract
   arrives here by being declared.
2. **Statuses and sort that are settable, and a cursor that knows it.** `BoardStore` compares the
   whole question it is being asked — statuses, sort and search text as one `BoardQuestion` — rather
   than one property at a time. A cursor addresses the results of the question it was handed back
   for, so changing any of the three throws away the pages held under the old one and starts at page
   one.
3. **A bar that is reachable in every state the board can be in.** It is drawn above the content,
   not inside the list. Narrowing to a status nothing is in replaces the list with an empty state,
   and a filter that lived inside that list would vanish at the exact moment it has to be undone —
   leaving a page that says the app has no feature requests, which is not true and cannot be argued
   with.

Both controls shipped in the released 0.6.2 and are absent from the proto rewrite on `master`, where
`DifferentRequestsHub` builds its board with `statuses: [], sort: .top` and no way to change either.
This is the regression closed.

## Surfaces

Every surface this package ships, and whether the board can be sorted or filtered on it.

| Surface | Sorts or filters? |
| --- | --- |
| `DifferentRequestsView` — the board | Yes: the filter bar, in all four read states |
| `BoardFilterBar` — the bar itself | Yes: this is it. Internal; it is not a component a host app places |
| `FilterChip` — one capsule on the bar | Yes: one narrowing, on or off. Internal |
| `SubmitRequestView` — the composer sheet | No. It carries the search text as a title and nothing else |
| `RequestDetailView` — one request | No. One request has one status |
| `RoadmapView` | No. The roadmap is already grouped into columns by the server, in the order the tenant set |
| `ChangelogView` | No. Published entries, newest first, and no other order offered |
| `InboxView` | No |
| `VoteControl` — the component | No |
| `StatusBadge` — the component | No. It renders a status; the chips reuse its `badgeLabel` so a status is called the same word in both places |
| `DifferentRequestsClient` — the API, for host apps building their own UI | Yes: `requests(statuses:sort:query:cursor:)`, with `statuses` sent comma-separated and `sort` as its token |
| `DifferentRequestsHub` — the object the host holds | Its board starts as everything, ranked `.top`. `BoardStore` is internal, so a host narrows it through the bar or calls the client itself |
| Example app (`Example/DifferentRequestsExample`) | Yes, through the board in its Requests tab |
| Command line | None. This package ships no executable |
| Web / console | None. Not in this repository |
| watchOS, tvOS, visionOS | None. `Package.swift` declares iOS 18 and macOS 15 only |
| Widgets, App Intents, Shortcuts | None |
| Push notification | None. Narrowing a board sends nothing to anyone's device |

## How to find it, trigger it, and what happens

### On the board (`DifferentRequestsView`)

**Find it.** A strip directly under the navigation bar and the search field, above whatever the board
is showing — a spinner, a failure, an empty state or the list. It reads left to right: the rankings,
a divider, then **All** and one capsule per status.

**Trigger it.** Tap a capsule.

- A ranking capsule calls `BoardStore.show(sort:)`.
- A status capsule calls `BoardStore.toggle(status:)` — on if it was off, off if it was on. Several
  can be on at once; they are sent as one comma-separated `statuses` value.
- **All** calls `BoardStore.showEveryStatus()`, which clears the statuses and leaves the search field
  alone.

**What happens.** The capsule changes state immediately, because the store's property is set before
anything suspends. Then `load()` runs: the pages held stay on screen (`refreshing` holds them there
on purpose) and a small spinner appears at the trailing end of the bar, so a tap is never answered
with a still picture. When the answer lands the list is replaced from page one, and the paging cursor
with it.

A capsule tapped while its own read is running is inert for the length of that read — `AsyncButton`
disables itself while its action runs. A *different* capsule tapped during that read is not: it sets
the question, and the read already in flight reads again for it when it lands.

### Through the API (`DifferentRequestsClient`)

**Find it.** `requests(statuses:sort:query:cursor:)`.

**Trigger it.** Call it. It needs no session: `ListRequests` declares `APP_KEY` audience, so an app
key alone reads the board.

**What happens.** `sort.urlToken` becomes `?sort=`, the statuses are `compactMap`ped to their tokens
and joined with commas into `?statuses=`, and anything with no token is silently absent from the URL
because there is no spelling to send. `GET /requests` answers with `DRListRequestsResponse`.

### In the Example app

**Find it.** The Requests tab, which is a `NavigationStack` wrapping `DifferentRequestsView`.

**Trigger it.** As on the board above.

**What happens.** As on the board above. The app must be run with `DIFFERENT_REQUESTS_APP_KEY` set
in the scheme, or it never reaches the board at all.

## Expectations

### Positive

| What someone does | What they get |
| --- | --- |
| Opens the board for the first time | **Top** and **All** highlighted, every other capsule plain, and the whole board ranked by votes |
| Taps **New** | The capsule highlights at once, a spinner appears at the end of the bar, the old rows stay up, then the board comes back newest-first from page one |
| Taps **Planned** | **All** stops being highlighted, **Planned** starts, and the board is re-read as `?statuses=planned` |
| Taps **Planned**, then **Shipped** | Both highlighted, one read, sent as `?statuses=planned,shipped` |
| Taps **Shipped**, then **Open** | Sent as `?statuses=open,shipped` — kept in the order the contract declares them, so one set is always one URL |
| Taps **Planned** a second time | It un-highlights, **All** highlights again, and the whole board comes back |
| Taps **All** after searching "dark mode" | Statuses cleared, "dark mode" still in the field and still applied |
| Searches "dark mode" and taps **Shipped** | Both narrowings on one call: `?sort=top&statuses=shipped&query=dark%20mode` |
| Scrolls four pages into a filtered board | Each further page is asked for under the filter the cursor came from, not under whatever the bar says now |
| Filters, opens a request, comes back | The same filter, the same rows, the same place in them. No re-read: the store answers the question the bar is asking |
| Filters to something empty, taps **Show every status** | The whole board, with the search text untouched |
| Taps a second capsule while the first one's read is still running | One further read, not two — the read in flight notices the question moved and reads again for it |
| Pulls to refresh a filtered board | The same filter, re-read from page one |
| A status is added to the contract | It appears on the bar with no change to this package, because the bar is `allCases` filtered by `urlToken` |

### Negative

| What happens | What they see |
| --- | --- |
| The board is narrowed to statuses nothing is in | "Nothing in this filter" / "No request is in the statuses you picked. Others are on the board — show every status to see them." with **Show every status** and **Ask for a feature** |
| A search inside a status filter matches nothing | "No matches in this filter" / "Nothing in the statuses you picked matches that search. Show every status to search the whole board." with the same two buttons |
| A search on an unfiltered board matches nothing | "Nothing matches" / "Nobody has asked for this yet." with **Ask for a feature** |
| The whole board is empty and nothing is narrowing it | "No requests yet" / "Nobody has asked for anything. Be first." with **Ask for a feature** |
| The read a capsule started does not answer | "Couldn't load" / "Something went wrong reaching the server. Check your connection and try again." with **Try Again**. The bar stays above it with the tapped capsule highlighted, so the filter can be changed or undone without a successful read first |
| A further page of a filtered board fails | "Couldn't load any more." with **Try Again** under the last row. The rows already read stay, and so does the filter |
| A vote fails on a filtered board | "Your vote didn't go through. Try it again." — the filter is untouched and the notice sits above the rows |
| The same capsule is tapped twice inside one round trip | The second tap does nothing. No error text: the capsule already shows the state the first tap asked for, and it goes live again the moment the read lands |
| The contract carries a status with no `url_token` | It is never drawn on the bar. There is no capsule, no error, and nothing to tap — it cannot be sent, so it is not offered |
| A host app sets `statuses` to a value with no `url_token` | The client leaves it out of the query string, and the next capsule tapped rebuilds the set from what the contract can spell. Nothing is shown, because nothing the reader did was refused |
| The host app forgets the `NavigationStack` | No title and no search field. The bar itself still draws — it is the view's own content, not a toolbar item |

## The code path

```
Host app  ──►  DifferentRequestsHub.swift
                 board = BoardStore(client:, statuses: [], sort: .top)
                   └── asked = BoardQuestion(statuses: [], sort: .top, query: "")
        │
        ▼
DifferentRequestsView.swift
  body
   └── VStack(spacing: 0)
        ├── BoardFilterBar.swift  ── drawn in ALL FOUR read states, above the content
        │     HStack
        │      ├── ScrollView(.horizontal)
        │      │    ├── sortChips
        │      │    │     ForEach(store.offeredSorts, id: \.self)
        │      │    │       BoardStore.offeredSorts
        │      │    │         = DRRequestSort.allCases.filter { $0.urlToken != nil }
        │      │    │              └── URLTokens.differentrequests_sdk.generated.swift
        │      │    │       FilterChip.swift(label: sort.filterLabel,
        │      │    │                        isActive: store.sort == sort)
        │      │    │         └── AsyncButton.swift ──► BoardStore.show(sort:)
        │      │    ├── Divider
        │      │    └── statusChips
        │      │          FilterChip("All", isActive: store.statuses.isEmpty)
        │      │            └── AsyncButton ──► BoardStore.showEveryStatus()
        │      │          ForEach(store.offeredStatuses, id: \.self)
        │      │            BoardStore.offeredStatuses
        │      │              = DRRequestStatus.allCases.filter { $0.urlToken != nil }
        │      │                   └── URLTokens.differentrequests_domain.generated.swift
        │      │            FilterChip(label: status.badgeLabel,   ── StatusBadge.swift
        │      │                       isActive: store.statuses.contains(status))
        │      │              └── AsyncButton ──► BoardStore.toggle(status:)
        │      └── ProgressView .opacity(store.read.isReading ? 1 : 0)
        │
        └── content  ── switch store.read (ReadState.swift)
              ├── .unread, .reading  ──► ProgressView
              ├── .failed            ──► LoadFailure.swift  ──► store.load()
              ├── .empty             ──► empty
              │      BoardStore.narrowing ──► BoardNarrowing(question: asked)
              │        BoardNarrowing.swift : (query.isEmpty, statuses.isEmpty)
              │            (true , true ) ──► .nothing
              │            (false, true ) ──► .query
              │            (true , false) ──► .statuses
              │            (false, false) ──► .queryAndStatuses
              │        ContentUnavailableView(emptyTitle, emptyIcon, emptyMessage)
              │        if narrowing.isStatusFiltered
              │            AsyncButton "Show every status" ──► store.showEveryStatus()
              │            askButton .bordered
              │        else
              │            askButton .borderedProminent
              └── .loaded, .refreshing ──► list(requests)
                     Section footer ──► store.narrowing.listFooter

BoardStore.swift  ── a capsule tapped
  show(sort:)          sort = …                         ─┐
  toggle(status:)      contains ? removeAll             ─┤
                       : offeredStatuses.filter{…}       ├──► load()
  showEveryStatus()    statuses = []                    ─┘
        │
        ▼
  load()
    if read.isReading { return }        ← the read already running finishes the job
    repeat {
      read = read.whileReading          ReadState.swift  loaded→refreshing · empty→reading
      asked = question                  BoardQuestion.swift(statuses:sort:query:)
      cursor = ""                       ← the old cursor addressed the old question
      page = .more
      await readFirstPage(asked)
          └── fetch(asked, cursor: "")
                └── DifferentRequestsClient.requests(statuses:sort:query:cursor:)
                      sort.urlToken            ──► URLQueryItem("sort", "top"|"new")
                      statuses.compactMap(\.urlToken).joined(separator: ",")
                                               ──► URLQueryItem("statuses", "open,shipped")
                      GET /requests            ServiceEndpoints.generated.swift
                                               audience .appKey — no session needed
          read = ReadState(page: answer.requests)   ──► .empty | .loaded
          page = PageState(nextCursor:)
    } while asked != question           ← a capsule tapped mid-read is read next, not dropped

  loadMore()  ──► fetch(asked, cursor: cursor)
                  asked, not question: the cursor came back from that question, and
                  handing it to another asks the server to continue a list it never started
```

The search field walks the same store through a different door, and the two do not collide:

```
DifferentRequestsView
  .searchable(text: $store.query)     ──► BoardStore.query
  .task(id: store.query) ──► runSearch()
       ├── store.isCurrent  ──► return        (read.hasRead && asked == question)
       ├── query non-empty  ──► Task.sleep(300ms)   ← typing is debounced
       └── store.load()                             ← a capsule tap is not
  .firstRead(store.read)  ──► FirstRead.swift ──► store.load()   once per store
```

## The screens

```
DifferentRequestsView — loaded, nothing narrowing
┌────────────────────────────────────────────────────┐
│  Requests                                   [ ⊕ ]  │
│ ┌────────────────────────────────────────────────┐ │
│ │ 🔍 Search requests                             │ │
│ └────────────────────────────────────────────────┘ │
│ (Top) (New) │ (All) (Open) (Planned) (In Prog… ›   │ ← BoardFilterBar, horizontal scroll
│  ▔▔▔▔▔        ▔▔▔▔▔                                │   filled = active · plain = off
│ ══════════════════════════════════════════════════ │ ← Divider; everything below is `content`
│  ⌃    Dark mode everywhere                         │
│ 128   Please. My eyes.                             │
│       [Planned]  💬 12               3 days ago    │
│ ────────────────────────────────────────────────── │
│  ⌃    Offline drafts                               │
│  74   …                          [Open]  last week │
│ ────────────────────────────────────────────────── │
│              ( spinner )                           │ ← NextPageRow, while page is not .done
│        ┌────────────────────────────┐              │
│        │ ⊕  Ask for a feature       │              │
│        └────────────────────────────┘              │
│   Not on the board? Ask for it.                    │ ← BoardNarrowing.listFooter
└────────────────────────────────────────────────────┘

  in flight (any read: a capsule tap, a search, a pull-to-refresh)
┌────────────────────────────────────────────────────┐
│ (Top) (New) │ (All) (Open) (Planned) (In Prog… ›  ◌ │ ← the spinner is always in the layout,
│  ▔▔▔▔▔               ▔▔▔▔▔▔▔▔▔                     │   only sometimes visible, so the strip
│ ══════════════════════════════════════════════════ │   never changes width
│  ⌃    Dark mode everywhere                         │ ← the rows already read STAY UP through
│ 128   …                                            │   the read; `refreshing` holds them
└────────────────────────────────────────────────────┘

  disabled : the capsule that started the read, for the length of it (AsyncButton's isRunning).
             It has already flipped to its new state, so it is never inert in secret. Every
             OTHER capsule stays live — tapping one sets the question and the read in flight
             picks it up.

  loaded, filtered, nothing in it
┌────────────────────────────────────────────────────┐
│ (Top) (New) │ (All) (Open) (Planned) (Declined) ›  │ ← STILL HERE. This is the whole point of
│  ▔▔▔▔▔                            ▔▔▔▔▔▔▔▔▔▔       │   drawing the bar above the content
│ ══════════════════════════════════════════════════ │
│                                                    │
│                     ⊟                              │ ← line.3.horizontal.decrease.circle
│              Nothing in this filter                │
│    No request is in the statuses you picked.       │
│    Others are on the board — show every status     │
│    to see them.                                    │
│        ┌────────────────────────────┐              │
│        │   Show every status        │              │ ← prominent: the likelier fix
│        └────────────────────────────┘              │
│        ┌────────────────────────────┐              │
│        │ ⊕  Ask for a feature       │              │ ← bordered
│        └────────────────────────────┘              │
└────────────────────────────────────────────────────┘

  read failed, filtered  → the bar, then "Couldn't load" + "Something went wrong reaching the
                           server. Check your connection and try again." + [Try Again].
                           The capsules are live; a filter can be changed without a good read first
  first read in flight   → the bar, then a centred spinner
  loaded, unfiltered,    → the bar, then "No requests yet" + "Nobody has asked for anything.
  board empty              Be first." + [ ⊕ Ask for a feature ] (prominent, and alone)
  searched, no filter,   → the bar, then "Nothing matches" + "Nobody has asked for this yet."
  no matches               + [ ⊕ Ask for a feature ]
  searched inside a      → the bar, then "No matches in this filter" + "Nothing in the statuses
  filter, no matches       you picked matches that search. Show every status to search the whole
                           board." + [Show every status] + [ ⊕ Ask for a feature ]
  loaded, filtered, rows → footer reads "This is one slice of the board. Show every status before
                           asking, or you may be asking twice." — a status filter can hide the
                           very duplicate the composer exists to catch
```

## Platform differences

- **iOS 18+ and macOS 15+.** `Package.swift` declares no other platform, so there is no watchOS,
  tvOS or visionOS behaviour to describe.
- **The bar is the view's own content, not a toolbar item.** It draws identically on both platforms
  and does not compete with `.primaryAction` for toolbar room, which on macOS is a window toolbar
  shared with whatever the host app put there.
- **Horizontal scrolling.** Touch-drag on iOS, trackpad scroll or shift-scroll on macOS.
  `.scrollIndicators(.hidden)` is stated so the strip reads as a row of capsules on both rather than
  growing a bar on one.
- **Colours.** The capsules use `Color.accentColor` and `HierarchicalShapeStyle.quaternary`, both of
  which resolve against the host app's accent and the platform's own materials. No `UIColor` or
  `NSColor` is named, so there is nothing here that compiles on one platform and not the other.
- **The search field beside it.** `.searchable` is a field under the title on iOS and a toolbar
  search field on macOS. Both write the same `BoardStore.query`, and the bar sits under both.

## Tests that walk this

`Tests/DifferentRequestsTests/BoardFilterTests.swift`, all hermetic. The reads go to a base URL
whose scheme `URLSession` cannot open, so every `load()` fails inside `URLSession.data(for:)` without
a lookup and without a connection — which is enough to walk the store's whole state machine, because
what is asserted is what was asked and what the store did with it, not what a server answered.

| Test | The leg it walks |
| --- | --- |
| `theBarOffersExactlyWhatTheContractCanSend` | `offeredSorts` and `offeredStatuses` against `DRRequestSort.allCases` and `DRRequestStatus.allCases` — every value with a `urlToken` is offered, and every offered value has one. Walks the generated tables in both directions rather than checking a list written here |
| `theZeroSentinelIsNeverOffered` | `unspecified` has no `urlToken` in either table, and so is on neither strip. This is the one that keeps a `0` out of a query string |
| `aStatusGoesOnAndComesOffAgain` | `toggle(status:)` both ways, and `All` lighting up again when the last one comes off |
| `statusesAreSpelledInTheOrderTheContractDeclaresThem` | `toggle(status:)` tapped in reverse order still leaves `statuses` in `offeredStatuses` order, so one set is one URL |
| `showEveryStatusLeavesTheSearchAlone` | `showEveryStatus()` clears the statuses and not `query` — two narrowings undone one at a time |
| `showingARankingReplacesTheOneBefore` | `show(sort:)` over every value in `offeredSorts`, so a ranking added to the contract is covered by being declared |
| `everyNarrowingIsCurrentOnlyForItsOwnQuestion` | `isCurrent` against each of the three properties moved on its own — the staleness check that a per-property comparison would have let a fourth property slip past |
| `aQuestionKnowsWhatItIsHoldingBack` | `BoardNarrowing(question:)` over all four combinations of empty/non-empty query and statuses, checked against `BoardNarrowing.allCases` so no case is left unreached |
| `everyNarrowingSaysSomethingDifferent` | Walks `BoardNarrowing.allCases`: every case has a non-empty title, message and footer, and no two cases share any of the three. A blank empty state and a copy-pasted one are the same bug |
| `anEmptyBoardDescribesTheReadThatEmptiedIt` | `narrowing` reads the question the last read was started for, not what the capsules say now — so the sentence under an empty board is about the read that produced it |
| `aFilterChangeAsksAgainRatherThanPagingOn` | `show(sort:)` and `toggle(status:)` read again rather than only setting a property: the board ends up current for the new question, and the rows read under the old one are replaced rather than paged onto |

Not walked here, and why:

- **The URL itself** — `?sort=new&statuses=open,shipped`. Building it is
  `DifferentRequestsClient.requests(statuses:sort:query:cursor:)`, which was already there and
  unchanged; asserting the string needs a stubbed transport, and the client's own query-building is
  covered by the tokens it reads from the generated table.
- **The `while asked != question` re-read** — a question changed *during* a suspended read. Reaching
  it needs a transport that can be held open mid-call, which a required lane cannot have without a
  live network.
- **The SwiftUI legs** — the capsule tap, the horizontal scroll, `AsyncButton`'s disabled window, the
  spinner's opacity. They need a host app; the Example is that host app, and the owner verifies it by
  running it.
