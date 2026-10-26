# Requests in tabs, on a design system

Issue #167, first slice. The mockup, its rule sheet and its planned frames are in the Second Brain:
`projects/different-requests/documents/2026-10-09-sdk-redesign-mockup.html`.

## What it is and how to trigger it

Three things ship together.

**A design system.** Every gap, size, text style and color the redrawn screens use has a name, and
the names live in one place each. No file touched by this slice keeps a one-off number.

| Token | Values | Shape in Swift |
|---|---|---|
| `Spacing` | 4, 8, 12, 16, 20, 24, 32 | an enum with `CGFloat` raw values |
| `TargetSize` | 44, the smallest tap area | the same |
| `Radius` | 12, the vote tile. Controls are capsules and a group's corner is the system's | the same |
| `VoteTileSize` | 48 wide, 56 tall, both minimums | the same |
| `TextRole` | screenTitle (Large Title), requestTitle (Title 2), rowTitle (Headline), reading (Body), supporting (Subheadline), meta (Footnote) | an enum, read with `.textRole(_:)` |
| `ColorRole` | label, secondaryLabel, fill, tint, onTint, failure | an enum that is a `ShapeStyle` |

The tint is the host app's own color: the one its developer chose in the dashboard, or else
`Appearance.accent`, applied once by `worn(by:)` (`a-tint-set-in-the-dashboard.md`). `onTint` is
the label drawn on that color: white where white measures 4.5 to 1 against the tint in the
appearance being drawn, and black where it does not. The contrast floor wins over matching the white
iOS draws on its own filled buttons. The screen background, the card behind rows and the lines
between rows are the system's grouped list, so they have no token.

**Tabs in the SDK's sheet.** Requests and Inbox are always tabs in the system tab bar. Roadmap and
What's New are tabs only where the app's plan includes them. Each tab has its own navigation stack.
The Inbox tab carries the unread count as a badge. The system search button sits beside the tab
bar. The More menu is gone.

Owner ruling, 2026-10-09: inside the SDK, nothing is shown that the developer has not paid for. So a
Free app's tab bar is Requests and Inbox, plus search. This departs from Apple's rule quoted in the
rule sheet, "Don't disable or hide tab bar buttons, even when their content is unavailable", by
that ruling. While the app's configuration is still being read, only Requests and Inbox are drawn,
and the other two are added when the answer says the plan has them, so no tab appears and then goes
away. "This app has no roadmap" and "This app doesn't post updates" stay for the case they were
built for: a host app that presents `RoadmapView` or `ChangelogView` itself.

**The Requests screen, redrawn.** A grouped list that starts directly under the title.

- A row is a vote tile, a title, one supporting line, and one line of status, comment count and age.
- The vote tile is at least 48 by 56 pt. Voted, it is filled with the tint and its triangle is
  solid. Not voted, it is filled gray with an outline triangle. It flips the moment it is tapped.
- Status is a symbol and a word in the label color. An unanswered request reads "Open".
- Filter and sort are one bar button that opens a system menu: the rankings, then All and each
  status, with checkmarks. The button is filled with the tint while a status filter is on.
- New request is one filled plus button, trailing. Close is the system close button, leading.
- A Free app shows one "Powered by Different Requests" row after the last request. It pushes
  "What is this?" onto the same stack.
- At accessibility text sizes the vote tile moves above the title, and status, comments and age
  stack.

Trigger: present `DifferentRequestsView(hub:)` in a sheet. In the example app, tap **Requests**.

## Expectations

| When it works | What the person sees |
|---|---|
| The sheet opens | The Requests tab, selected, with the list under the title "Requests" |
| Taps Roadmap, What's New or Inbox | That screen, with its own title, and the system close button |
| Has unread updates | The count on the Inbox tab, from every tab |
| Pro app | Four tabs: Requests, Roadmap, What's New, Inbox |
| Free app | Two tabs: Requests, Inbox. No Roadmap or What's New tab at any moment |
| The configuration has not answered, or failed | Requests and Inbox only |
| Nobody is signed in | No New request button, a plain count where the vote tile would be, and an Inbox that says "No updates yet" |
| Taps a vote tile | The tile fills and the count goes up by one at once. The server's count replaces it when it answers |
| Taps a voted tile | The tile empties and the count goes down by one at once |
| Opens the filter and sort button | "Most votes" and "Newest", then "All" and each status. What is on has a checkmark |
| Picks a status | The list is read again for it, and the button is filled with the tint |
| Taps the search button | The search field takes the tab bar's place, over the same list. Typing narrows it after 300 ms |
| Leaves search for another tab | The search text is cleared, so the Requests tab is the whole board again |
| Scrolls to the last row | A spinner row, then the next page |
| Free app | "Powered by Different Requests" after the last row, with a chevron |
| Text size at an accessibility size | The tile above the title; status, comments and age on their own lines |
| Arabic | The tile trailing-to-leading mirrored by the system; chevrons point the other way |

| When it fails | Exact text |
|---|---|
| The list cannot be read, offline | "Requests couldn't load" / "You're offline. Check your connection and try again." / **Try again** |
| The list cannot be read, otherwise | "Requests couldn't load" / "Something went wrong on the server. Try again in a moment." / **Try again** |
| No requests at all | "No requests yet" / "Ask for what you want in this app, and everyone can vote on it." / **New request** |
| A search finds nothing | "No requests match your search" / "Nobody has asked for this yet." / **New request** |
| A status filter leaves nothing | "No requests in this filter" / "No requests match this filter." / **Show all**, **New request** |
| A search inside a filter finds nothing | "No requests match in this filter" / "Nothing matches this search with this filter." / **Show all**, **New request** |
| The next page fails | "Couldn't load more requests." / **Try again**, as one whole row |
| A vote is refused | The tile goes back to what it was, and "Your vote didn't go through. Try again." sits above the rows with **Dismiss** |

## Flow chart

```
Host app: .sheet { DifferentRequestsView(hub:) }
        |
        v
DifferentRequestsView.swift          TabView(selection: ScreenTab)        ScreenTab.swift
   |  .searchable(text: hub.board.query)     .worn(by:)  View+WornBy.swift
   |  .task: appConfig.load, whoIsHere.read, inbox.load (the badge's count)
   |
   +-- Tab requests  -> NavigationStack { RequestsScreen }
   +-- Tab roadmap   -> NavigationStack { RoadmapView }      RoadmapView.swift
   |      only if appConfig.config.roadmapEnabled            Stores/AppConfigStore.swift
   +-- Tab changelog -> NavigationStack { ChangelogView }    ChangelogView.swift
   |      only if appConfig.config.changelogEnabled
   +-- Tab inbox     -> NavigationStack { InboxView }        InboxView.swift   .badge(inbox.unreadCount)
   +-- Tab search (role: .search) -> NavigationStack { RequestsScreen }
        |
        v
RequestsScreen.swift
   |  .toolbar { RequestsToolbar }           RequestsToolbar.swift
   |       close      -> SheetClose.swift, View+SheetClose.swift, SheetRootProbe.swift
   |       FilterMenu -> FilterMenu.swift -> BoardStore.sort, toggle(status:), showEveryStatus()
   |       NewRequestButton.swift -> hub.beginSubmission(), SubmitRequestView.swift
   |  .task(id: board.question) -> BoardStore.search()      Stores/BoardStore.swift
   v
RequestsContent.swift                switch board.read
   +-- unread, reading -> ProgressView
   +-- failed          -> LoadFailure.swift   (State/ReadTrouble.swift picks the sentence)
   +-- empty           -> RequestsEmpty.swift (State/BoardNarrowing.swift, EmptyBoard.swift)
   +-- loaded          -> RequestsList.swift
                            +-- WriteFailureNotice.swift
                            +-- RequestRow.swift
                            |     +-- VoteControl.swift -> VoteTileStyle.swift, VoteMark.swift
                            |     |        tap -> BoardStore.toggleVote(requestID:)
                            |     |               flips the row, then DifferentRequestsClient.vote / clearVote
                            |     +-- VoteTally.swift (nobody signed in)
                            |     +-- RequestSummary.swift -> StatusBadge.swift, StatusMark.swift,
                            |              CommentCount.swift, Date+Ago.swift
                            |     +-- push -> RequestDetailView.swift
                            +-- NextPageRow.swift -> RetryRow.swift
                            +-- PoweredByRow.swift -> push PoweredByPage.swift

Tokens read by the views above:
   Spacing.swift  TargetSize.swift  Radius.swift  VoteTileSize.swift
   TextRole.swift  View+TextRole.swift  ColorRole.swift
```

## What was walked

- 2026-10-09: `swift build` (macOS), `xcodebuild` for the iOS simulator and the example app all
  build with no warnings, and `swiftlint lint --strict` finds nothing.
- 2026-10-09, iPhone 17 Pro simulator "DR Redesign Walk", iOS 26.0, local server behind Caddy,
  signed in as Demo User, walked with AXe. A Free app ("Walk Provisioned App") and a Pro app
  ("Calls Walk").
  - Free: the tab bar is Requests, Inbox and search. Pro: Requests, Roadmap, What's New, Inbox and
    search, drawn in the example's purple and rounded font. Each tab opened with the close button.
  - A vote filled the tile and took the count from 1 to 2 at once; taking it back emptied it. On
    Pro the notification card followed the vote. A voted tile is white on the tint.
  - The filter and sort menu, a status filter, a filter that leaves nothing, **Show all**, search
    with a match and without one, the new request form opened and canceled, a request pushed (the
    tab bar goes), and "What is this?" pushed from the Powered by row.
  - Light and dark, the accessibility-extra-large text size (the tile sits above the title and the
    facts stack), and Arabic (the whole screen mirrors).
  - Measured, in points, planned beside measured: bar buttons 44 by 44 planned, and iOS draws a 44
    pt glass circle at the planned place around an accessibility element of 36 by 36; the filter
    button while a status is on is a 43 pt filled circle in a 61 by 44 element, 12 pt left of plan;
    menu rows 44 tall planned and 42 drawn by iOS; first row 187 and 188; vote tile 32, row + 12, 48 by 56 and the same; text edge 92 and 92;
    Powered by row 12 under the group, 370 by 44, and the same; tabs 70 by 52 planned and 78 to 94
    by 54 drawn by iOS; search button 60 by 60 planned and 62 by 62 drawn by iOS.
- Not walked: an unread count on the Inbox tab (neither app's person had an unread update), the
  failed read, the next-page row (no board was longer than a page), and nobody signed in.
- Screenshots: `~/Developer/Screenshots/DifferentRequests/2026-10-09 SDK redesign build/`.
- macOS: builds. Not walked; the Mac walk waits for the owner's go-ahead.
- The owner's real walk: not yet.
