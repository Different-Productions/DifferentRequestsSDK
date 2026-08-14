# When a write fails

## What it is

Every state a screen in this SDK can be in, held as one value per thing that can be happening, and
rendered by a view that has to account for all of it.

The defect it fixes: `writeError` was assigned by `BoardStore`, `InboxStore` and
`RequestDetailStore`, and read by no view in the package. A vote, an un-vote, a follow, an unfollow,
a comment, a notification marked read and everything marked read all landed on a property nobody
rendered. What the person got for tapping was a control that did not move and no reason why.
`SubmitRequestView` was the only write in the SDK that said anything at all when it failed, so the
pattern was understood — it had simply been applied once.

The cause was not forgetfulness. It was that each store described itself with a handful of parallel
flags — `isLoading`, `isLoadingMore`, `hasLoaded`, `hasMore`, `loadError`, `isWriting`,
`writeError` — which between them describe far more combinations than are real, and a view built
from them one clause at a time renders whichever combination its author remembered. The ones that
got dropped were always the same: the surface that read and found nothing, and the write that did
not land.

So the flags are gone, replaced by three values, one per axis that can be true at the same time as
the others:

| Value | Type | Replaces |
| --- | --- | --- |
| `read` | `ReadState<Content>` | `isLoading`, `hasLoaded`, `loadError`, and the emptiness of the collection |
| `page` | `PageState` | `hasMore`, `isLoadingMore`, and the half of `loadError` a paged read set |
| `write` | `WriteState` | `isWriting`, `writeError` / `submitError` |

Three rather than one because all three are true together: a vote is cast on a board that is
already loaded, while its third page is arriving. Folding them into a single value would mean a
failed vote erasing the list it was cast on.

`ReadState` has six cases and four outcomes. `unread` and `reading` draw the same picture; `loaded`
and `refreshing` draw the same picture. They are separate cases because the store needs the
difference and the view does not — a read already running must not be started twice, and a refresh
must not blank the list that is running it, because a pull-to-refresh lives on the list's own task
and a list that disappears takes that task with it.

```swift
enum ReadState<Content> {
  case unread                 // nothing has been asked for
  case reading                // in flight, nothing to show
  case failed(any Error)      // did not answer
  case empty                  // answered, and there is nothing there
  case loaded(Content)        // answered, and here it is
  case refreshing(Content)    // in flight over what is already on screen
}
```

Three things fell out of doing this that were the same defect wearing different clothes:

- **A paged read that failed** set the same `loadError` the first read set, and no paged surface
  renders that error — by the time a second page is asked for there is a list on screen, and a list
  on screen is what those views took as proof that nothing had gone wrong. The reader got a spinner
  under the last row that spun forever. `PageState.failed` is now its own case and `NextPageRow`
  draws it.
- **A request the server says is gone** was rendered as "Couldn't load … Try Again", which is a
  button that will never work. `ReadState.empty` on `RequestDetailStore.read` is now that answer,
  reached through `DifferentRequestsError.isNotFound`.
- **A second tap during a write** was refused by the store — every store takes one write at a time
  — and refused silently. The controls now go inert from `write.isWriting`, and say so, because
  `.buttonStyle(.plain)` draws a disabled button exactly like an enabled one.
- **A tap during a refresh** was refused for the same reason in reverse: `refreshing` and `loaded`
  draw the same screen, so every control on a refreshing surface is there to be tapped. A store
  reading only the settled case would refuse all of them without a word. `ReadState.content` and
  `ReadState.held` both answer from either, and `ReadState.holding(_:)` is how a write's answer
  lands without clearing the mark that says a read is still running.

## Surfaces

Every surface this package ships, and what it now says when something does not work.

| Surface | Says so? |
| --- | --- |
| `DifferentRequestsView` — the board | Yes: read, page and vote failures all land on screen |
| `RequestDetailView` — one request | Yes: the request read, the thread read, the thread's paging, and vote / follow / comment |
| `InboxView` | Yes: read, page, and mark-read / mark-all-read |
| `ChangelogView` | Yes: read and page. Nothing is written from here |
| `RoadmapView` | Yes: read. There is no paging and nothing is written from here |
| `SubmitRequestView` — the composer sheet | Yes, as it already did. It now says it through the same component as everything else |
| `VoteControl` — the component | Yes: takes `isWriting` and goes inert and dim on it |
| `WriteFailureNotice` — the component | This is the thing that says it, on four surfaces |
| `NextPageRow`, `RetryRow`, `LoadFailure` — the components | These are what a failed read says |
| `DifferentRequestsClient` — the API, for host apps building their own UI | Yes: everything throws `DifferentRequestsError`. `isNotFound` and `retryAfterSeconds` are what to branch on |
| `DifferentRequestsHub` — the object the host holds | No UI of its own. `fileRequest()` reads `SubmitStore.submitted` to decide whether the board needs re-reading |
| Example app (`Example/DifferentRequestsExample`) | Yes, through the SDK screens in its tabs |
| Command line | None. This package ships no executable |
| Web / console | None. Not in this repository |
| watchOS, tvOS, visionOS | None. `Package.swift` declares iOS 18 and macOS 15 only |
| Widgets, App Intents, Shortcuts | None |
| Push notification | None. A failed write pushes nothing to anybody |

## How to find it, trigger it, and what happens

### On the board (`DifferentRequestsView`)

**Find it.** The chevron at the left of every row.

**Trigger it.** Tap it with the network down, without a session, or against a server that refuses.
`BoardStore.toggleVote(requestID:)` decides from the row it holds whether this is a vote or an
un-vote, sets `write = .writing(.vote)` or `.writing(.clearVote)`, and calls the client.

**What happens.** While the call runs, every `VoteControl` on the board is `.disabled` and drawn
tertiary — the store takes one vote at a time, and a tap it refuses is a tap that does nothing.
On failure, `write` becomes `.failed(WriteFailure(attempt:error:))` and a line appears in a section
at the top of the list: **"Your vote didn't go through. Try it again."** with **Dismiss** beside it.
The count does not move, because nothing was counted. On success the row is replaced by the request
the write returned, found again by id rather than by an index taken before the call.

**Find it (reading).** The list itself, and the spinner under its last row.

**Trigger it (reading).** Pull to refresh with the network down; or scroll to the end so
`NextPageRow` asks for the next page, with the same network.

**What happens.** A first read that fails replaces the board with "Couldn't load" and a **Try
Again**. A refresh keeps the list up for the whole read — `refreshing(held)` — and replaces it with
the failure only when the answer is a failure. A *page* that fails leaves everything already read
on screen and puts **"Couldn't load any more."** with **Try Again** where the spinner was. It does
not retry itself: a retry that fires itself loops against a server that is down.

### On one request (`RequestDetailView`)

**Find it.** The chevron, the **Follow** / **Following** button, and the composer pinned under the
thread.

**Trigger it.** Any of the three, against a server that refuses.

**What happens.** All three go inert together while any one of them runs, and the notice appears
directly under the vote-and-follow row, which is where whoever tapped is looking:

- vote — **"Your vote didn't go through. Try it again."**
- un-vote — **"Couldn't take your vote back. Try it again."**
- follow — **"Couldn't start following this. Try it again."**
- unfollow — **"Couldn't stop following this. Try it again."**
- comment — **"Your comment didn't post. It's still written — send it again."**, and the draft is
  still in the field, because the sentence says to send it again and there has to be something to
  send

**Find it (reading).** Two reads, not one: the request and the thread.

**Trigger it (reading).** Open a request id the server does not have; or open a real one with the
thread rpc failing.

**What happens.** A request that cannot be reached shows "Couldn't load" with **Try Again**. A
request the server says is *not there* shows **"This request is gone"** / "It was removed, or the
link that got you here is out of date." — and no **Try Again**, because there is nothing on the
other side of it. A thread that fails leaves the request readable above it and puts **"Couldn't
load the discussion."** with **Try Again** under the Discussion heading.

### In the inbox (`InboxView`)

**Find it.** The blue dot at the right of every unread row, and **Read All** in the toolbar.

**Trigger it.** Either, against a server that refuses.

**What happens.** Every dot goes inert and tertiary while any stamp is being written, and the
notice appears in a section at the top of the list: **"Couldn't mark that read. Try it again."**
or **"Couldn't mark everything read. Try it again."** The dot stays blue, because the row is still
unread.

**Reading.** The page and the unread count are one read. A page that arrives beside a count that
did not is an inbox rendering a badge nobody vouches for — and **Read All** appears and disappears
on that badge — so either both answered or the read failed.

### In the composer (`SubmitRequestView`)

**Find it.** **Submit**, in the confirmation slot of the sheet's own toolbar.

**Trigger it.** As before. What changed is only where the state lives: `SubmitStore.submitError`
became `SubmitStore.write`.

**What happens.** As before — **"That didn't send. Try again in a moment."** with everything typed
still in the fields — with a **Dismiss** beside it now, and drawn by the same
`WriteFailureNotice` the other three surfaces use.

### On the roadmap and the changelog (`RoadmapView`, `ChangelogView`)

**Find it.** Pull to refresh, and — on the changelog — the spinner under the last row.

**Trigger it.** Either, against a server that refuses.

**What happens.** The changelog behaves as the board does. The roadmap has one deliberate change of
behaviour: columns held from a previous read used to survive a failed refresh, and a roadmap left
on screen after a refresh that could not reach the server is a roadmap presenting itself as current
when nobody knows whether it is. It now shows "Couldn't load" with **Try Again**.

### Through the API (`DifferentRequestsClient`)

**Find it.** Every call throws `DifferentRequestsError`.

**Trigger it.** Call anything.

**What happens.** Unchanged, plus one addition: `isNotFound` says whether the server's answer was
`DRErrorCode.notFound`, which is the distinction between an outage and an answer. The `message` on
a `DRApiError` is still written for whoever is debugging and may name internals — no copy in this
SDK is derived from it.

## Expectations

### Positive

| What someone does | What they get |
| --- | --- |
| Opens a surface that has never read | A centred spinner, from `ReadState.unread` |
| Opens a surface whose store has already read | What it read, with no second read. `firstRead` keys on `hasRead`, which is true from the first answer onward |
| Pulls to refresh a loaded list | The list stays up for the whole read (`refreshing(held)`) and is replaced by the answer |
| Votes successfully | The row is replaced by the request the write returned; the count is the server's, never one incremented locally |
| Marks one notification read successfully | The row is replaced by the stamped one, and the badge drops by one — the server answered with the stamp, so this is not a guess |
| Marks everything read successfully | The whole inbox and its badge are re-read; nothing marked means nothing changed, so nothing is re-read |
| Posts a comment on a fully-read thread | It joins the end of the thread and the draft clears |
| Posts a comment on a partly-read thread | The draft clears and the comment is not appended; a thread reads oldest first, and appending would put it ahead of comments not yet fetched |
| Reaches the end of a paged list | The spinner stops and nothing is drawn under the last row (`PageState.done`) |
| Opens a request that has been folded into another | The request, plus "Folded into another request — your vote went with it" as a link into the one that now holds the demand |
| Reads a surface that is genuinely empty | Its own empty state, never a spinner and never blank space |

### Negative

| What happens | What they see |
| --- | --- |
| A vote fails, either direction | **"Your vote didn't go through. Try it again."** / **"Couldn't take your vote back. Try it again."** in a section at the top of the board, with **Dismiss**. The count does not move |
| A follow or unfollow fails | **"Couldn't start following this. Try it again."** / **"Couldn't stop following this. Try it again."** under the vote-and-follow row. The bell does not change |
| A comment fails to post | **"Your comment didn't post. It's still written — send it again."** and the draft is still in the field, untouched |
| One notification fails to mark read | **"Couldn't mark that read. Try it again."** at the top of the inbox. The dot stays blue |
| Marking everything read fails | **"Couldn't mark everything read. Try it again."** at the top of the inbox. Nothing is re-read, because nothing was marked |
| Filing a request fails | **"That didn't send. Try again in a moment."** in the composer, with the title and detail exactly as typed. The sheet stays up |
| Any write is attempted with no end-user session | The same sentence for that write. `DifferentRequestsError.notAuthenticated(rpc)` is thrown from the audience the contract declares, before anything reaches the network, and it reaches the developer through `store.write.failure?.error` |
| A second control is tapped while a write is in flight | It does not respond, and it is visibly dim — `disabled(write.isWriting)` plus a stated tertiary tint, because `.buttonStyle(.plain)` draws a disabled button exactly like an enabled one |
| A first read fails | "Couldn't load" / "Something went wrong reaching the server. Check your connection and try again." with **Try Again** |
| A refresh of a loaded list fails | The same screen. The stale list is not left up: on the roadmap that was the old behaviour, and it presented columns as current when nobody knew whether they were |
| A further page fails | **"Couldn't load any more."** with **Try Again**, in place of the spinner. Everything already read stays on screen, and the cursor stays where it was so the retry asks for that page rather than skipping it |
| The thread on a request fails to load | **"Couldn't load the discussion."** with **Try Again** under the Discussion heading. The request above it is still readable |
| A request id the server does not have | **"This request is gone"** / "It was removed, or the link that got you here is out of date." No **Try Again**: there is nothing to try again for |
| A read answers with nothing at all | The surface's own empty state — "No requests yet", "Nothing matches", "Nothing yet", "No roadmap yet", "Nothing published yet", "No comments yet." — never blank space |
| The server's `DRApiError.message` says something specific | Nobody sees it. Every sentence above is written against what the person did; the contract states that message is for whoever is debugging and may name internals |
| A failure notice is dismissed | It goes away. Nothing else changes — the write still did not land, and the control that starts it is on screen either way |

## The code path

```
                     ┌──────────────────────────────────────────────────────┐
                     │  State/  — one value per thing that can be happening  │
                     ├──────────────────────────────────────────────────────┤
  ReadState.swift    │  unread · reading · failed(Error) · empty             │
                     │  loaded(Content) · refreshing(Content)                │
                     │    .hasRead   ← what firstRead keys on                │
                     │    .isReading ← what load() guards on                 │
                     │    .whileReading ← keeps content up during a refresh  │
                     │    .content   ← answers from loaded AND refreshing    │
                     │    .holding(_:) ← a write's answer, without ending a  │
                     │                   read that is still running          │
                     │    init(readFailure:) ← notFound becomes .empty       │
  ReadState+Pages    │    init(page:) · .held · .appending(_:) · .replacing  │
  PageState.swift    │  more · reading · failed(Error) · done                │
  WriteAttempt.swift │  vote · clearVote · follow · unfollow · comment       │
                     │  markRead · markEverythingRead · fileRequest          │
                     │    .failureMessage ← the sentence, per attempt        │
  WriteFailure.swift │  attempt + error, .message = attempt.failureMessage   │
  WriteState.swift   │  idle · writing(WriteAttempt) · failed(WriteFailure)  │
                     │    .isWriting · .failure                              │
                     └──────────────────────────────────────────────────────┘

A WRITE THAT FAILS — the defect, and where it now goes

  VoteControl.swift  ─ AsyncButton ─► BoardStore.toggleVote(requestID:)
   (or the dot in InboxView, Follow in RequestDetailView, Send in CommentComposer,
    Submit in SubmitRequestView)
        │
        ▼
  BoardStore.swift  ── toggleVote(requestID:)
        ├── write.isWriting ──► return          (one write at a time, per surface)
        ├── read.held.first(where: id) ──► nil ──► return   (held answers from
        │                                     loaded AND refreshing, or every tap
        │                                     during a pull-to-refresh is dropped)
        ├── attempt = current.viewer.voted ? .clearVote : .vote
        ├── write = .writing(attempt)  ──────────► every control dims, right now
        │
        ├──► DifferentRequestsClient.vote/clearVote(requestID:)
        │        DifferentRequestsClient.swift ── perform(_:query:body:)
        │          ├── rpc.audience == .endUser && sessionToken == nil
        │          │     └──► throw .notAuthenticated(rpc)     (no round trip)
        │          ├── URLSession failure ──► throw .networkError(underlying:)
        │          ├── non-2xx ──► throw .api(DRApiError)
        │          └── 2xx ──► DRVoteResponse
        │
        ├── success ──► read = read.replacing(written, identifiedBy: { $0.id })
        │                      └── lands through .holding(_:), so a write answering
        │                          mid-refresh does not report the read as finished
        │               write = .idle
        └── failure ──► write = .failed(WriteFailure(attempt:error:))
                             │
                             │   ⟵ this is where it used to stop.
                             │      writeError = error, and nothing read it.
                             ▼
  DifferentRequestsView.swift ── list(_:)
        └── if let failure = store.write.failure
              └──► WriteFailureNotice.swift
                     Text(failure.message)   ← WriteAttempt.failureMessage
                     Button("Dismiss") ──► BoardStore.acknowledgeWriteFailure()
                                              write = .idle

A READ, AND ITS FOUR OUTCOMES

  DifferentRequestsView.body
    .firstRead(store.read) ──► FirstRead.swift
                                 task(id: state.hasRead) { hasRead ? return : read() }
                                    │        ▲
                                    │        └── false only until the FIRST answer, so the
                                    │            task's own progress cannot cancel it
                                    ▼
  BoardStore.load()
    ├── read.isReading ──► return
    ├── repeat {
    │     read = read.whileReading      unread/failed/empty ──► .reading
    │                                   loaded(h)/refreshing(h) ──► .refreshing(h)
    │     loadedQuery = query; cursor = ""; page = .more
    │     readFirstPage()
    │       ├── client.requests(statuses:sort:query:cursor:)
    │       ├── success ──► read = ReadState(page: answer.requests)
    │       │                       empty? ──► .empty
    │       │                       else   ──► .loaded(requests)
    │       │               page = PageState(nextCursor:)  ""? .done : .more
    │       └── failure ──► read = ReadState(readFailure: error)
    │                               isNotFound? ──► .empty
    │                               else       ──► .failed(error)
    │                       page = .done
    │   } while loadedQuery != query          (a search typed mid-read is not dropped)
    ▼
  DifferentRequestsView.content
    switch store.read {
      case .unread, .reading            ──► ProgressView()
      case .failed                      ──► LoadFailure.swift  "Couldn't load" + Try Again
      case .empty                       ──► ContentUnavailableView + Ask for a feature
      case .loaded(let r), .refreshing(let r) ──► list(r)
    }                                        no default:, so a sixth case would not compile

A PAGE, WHICH USED TO SPIN FOREVER

  DifferentRequestsView.list(_:)
    └── if store.page.isDone == false ──► NextPageRow.swift
                                            switch state {
                                              .more    ──► spinner.task { more() }
                                              .reading ──► spinner
                                              .failed  ──► RetryRow.swift
                                                             "Couldn't load any more."
                                                             + Try Again  (tapped, never auto)
                                              .done    ──► EmptyView()
                                            }
                                              │
                                              ▼
  BoardStore.loadMore()
    ├── page.isReading || page.isDone ──► return
    ├── read.isReading ──► return
    ├── page = .reading
    ├── success ──► read = read.appending(answer.requests); page = PageState(nextCursor:)
    └── failure ──► page = .failed(error)      read untouched — the list stays up
                       │
                       └── the cursor is NOT advanced, so Try Again asks for this page

ONE REQUEST — two reads, because they are two rpcs that fail apart

  RequestDetailStore.load()
    ├── read.isReading || thread.isReading ──► return
    ├── read = read.whileReading
    ├── client.request(id:)
    │     ├── success ──► read = .loaded(answer.request)
    │     └── failure ──► read = ReadState(readFailure: error)
    │                         .api(code: .notFound) ──► .empty   "This request is gone"
    │                         anything else         ──► .failed  "Couldn't load"
    │                     thread = .unread; page = .done; return
    ├── thread = thread.whileReading; cursor = ""; page = .more
    └── client.comments(requestID:cursor:)
          ├── success ──► thread = ReadState(page: answer.comments)
          └── failure ──► thread = ReadState(readFailure: error)
                              │
  RequestDetailView.thread ◄──┘
    switch store.thread {
      .unread, .reading ──► spinner
      .failed           ──► RetryRow "Couldn't load the discussion." + Try Again
      .empty            ──► "No comments yet."
      .loaded(c), .refreshing(c) ──► ForEach(c) + NextPageRow
    }
```

## The screens

```
DifferentRequestsView — a vote that did not land
┌──────────────────────────────────────────────┐
│  Requests                             [ ⊕ ]  │
│ ┌──────────────────────────────────────────┐ │
│ │ 🔍 Search requests                       │ │
│ └──────────────────────────────────────────┘ │
│ ┌──────────────────────────────────────────┐ │
│ │ ⚠  Your vote didn't go through.  Dismiss │ │ ← WriteFailureNotice, first section.
│ │    Try it again.                         │ │   Dismiss ⇒ write = .idle
│ └──────────────────────────────────────────┘ │
│  ⌃    Dark mode everywhere                   │ ← count unmoved: nothing was counted
│ 128   Please. My eyes.                       │
│       [Planned]  💬 12          3 days ago   │
│ ─────────────────────────────────────────── │
│  ⌃    Offline drafts                         │
│  74   …                                      │
└──────────────────────────────────────────────┘

  in flight (write = .writing) : EVERY ⌃ on the board is .disabled and drawn .tertiary.
                                 One vote at a time is the store's rule; a tap it refuses
                                 in silence is the same defect in miniature.
  idle, voted                  : ⌃ filled, accent colour, "Remove your vote"
  idle, not voted              : ⌃ outline, secondary,   "Vote for this"

  first read in flight   → centred spinner; nav bar and [ ⊕ ] still there
  refresh in flight      → the list, unchanged, with the system refresh control
  read failed            → "Couldn't load" / "Something went wrong reaching the server.
                            Check your connection and try again." + [Try Again]
  read empty             → "No requests yet" / "Nobody has asked for anything. Be first."
  searched, no matches   → "Nothing matches" / "Nobody has asked for this yet."
                           (neither empty state has pull-to-refresh: there is no List
                            under it to pull. The nav-bar [ ⊕ ] is still reachable.)

  end of the list, by PageState:
     .more    ─►  ( spinner )        — and it asks, on appear
     .reading ─►  ( spinner )        — it is asking
     .failed  ─►  Couldn't load any more.
                  [Try Again]        — it stopped, and it waits to be told
     .done    ─►  nothing at all

RequestDetailView — a follow that did not land
┌──────────────────────────────────────────────┐
│ ‹ Back                Request                │
│                                              │
│  Dark mode everywhere                        │
│  [Planned]  Ada Lovelace        3 days ago   │
│  Please. My eyes.                            │
│                                              │
│   ⌃    ┌───────────────┐                     │
│  128   │ 🔔  Follow    │                     │ ← .disabled(write.isWriting)
│        └───────────────┘                     │
│  ⚠  Couldn't start following this.  Dismiss  │ ← under the controls, where the eye is
│     Try it again.                            │
│                                              │
│  DISCUSSION                                  │
│  Ada Lovelace · 2 days ago                   │
│  Agreed.                                     │
│ ─────────────────────────────────────────── │
│ ┌──────────────────────────────────────────┐ │
│ │ Add a comment                        ⬆   │ │ ← ⬆ hidden and replaced by a spinner
│ └──────────────────────────────────────────┘ │   while write.isWriting; disabled when
└──────────────────────────────────────────────┘   the draft trims to nothing

  request read failed    → "Couldn't load" + [Try Again]        (whole screen)
  request read empty     → "This request is gone" / "It was removed, or the link that
                            got you here is out of date."       (whole screen, NO retry)
  thread failed          → request still readable; under DISCUSSION:
                              Couldn't load the discussion.
                              [Try Again]
  thread empty           → "No comments yet."
  comment failed         → "Your comment didn't post. It's still written — send it
                            again." and the draft still in the field

InboxView — a stamp that did not land
┌──────────────────────────────────────────────┐
│  Inbox                            Read All   │ ← shown only while unreadCount > 0,
│ ┌──────────────────────────────────────────┐ │   .disabled(write.isWriting)
│ │ ⚠  Couldn't mark that read.      Dismiss │ │
│ │    Try it again.                         │ │
│ └──────────────────────────────────────────┘ │
│  Now Planned                             ●   │ ← still blue: the row is still unread.
│  Dark mode everywhere                        │   .disabled + .tertiary while writing
│  2 hours ago                                 │
└──────────────────────────────────────────────┘

  read failed  → "Couldn't load" + [Try Again]   (the page and the unread count are one
                  read: a badge nobody vouches for is what Read All appears on)
  read empty   → "Nothing yet" / "Vote for a request or follow one, and you'll hear
                  when it moves."

SubmitRequestView — unchanged in copy, moved to the shared component
┌──────────────────────────────────────────────┐
│ Cancel      Ask for a feature        Submit  │ ← greyed while the title is blank, and
│  WHAT DO YOU WANT?                           │   again while the write is in flight
│ ┌──────────────────────────────────────────┐ │
│ │ dark mode                                │ │ ← still exactly as typed
│ └──────────────────────────────────────────┘ │
│  ⚠  That didn't send.            Dismiss     │
│     Try again in a moment.                   │
└──────────────────────────────────────────────┘

RoadmapView / ChangelogView
  reading  → centred spinner
  failed   → "Couldn't load" + [Try Again]     (roadmap: stale columns are no longer
              left up behind a failed refresh)
  empty    → "No roadmap yet" / "Nothing has been planned publicly."
             "Nothing published yet" / "Release notes will appear here."
  loaded   → sections / rows, changelog with a NextPageRow under the last one
```

## Platform differences

- **iOS 18+ and macOS 15+.** `Package.swift` declares no other platform, so there is no watchOS,
  tvOS or visionOS behaviour to describe.
- **The copy says "try it again", never "tap".** The same sentence has to read correctly under a
  finger and under a cursor, and it is the same string on both platforms.
- **Disabled buttons.** `VoteControl` and the inbox dot both use `.buttonStyle(.plain)`, which
  renders its own label and therefore draws a disabled button identically to an enabled one on both
  platforms. Neither relies on the system dim: each states a `.tertiary` tint of its own while
  `isWriting`. `Follow`, `Read All` and `Submit` use bordered styles and do get the system's
  disabled treatment, which differs in shade between iOS and macOS but is present on both.
- **Pull to refresh.** `.refreshable` is a pull gesture on iOS and a menu command plus a scroll
  gesture on macOS. Both call the same `load()`, and both are why a refresh keeps the list up: the
  task belongs to the list.
- **`ContentUnavailableView`.** Centres in the available space on both, which is the whole screen
  for a failed or empty surface here.
- **`ToolbarItem(placement: .primaryAction)`** — trailing edge of the navigation bar on iOS, window
  toolbar on macOS. `Read All` is there on both.
- **The stack around it all.** The host app owns it on every platform. The SDK ships no
  `NavigationStack` of its own except inside the composer sheet.

## Tests that walk this

All hermetic. Two ways of reaching a real failure without a network:

1. **The audience gate.** An rpc the contract marks `END_USER` is refused by
   `DifferentRequestsClient.perform` before anything is sent when no session exists. That is every
   write in this SDK, so every write's failure path is walked exactly as a host app that forgot
   `createSession` would walk it.
2. **A scheme `URLSession` will not open.** A client built against a base URL with an unusable
   scheme fails inside `URLSession.data(for:)` without a lookup or a connection, which is how the
   `APP_KEY` reads are reached.

| Test file / test | The leg it walks |
| --- | --- |
| `ReadStateTests.theFourOutcomesAreFourDifferentStates` | `unread`/`reading` vs `empty` vs `loaded` vs `failed` — that a read which found nothing is not the same value as one still running |
| `ReadStateTests.hasReadIsFalseOnlyUntilTheFirstAnswer` | `hasRead` across every case: what `firstRead` keys its task on, and why a read in flight cannot cancel itself |
| `ReadStateTests.aRefreshKeepsWhatIsAlreadyHeld` | `whileReading` from each case: `loaded(h)`/`refreshing(h)` → `refreshing(h)`, everything else → `reading` |
| `ReadStateTests.anEmptyPageIsEmptyAndAPageIsLoaded` | `init(page:)` — the one place the empty/loaded distinction is drawn |
| `ReadStateTests.appendingCarriesWhatWasAlreadyHeld` | `appending(_:)` from every case, and `held` under each |
| `ReadStateTests.contentAnswersFromBothStatesThatHoldSomething` | `content` from `loaded` and from `refreshing`, and nil from the four that hold nothing — a store reading only the settled case refuses every write made during a refresh, silently |
| `ReadStateTests.aWriteAnsweringDuringARefreshDoesNotEndTheRefresh` | `holding(_:)` from every case: a write's answer stays inside a running read rather than reporting it finished |
| `ReadStateTests.aServerSayingItIsGoneIsNotAFailure` | `init(readFailure:)` — `DRErrorCode.notFound` becomes `.empty`, a plan refusal and an unreachable server become `.failed` |
| `ReadStateTests.everyOtherCodeIsAFailure` | The same init walked across `DRErrorCode.allCases`, so a code added to the contract is covered by being declared rather than by anyone remembering it |
| `ReadStateTests.replacingFindsTheRowByIdAndLeavesAGoneRowGone` | `replacing(_:identifiedBy:)`, the path a write's answer takes back into a list |
| `PageStateTests.theServerLeavesTheCursorEmptyOnTheLastPage` | `init(nextCursor:)` → `.done` / `.more` |
| `PageStateTests.aFailedPageIsNeitherDoneNorReading` | `isDone`, `isReading` and `failure` across every case — what `NextPageRow` and `loadMore()` branch on |
| `WriteStateTests.everyWriteHasSomethingToSay` | Walks `WriteAttempt.allCases`: each has a non-empty `failureMessage`, and no two share one |
| `WriteStateTests.aFailureIsReadableAndAWriteInFlightIsNot` | `isWriting` and `failure` across every `WriteState` case |
| `WriteStateTests.theSentenceIsNeverTheServers` | `WriteFailure.message` is `attempt.failureMessage` and carries nothing from a `DRApiError` that names a shard and a connection pool. The error is still on the failure, for whoever is debugging |
| `WriteStateTests.aVoteAndAnUnvoteAreDifferentWrites` | The three pairs that are one control in two directions say different things when they fail |
| `SilentWriteTests.aBoardVoteThatFailsSaysSo` | `BoardStore.toggleVote` → `.notAuthenticated(.vote)` → `write.failure`, attempt `.vote`, and the row unchanged |
| `SilentWriteTests.aBoardUnvoteThatFailsSaysWhichDirectionItWas` | The same with `viewer.voted` set: attempt `.clearVote` |
| `SilentWriteTests.aVoteOnOneRequestThatFailsSaysSo` | `RequestDetailStore.toggleVote` → `write.failure`, attempt `.vote`, `read` still `.loaded` |
| `SilentWriteTests.aFollowThatFailsSaysSo` | `RequestDetailStore.toggleFollow` → attempt `.follow`; and `.unfollow` from a followed request |
| `SilentWriteTests.aCommentThatFailsKeepsWhatWasWritten` | `RequestDetailStore.postComment` → attempt `.comment`, and `draft` untouched |
| `SilentWriteTests.markingOneReadThatFailsSaysSo` | `InboxStore.markRead` → attempt `.markRead`, the row unchanged and `unreadCount` unmoved |
| `SilentWriteTests.markingEverythingReadThatFailsSaysSo` | `InboxStore.markAllRead` → attempt `.markEverythingRead` |
| `SilentWriteTests.filingThatFailsKeepsTheComposer` | `SubmitStore.submit` → attempt `.fileRequest`, `submitted` still nil, title and body untouched |
| `SilentWriteTests.everyWritingStoreCanBeToldTheNoticeWasSeen` | `acknowledgeWriteFailure()` on all four writing stores returns `write` to `.idle` |
| `SilentWriteTests.oneWriteAtATimeIsNotASecondFailure` | A write already in flight leaves `write` on `.writing` rather than replacing it with a failure nobody caused |
| `SilentWriteTests.aWriteDuringARefreshIsStillAttempted` | A vote on the board, a vote on one request and a stamp in the inbox, each made while its surface is `refreshing`: attempted and reported, not dropped |
| `SilentWriteTests.aVoteForARowTheBoardDoesNotHoldDoesNothing` | A reload between the tap and the store reading it leaves nothing to toggle, which is not a failure and says nothing |
| `StoreReadTests.aFirstReadThatFailsLandsOnTheState` | `BoardStore` / `RoadmapStore` / `ChangelogStore` / `InboxStore` / `RequestDetailStore` `load()` against an unusable scheme: `read` is `.failed`, `hasRead` is true so `firstRead` does not loop |
| `StoreReadTests.aPageThatFailsDoesNotTakeTheListWithIt` | `loadMore()` on a seeded, loaded store: `page` is `.failed`, `read` is still `.loaded` with every row on it — the defect that made the spinner spin forever |
| `StoreReadTests.aReadAlreadyRunningIsNotStartedTwice` | `load()` while `read.isReading` returns without touching anything |
| `StoreReadTests.theInboxReadsItsBadgeWithItsPage` | A failed inbox read leaves `unreadCount` where it was rather than publishing a page beside a count nobody answered for |
| `StoreReadTests.aThreadThatFailsLeavesTheRequestReadable` | A thread page that fails lands on `page` and leaves `RequestDetailStore.read` loaded — the two rpcs fail apart, and so do the two states |

Not walked here, and why:

- **Anything that needs a 2xx protobuf answer** — a successful vote replacing a row, the badge
  dropping by one, a page appending. Those need a server or a stubbed transport; what they depend
  on (`ReadState.replacing`, `appending`, `init(page:)`) is walked directly as values instead.
- **The SwiftUI legs** — that `WriteFailureNotice` is on screen, that a disabled `VoteControl` is
  visibly dim, that `NextPageRow` stops asking. They need a host app; the Example is that host app,
  and the owner verifies it by running it.
