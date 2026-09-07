# What a plan includes

## What it is

The SDK asks the server which surfaces this app has, and draws only those.

The defect it fixes: this package never called its own `config()`. `DifferentRequestsClient.config()`
existed, was documented as "fetch once per launch", and had exactly one caller in this
repository — the Example app, which used it to decide which tabs to build. No screen in the SDK
asked. So `RoadmapView` and `ChangelogView` rendered themselves for any app that reached them, read
their rpc, and got `planRequired` back. `GetRoadmap` and `ListChangelog` are the only two rpcs the
server refuses on plan, and both of them are behind those two screens.

Which two is not a fact this SDK holds. Each declares `(plan_gate)` in the contract, so
`DRRequestsServiceRPC.planGate` names the surface an app's plan has to include, and an rpc gated
later arrives here already saying so.

What made that worse than an ordinary failure is who the refusal is written for. The contract is
explicit: the `planRequired` reason is "distinct from PermissionDenied because the remedy is a
purchase, not a different account, and only the host developer can act on it — never surfaced to an
end user." The person looking at the screen did not choose the plan and cannot change it. Everything
this SDK can honestly say to them is a sentence about what is there instead, and it can only say it
if it knows before it draws.

The composer under a request is the same question with a different answer. `AppConfig.commentsEnabled`
says whether an app takes comments, and `RequestDetailView` rendered `CommentComposer` without
consulting it. **This half is a contract inconsistency rather than an outage anyone is hitting**: the
server's `SurfaceRepository` hardcodes `comments_enabled = true` and `CreateComment` is not gated, so
today every app reports comments on and every comment posts. The flag is the developer's to turn off and
the schema says so; a client that renders a composer without reading it is a client that will be
wrong the day it is turned off, not one that is wrong now. It is handled here because it is the same
sentence in the same place, not because anyone is stuck.

Three things carry it:

| Value | Where | What it answers |
| --- | --- | --- |
| `PlanSurface` | `State/PlanSurface.swift` | Which surface the contract names, and what is said in its place |
| `PlanState` | `State/PlanState.swift` | How far the asking got: `unread`, `reading`, `failed`, `excluded`, `included` |
| `configuration` | `DifferentRequestsClient.swift` | The answer, kept, so that three screens asking cost one round trip |

`PlanState` is held beside `ReadState` rather than folded into it. They are two questions asked in
order — whether there is anything here, and then what it says — and only the second has content to
hold. Folding them would also mean a sixth `ReadState` case that every surface in the package would
have to enumerate, including the four that are not gated at all.

The cache is a plain remembered answer on the actor, and only a successful read lands in it. A read
that threw leaves it empty so the next ask reaches the server: a config read fails for the same
reasons any read does, and a plan remembered as unreadable would keep a paid app's surfaces shut
for the rest of the launch over one dropped connection. Two asks made before the first has answered
both read, which costs one extra GET of a route with no side effects.

## Surfaces

Every surface this package ships, and what plan gating does to it.

| Surface | Gated? |
| --- | --- |
| `RoadmapView` | Yes. `GetRoadmap` is one of the two plan-refused rpcs. Nothing is read until the app says it has a roadmap |
| `ChangelogView` | Yes. `ListChangelog` is the other one |
| `RequestDetailView` — the composer strip only | Yes, on `AppConfig.commentsEnabled`. The request, its thread, its vote and its follow are not gated and render as before |
| `DifferentRequestsView` — the board | No. `ListRequests` is on every plan. Untouched by this change |
| `SubmitRequestView` — the composer sheet | No. `CreateRequest` is on every plan |
| `InboxView` | No. Notifications are on every plan |
| `AbsentSurface` — the component | This is the thing that says it, on the two Pro screens |
| `CommentComposer` — the component | Unchanged. It is now rendered only when the app takes comments |
| `DifferentRequestsClient` — the API, for host apps building their own UI | `config()` is unchanged in shape and now answers a second ask from the first read. `DRAppConfig` is what a host app branches on |
| `DifferentRequestsHub` — the object the host holds | No UI of its own. Builds the stores that hold the plan state |
| Example app (`Example/DifferentRequestsExample`) | Already gated, and left as it is: it reads `DRAppConfig` in `RootView` and does not build a tab for a surface the app lacks. An absent tab is better than a tab that explains itself, and the SDK's own screens are the backstop for a host that shows them anyway — from a deep link, a settings row, or a tab bar built before the config arrives |
| Command line | None. This package ships no executable |
| Web / console | None. Not in this repository |
| watchOS, tvOS, visionOS | None. `Package.swift` declares iOS 18 and macOS 15 only |
| Widgets, App Intents, Shortcuts | None |
| Push notification | None. A plan does not push anything to anybody |

## How to find it, trigger it, and what happens

### The roadmap (`RoadmapView`)

**Find it.** Wherever the host app puts it. In the Example it is a tab, built only when the config
says the app has one; reach it in a Free app by building the view directly.

**Trigger it.** Open the screen with an app key belonging to an app whose plan does not include
the roadmap.

**What happens.** `.firstRead(store.read)` runs `RoadmapStore.load()`, which asks
`DifferentRequestsClient.config()` before it asks for anything else. `PlanState(surface: .roadmap,
response:)` reads `AppConfig.roadmapEnabled`. On `false` the store stops there — `GetRoadmap` is
never called — and the screen draws **"This app has no roadmap"** / "It doesn't publish one. What
people have asked for is on the board." There is no **Try Again** on it, because there is nothing to
try: the read behind it has one possible answer and it is one nobody may be shown.

On `true` the store reads the roadmap and the screen behaves exactly as it did before this change.

### The changelog (`ChangelogView`)

**Find it.** As above.

**Trigger it.** The same, against `AppConfig.changelogEnabled`.

**What happens.** The same shape, with its own words: **"This app has no release notes"** / "It
doesn't publish them. What people have asked for is on the board." `ListChangelog` is never called,
so neither is its paging.

### The composer under a request (`RequestDetailView`)

**Find it.** The field pinned under the thread, below the divider.

**Trigger it.** Open any request in an app whose `AppConfig.commentsEnabled` is `false`. No app
reports that today — the server hardcodes it to `true` — so reaching this on a live server means the
developer setting behind the flag has started being honoured.

**What happens.** `RequestDetailStore.load()` reads the request, then the thread, then asks the
config. The composer's slot draws one of four things, and the request and its thread are readable
above it in all four. Where the field would be: **"Comments are off"** / "This app doesn't take
them. Voting is how you say you want this." The vote control is on the same screen, which is what
that sentence points at.

### Through the API (`DifferentRequestsClient`)

**Find it.** `config()`.

**Trigger it.** Call it more than once.

**What happens.** The first call reads. Every call after it returns that answer without a round
trip, for the life of the client. The contract states config is fetched once per launch, so an app
upgraded mid-session is seen on the next one — that is the contract's decision and this matches
it rather than approximating it. A call that throws is not remembered, so the next call reads again.

## Expectations

### Positive

| What someone does | What they get |
| --- | --- |
| Opens the roadmap in an app that has one | The roadmap, exactly as before: spinner, then columns, or its own empty state |
| Opens the changelog in an app that publishes release notes | The changelog, exactly as before, paging included |
| Opens a request in an app that takes comments | The composer, exactly as before |
| Opens the roadmap and then the changelog | One `GET /config` between them. The second is answered from the first |
| Opens ten requests | No further config reads. The composer's question was answered by whichever screen asked first |
| Is a host app calling `config()` itself | The same answer the screens use, from the same read. The Example's `Session.start()` and the SDK's own stores share one |
| Upgrades the app to Pro and relaunches | The surfaces are there. `AppConfig` is read fresh on a new client |
| Opens a request whose app takes comments, while the config read is still in flight | The request and its thread, with a spinner in the composer's strip — never an enabled field that turns out not to be one |

### Negative

| What happens | What they see |
| --- | --- |
| The app's plan does not include the roadmap | **"This app has no roadmap"** / "It doesn't publish one. What people have asked for is on the board." No **Try Again**, and no request is sent |
| The app's plan does not include the changelog | **"This app has no release notes"** / "It doesn't publish them. What people have asked for is on the board." No **Try Again**, and no request is sent |
| The app does not take comments | **"Comments are off"** / "This app doesn't take them. Voting is how you say you want this." — in the strip the field would have occupied. The thread above it is still readable, and voting still works |
| The config read fails on the roadmap or the changelog | **"Couldn't load"** / "Something went wrong reaching the server. Check your connection and try again." with **Try Again**, which asks for the config again. The surface itself is not read, because whether it exists is not known |
| The config read fails on a request's composer | **"Couldn't tell whether this app takes comments."** with **Try Again**, in the composer's strip. The request and the thread above it are unaffected — they were read by a different rpc that answered |
| The config read answers with no `AppConfig` in it | The same "Couldn't load" screen, from `DifferentRequestsError.incompleteResponse(.getConfig)`. Not treated as an answer: every flag on an absent message reads as `false`, and a server that said nothing would otherwise be read as an app nobody paid for |
| The server returns `planRequired` anyway — a plan that lapsed between the config read and the surface read | **"Couldn't load"** with **Try Again**, from `ReadState(readFailure:)`. The gate is a way to not ask; it is not a promise that an answer cannot change underneath it |
| The `DRApiError.message` on a plan refusal says something specific | Nobody sees it. The contract states that message is written for whoever is debugging and may name internals, and `planRequired` in particular is never surfaced to an end user |
| A reader is shown any of the absent screens | Nothing about a plan, a tier, a price or an upgrade. They did not choose it and cannot change it |
| The config read fails and the screen is opened again | It asks again. `PlanState.needsReading` is true after a failure, so one outage does not close a surface for the rest of the launch |
| A surface that is settled — included or excluded — is opened again | It does not ask again. `needsReading` is false, so an excluded screen costs nothing on every appearance |

## The code path

```
                  ┌────────────────────────────────────────────────────────────┐
                  │  State/  — the two values this feature is made of           │
                  ├────────────────────────────────────────────────────────────┤
 PlanSurface.swift│  roadmap · changelog · comments        (CaseIterable)       │
                  │    .theSurfaceTheContractNames ──► DRPlanSurface            │
                  │       ↑ the contract's own DRAppConfig.includes(_:) reads   │
                  │         the flag. Both sides read the same one.             │
                  │    .absentTitle · .absentDescription · .absentSymbol        │
                  │       ↑ copy about what IS there. Never about a plan.       │
 PlanState.swift  │  unread · reading · failed(Error) · excluded · included     │
                  │    init(surface:response:)  hasConfig == false ──► .failed  │
                  │    .needsReading ← unread or failed, never after an answer  │
                  │    .isIncluded   ← what a store checks before reading       │
                  │    .failure      ← for whoever is debugging                 │
                  └────────────────────────────────────────────────────────────┘

ONE READ, SHARED — the cache that makes asking cheap enough to do everywhere

  DifferentRequestsClient.swift ── config()
        ├── if let configuration ──► return it            (no round trip, ever again)
        ├── get(.getConfig, query: [])
        │     └── perform(_:query:body:)
        │           ├── audience is APP_KEY ──► no session needed, so this works
        │           │                           before anyone has signed in
        │           ├── non-2xx ──► throw .api(DRApiError)
        │           └── 2xx ──► DRGetConfigResponse
        ├── success ──► configuration = answer            (kept for this client's life)
        └── failure ──► nothing is kept, and the error is thrown
                        └── so the next ask reads again rather than inheriting
                            an outage that has since ended

A PRO SURFACE — the defect, and where it now stops

  RoadmapView.body
    .firstRead(store.read) ──► FirstRead.swift  task(id: state.hasRead)
        │
        ▼
  RoadmapStore.load()
    ├── read.isReading ──► return
    ├── readPlan()
    │     ├── plan.needsReading == false ──► return   (settled once, asked once)
    │     ├── plan = .reading
    │     ├── client.config()
    │     │     ├── success ──► plan = PlanState(surface: .roadmap, response:)
    │     │     │                        hasConfig == false ──► .failed
    │     │     │                        roadmapEnabled     ──► .included
    │     │     │                        else               ──► .excluded
    │     │     └── failure ──► plan = .failed(error)
    │     ▼
    ├── plan.isIncluded == false ──►  ✗ STOP. client.roadmap() is NOT called.
    │                                   ⟵ this is the whole fix. The call that
    │                                      returned planRequired is not made.
    └── readColumns()
          ├── read = read.whileReading
          ├── client.roadmap()  ── GET /roadmap
          ├── success ──► read = ReadState(page: answer.columns)
          └── failure ──► read = ReadState(readFailure: error)
                                  isNotFound? ──► .empty   else ──► .failed
        │
        ▼
  RoadmapView.content
    switch store.plan {
      case .unread, .reading ──► ProgressView()
      case .failed           ──► LoadFailure.swift   "Couldn't load" + Try Again
      case .excluded         ──► AbsentSurface.swift  surface: .roadmap
      case .included         ──► columns
    }                             no default:, so a sixth case would not compile
                                        │
  RoadmapView.columns ◄─────────────────┘
    switch store.read {
      case .unread, .reading ──► ProgressView()
      case .failed           ──► LoadFailure "Couldn't load" + Try Again
      case .empty            ──► "No roadmap yet" / "Nothing has been planned publicly."
      case .loaded(h), .refreshing(h) ──► list(h)
    }

  ChangelogStore / ChangelogView are the same path, on .changelog and
  client.changelog(cursor:). Its paging lives entirely inside the .included branch,
  so a surface the app does not have has no page to ask for either.

THE COMPOSER — the contract inconsistency, handled in the same shape

  RequestDetailStore.load()
    ├── client.request(id:) ──► read = .loaded(request)
    │     └── failure ──► read = ReadState(readFailure:); thread = .unread; RETURN
    │                     ⟵ commenting is left .unread: nothing to comment on
    ├── client.comments(requestID:cursor:) ──► thread, page
    └── loadCommenting()                        ⟵ last, and usually free: the client
          ├── commenting.needsReading == false ──► return       answers from the read
          ├── commenting = .reading                             a Pro screen made
          ├── client.config()
          │     └── commenting = PlanState(surface: .comments, response:)
          │                               commentsEnabled ──► .included
          └── failure ──► commenting = .failed(error)
        │
        ▼
  RequestDetailView.loaded(_:)
    VStack { List { header · thread } ; Divider() ; composer }
                                                     │
  RequestDetailView.composer ◄────────────────────────┘
    switch store.commenting {
      case .unread, .reading ──► ProgressView() in the strip
      case .failed           ──► RetryRow.swift "Couldn't tell whether this app takes
                                    comments." + Try Again ──► store.loadCommenting()
                                    ⟵ re-asks the config only. The request and the
                                       thread on screen are not read again
      case .excluded         ──► commentsOff — the same words AbsentSurface gives a
                                    whole screen, in the strip
      case .included         ──► CommentComposer.swift  (unchanged)
                                    └── AsyncButton ──► store.postComment()
    }
```

## The screens

```
RoadmapView — an app whose plan does not include one
┌──────────────────────────────────────────────┐
│                Roadmap                       │ ← the title is still the screen's:
│                                              │   the host put this here, and a blank
│                                              │   bar would read as a broken push
│                   🗺                          │
│           This app has no roadmap            │ ← PlanSurface.roadmap.absentTitle
│                                              │
│      It doesn't publish one. What people     │ ← .absentDescription
│        have asked for is on the board.       │
│                                              │
│                                              │ ← no Try Again, no spinner, nothing
│                                              │   to tap. Nothing is being waited for
└──────────────────────────────────────────────┘

  plan .unread / .reading  → centred spinner. Identical to a roadmap being read,
                             deliberately: at that moment they are the same fact
  plan .failed             → "Couldn't load" / "Something went wrong reaching the
                             server. Check your connection and try again." + [Try Again]
                             ⟵ [Try Again] re-asks the CONFIG, then the roadmap
  plan .included           → the four ReadState outcomes, unchanged:
                             spinner · "Couldn't load" + [Try Again] ·
                             "No roadmap yet" / "Nothing has been planned publicly." ·
                             the columns

ChangelogView — the same screen, its own words
┌──────────────────────────────────────────────┐
│               What's New                     │
│                   ✨                          │
│        This app has no release notes         │
│                                              │
│      It doesn't publish them. What people    │
│        have asked for is on the board.       │
└──────────────────────────────────────────────┘

RequestDetailView — an app that does not take comments
┌──────────────────────────────────────────────┐
│ ‹ Back                Request                │
│                                              │
│  Dark mode everywhere                        │
│  [Planned]  Ada Lovelace        3 days ago   │
│  Please. My eyes.                            │
│                                              │
│   ⌃    ┌───────────────┐                     │ ← both still live. Neither is gated,
│  128   │ 🔔  Follow    │                     │   and the strip below points at the ⌃
│        └───────────────┘                     │
│                                              │
│  DISCUSSION                                  │ ← the thread is not gated either:
│  Ada Lovelace · 2 days ago                   │   comments already posted are still
│  Agreed.                                     │   worth reading
│ ─────────────────────────────────────────── │
│  💬 Comments are off                         │ ← where the field was
│  This app doesn't take them. Voting is how   │
│  you say you want this.                      │
└──────────────────────────────────────────────┘

  commenting .unread / .reading → a centred spinner in the strip, same height.
                                  The field is not drawn first and withdrawn:
                                  a composer that appears and then leaves has
                                  already invited a reply it cannot take
  commenting .failed            → Couldn't tell whether this app takes comments.
                                  [Try Again]        ← asks the config only
  commenting .included          → the composer, unchanged:
                                    "Add a comment"                       ⬆
                                    ⬆ disabled while the draft trims to nothing,
                                    replaced by a spinner while write.isWriting
```

## Platform differences

- **iOS 18+ and macOS 15+.** `Package.swift` declares no other platform, so there is no watchOS,
  tvOS or visionOS behaviour to describe.
- **`ContentUnavailableView`** — what `AbsentSurface` is — centres in the available space on both,
  which is the whole screen for a gated surface. It is the same component `LoadFailure` and the
  empty states use, so an absent surface, an unreachable one and an empty one are three different
  sentences in the same frame rather than three different-looking screens.
- **The composer's strip** is a `VStack` under a `Divider()` on both platforms, sized by its own
  text. It is not a keyboard accessory on either, so nothing about it changes when a hardware
  keyboard is attached on iPad or when there is no keyboard at all on macOS.
- **The copy is one string per case on both platforms.** Nothing says "tap", so nothing has to be
  rewritten for a cursor.
- **No `NavigationStack` of its own.** As with every screen in this package, the host app owns the
  stack on every platform, which is why the absent screens keep their `navigationTitle`.

## Tests that walk this

All hermetic. Two ways of reaching a real failure without a network, both already in use here:

1. **A scheme `URLSession` will not open.** A client built against a base URL with an unusable
   scheme fails inside `URLSession.data(for:)` without a lookup or a connection. `GetConfig` is an
   `APP_KEY` rpc, so this is how its failure path is reached — the audience gate does not stand in
   for it.
2. **Values, walked directly.** `PlanSurface` and `PlanState` are decided from a `DRAppConfig` built
   in the test, which is exactly what the store passes them.

| Test file / test | The leg it walks |
| --- | --- |
| `PlanGatingTests.everySurfaceSaysWhatIsThereInstead` | Walks `PlanSurface.allCases`: each has a title, a description and a symbol, and no two surfaces say the same thing — so a surface added to the enum is covered by being declared |
| `PlanGatingTests.nothingSaidToAReaderMentionsAPlan` | The same walk, against the words the contract forbids: plan, Pro, Free, upgrade, subscribe, price. `planRequired` is written for the host developer and is never surfaced to an end user |
| `PlanGatingTests.eachSurfaceReadsItsOwnFlag` | One config per flag, walked over `allCases`: turning on `roadmapEnabled` includes the roadmap and nothing else, and the same for the other two — a surface handed the contract's wrong name fails here |
| `PlanGatingTests.aConfigThatSaysNothingIncludesNothing` | Both ends of `PlanState(surface:response:)`, walked over `allCases`: an all-false `DRAppConfig` excludes every surface and an all-true one includes every surface, so the gate closes and opens rather than only closing |
| `PlanGatingTests.aResponseWithNoConfigIsAFailureRatherThanAnAnswer` | `PlanState(surface:response:)` on a `DRGetConfigResponse` with `hasConfig == false` → `.failed(.incompleteResponse(.getConfig))`, walked over `allCases`. The defaulted-to-false trap |
| `PlanGatingTests.anAnsweredPlanIsNotAskedAgainAndAFailedOneIs` | `needsReading` across every `PlanState` case: false once answered either way, true after a failure |
| `PlanGatingTests.onlyAnIncludedSurfaceIsRead` | `isIncluded` across every case — that an unknown plan is not read as an included one, which is what stops a read being started on a guess |
| `PlanGatingTests.aRoadmapIsNotReadUntilTheAppSaysItHasOne` | `RoadmapStore.load()` with `plan` seeded `.excluded`: `read` is still `.unread` afterwards, and `plan` was not re-asked. The rpc that answered `planRequired` is not called |
| `PlanGatingTests.aChangelogIsNotReadUntilTheAppSaysItPublishesOne` | The same for `ChangelogStore`, including that `page` is left alone — a surface the app lacks has no page to ask for |
| `PlanGatingTests.aPlanThatCouldNotBeReadReadsNothingAndSaysSo` | `RoadmapStore.load()` and `ChangelogStore.load()` against an unusable scheme: `plan.failure` is set and `read` is still `.unread`, because whether the surface exists is not known |
| `PlanGatingTests.aSurfaceTheAppHasIsRead` | The same two stores with `plan` seeded `.included`: the surface read happens and lands on `read.failure`, so the gate opens as well as closes |
| `PlanGatingTests.aRequestThatCannotBeReadDoesNotAskAboutComments` | `RequestDetailStore.load()` against an unusable scheme: `commenting` is still `.unread`. There is nothing to comment on |
| `PlanGatingTests.aComposerAsksAgainAfterAConfigReadThatFailed` | `loadCommenting()` twice: `.failed` leaves `needsReading` true, so the **Try Again** in the strip is a retry rather than a no-op |
| `PlanGatingTests.aSettledCommentingAnswerIsNotAskedAgain` | `loadCommenting()` with `commenting` seeded `.excluded` leaves it `.excluded` — no read, no flicker back to a spinner |
| `StoreReadTests.aFirstReadThatFailsLandsOnTheState` | Updated: the roadmap and the changelog now fail at the config read, so the leg it walks is `plan.failure` set with `read` untouched. The board, the inbox and the request detail are unchanged |
| `AudienceTests.readingTheBoardNeedsOnlyAnAppKey` | Already covered `.getConfig` as `APP_KEY`. That is what lets the gate be answered before anyone signs in |

Not walked here, and why:

- **The cache holding across two calls.** It needs a 2xx protobuf answer to have anything to hold —
  a read that throws is deliberately not remembered, so the failing-transport trick cannot observe
  it. What it is made of is one optional assigned on the success path of `config()`.
- **The SwiftUI legs** — that `AbsentSurface` is on screen, that the composer's strip does not jump
  as the answer arrives. They need a host app; the Example is that host app, and the owner verifies
  it by running it.
