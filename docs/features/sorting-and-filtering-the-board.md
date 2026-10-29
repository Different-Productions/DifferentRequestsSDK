# Sorting and filtering the board

## What it is and how to trigger it

One bar button on the Requests screen that decides two things about the list: how the requests are
ranked, and which statuses they are drawn from. With the search field they are the three narrowings
the list rpc takes, and each is one query parameter on the same call.

Until 2026-10-09 this was a bar of chips above the list with a sort menu at its end. It became one
system menu in the toolbar (#167): Apple's rules are "Use progressive disclosure to make layouts
cleaner" and "Consider using a checkmark to show that an attribute is currently in effect", and the
chip bar pushed the first request 78 pt down the screen.

Three things are one behavior here:

1. **The menu offers what the contract can send, and only that.** The rankings are
   `DRRequestSort.allCases` filtered to the values with a `urlToken`. The statuses are
   `DRRequestStatus.shownOnABoard`. Nothing in this package lists a status or a ranking, so one added
   to the contract arrives by being declared.
2. **Statuses and sort are settable, and the cursor knows it.** `BoardStore` compares the whole
   question it is asked, statuses, sort and search text, as one `DRListRequestsRequest`. A cursor
   addresses the results of the question it came back for, so changing any of the three throws away
   the pages held under the old one and starts at page one.
3. **The button is reachable in every state the board can be in.** It is a toolbar item, so
   narrowing to a status nothing is in leaves the control that undoes it exactly where it was.

Trigger: on the Requests screen, tap the button with three shortening lines, then pick a ranking,
**All**, or a status.

- A ranking calls `BoardStore.show(sort:)`. The one in use has a checkmark.
- A status calls `BoardStore.toggle(status:)`: on if it was off, off if it was on. Several can be on
  at once, and they are sent as one comma-separated `statuses` value.
- **All** calls `BoardStore.showEveryStatus()`, which clears the statuses and leaves the search text
  alone. It has the checkmark while no status is on.
- While any status is on, the button is filled with the tint.

A host app building its own screen calls `DifferentRequestsClient.requests(_:)` with the same three
fields. It needs no session: `ListRequests` declares the `APP_KEY` audience.

## Expectations

| What someone does | What they get |
|---|---|
| Opens the menu for the first time | A checkmark on **Most votes** and on **All**, and the whole board ranked by votes |
| Picks **Newest** | The old rows stay up, then the board comes back newest-first from page one |
| Picks **Planned** | **All** loses its checkmark, **Planned** gains one, the button fills with the tint, and the board is read as `?statuses=planned` |
| Picks **Planned**, then **Shipped** | Both checked, sent as `?statuses=planned,shipped` |
| Picks **Shipped**, then **Open** | Sent as `?statuses=open,shipped`, in the order the contract declares them, so one set is always one URL |
| Picks **Planned** a second time | Its checkmark goes, **All** is checked again, and the whole board comes back |
| Picks **All** after searching "dark mode" | Statuses cleared, the search text still applied |
| Searches "dark mode" with **Shipped** on | Both narrowings on one call: `?sort=top&statuses=shipped&query=dark%20mode` |
| Scrolls four pages into a filtered board | Each further page is asked for under the filter its cursor came from |
| Filters, opens a request, comes back | The same filter, the same rows, the same place in them, and no re-read |
| Pulls to refresh a filtered board | The same filter, read again from page one |
| A status is added to the contract | It appears in the menu with no change to this package |

| When it fails or finds nothing | Exact text |
|---|---|
| The statuses chosen hold nothing | "No requests in this filter" / "No requests match this filter." with **Show all** and **New request** |
| A search inside a status filter matches nothing | "No requests match in this filter" / "Nothing matches this search with this filter." with the same two buttons |
| A search on an unfiltered board matches nothing | "No requests match your search" / "Nobody has asked for this yet." with **New request** |
| The read a menu item started does not answer | "Requests couldn't load" / "Something went wrong on the server. Try again in a moment." with **Try again**. The button is still in the bar, so the filter can be changed without a good read first |
| A further page of a filtered board fails | "Couldn't load more requests." with **Try again**, as one row under the last. The rows already read stay, and so does the filter |
| The contract carries a status with no `url_token` | It is never offered, because it cannot be sent |

## Flow chart

```
Host app  -->  DifferentRequestsHub.swift
                 board = BoardStore(client:, statuses: [], sort: .top)
        |
        v
DifferentRequestsView.swift  -->  RequestsScreen.swift
   .toolbar { RequestsToolbar }                      RequestsToolbar.swift
        |     statuses.isEmpty ? FilterMenu : FilterMenu.buttonStyle(.glassProminent)
        v
FilterMenu.swift          Menu, two sections         MenuCheckLabel.swift draws the checkmark
   ForEach(board.offeredSorts)                       DRRequestSort+FilterLabel.swift
        AsyncButton.swift --> BoardStore.show(sort:)
   "All"  --> BoardStore.showEveryStatus()
   ForEach(board.offeredStatuses)                    DRRequestStatus+LocalizedLabel.swift
        AsyncButton.swift --> BoardStore.toggle(status:)

Stores/BoardStore.swift
   show(sort:) / toggle(status:) / showEveryStatus()  --> load()
   load()
     if status.isReading(): the read already running finishes the job
     repeat
       status.state = .reading(Reading())   State/ReadStatus+Reading.swift   the rows held stay up
       asked = question; cursor = ""; page = .more
       readFirstPage(asked) --> DifferentRequestsClient.swift  requests(_:)
            sort.urlToken, statuses' urlTokens joined by commas   GET /requests
     while asked != question             a choice made mid-read is read next, not dropped
   loadMore() --> fetch(asked, cursor:)  asked, never question: the cursor belongs to it

RequestsContent.swift     switch board.read
   .empty --> RequestsEmpty.swift --> State/BoardNarrowing+Wording.swift
                 a status filter on --> NarrowedEmptyActions.swift: Show all, New request

Search walks the same store through another door:
DifferentRequestsView.swift   .searchable(text: board.query)
RequestsScreen.swift          .task(id: board.query) --> BoardStore.search()
                                 isCurrent: nothing. Else wait 300 ms when there is text, then load()
```

A host that knows the board is about to open can pay for the first page early with
`DifferentRequestsHub.readTheBoardBeforeItIsShown()`. A board already read is not read again.

## What was walked

- 2026-09-26, iOS 27 simulator, the chip bar this replaced: Most votes and Newest, one status then a
  second, a search in a body and in a title, a search matching nothing, and the statuses offered
  (Open, Planned, In progress, Shipped, Declined, and no Duplicate).
- 2026-10-09, iPhone 17 Pro simulator "DR Redesign Walk", iOS 26.0, local server, a Free app
  ("Walk Provisioned App"): the menu opened with checkmarks on Most votes and All. Shipped left one
  request and filled the button with the tint. Declined left none: "No requests in this filter"
  with **Show all** and **New request** at one size, and **Show all** brought the board back. A
  search for "widget" found one request, and one for "widgetzzzq" found none: "No requests match
  your search" with **New request**. Newest was not picked.
- The owner's real walk: not yet.
