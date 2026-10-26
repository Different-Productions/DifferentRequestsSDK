# Inbox, Roadmap and What's New, redrawn

Issue #167, third slice. The mockup, its rule sheet and its planned frames are in the Second Brain:
`projects/different-requests/documents/2026-10-09-sdk-redesign-mockup.html`.

## What it is and how to trigger it

The three screens beside Requests take the same look it has: rows on a card in a grouped list, the
named text roles and colors, and no size written in a view.

**Inbox.** One row per update, at least 70 pt tall, and the whole row opens the request.

- An unread row has a dot in the tint and its headline at the rowTitle weight. A read row has no
  dot and its headline at the reading weight. VoiceOver says "Unread".
- The dot is a mark, not a button. An update is read by opening it, by swiping the row and choosing
  **Mark as read**, or by **Mark all as read** in the bar.
- Under the headline, the request's title and the age share one line.
- The Inbox tab's badge is the server's unread count. It drops as rows are read.

**Roadmap.** One section per status. Its heading is the status as a word, with the count spelled out
beside it: "2 requests". A row is the request's title at the reading size and its votes in words
under it. Nothing on this screen looks like a vote button.

**What's New.** One update is one card: its title, "Version 3.2" and the age on one line, the notes
at the reading size, then "Requests in this update" and one row per request it answers. Each of
those rows opens its request.

**Every empty and failed state** on these screens sits on the grouped background and uses the
system's button sizes.

Trigger: in a Pro app, open the SDK's sheet and tap Roadmap, What's New or Inbox. Each can also be
presented alone, as before.

## Expectations

| When it works | What the person sees |
|---|---|
| Opens Inbox with an unread update | A dot and a heavier headline on that row, and the count on the Inbox tab |
| Opens that update | The request. Back on Inbox the dot is gone and the badge is one lower |
| Swipes an unread row | **Mark as read** |
| Taps **Mark all as read** | Every dot goes and the badge goes. The button is there only while something is unread |
| Opens Roadmap | A heading and a spelled-out count per status, then its requests |
| A status has nothing in it | "No requests here yet." under its heading |
| Opens What's New | One card per update, newest first |
| Taps a request under "Requests in this update" | That request's own screen |

| When it fails or is empty | Exact text |
|---|---|
| Inbox cannot be read | "Inbox couldn't load" / the sentence for the kind of trouble / **Try again** |
| Inbox has nothing, or nobody is signed in | "No updates yet" / "Vote for or follow a request, and you'll get updates here when it changes." |
| An update cannot be marked read | "Couldn't mark this update as read. Try again." with Dismiss |
| Everything cannot be marked read | "Couldn't mark every update as read. Try again." with Dismiss |
| Roadmap cannot be read | "Roadmap couldn't load" / the sentence / **Try again** |
| Roadmap has nothing on it | "Nothing planned yet" / "When the team plans something, it shows up here." |
| What's New cannot be read | "What's New couldn't load" / the sentence / **Try again** |
| What's New has nothing | "Nothing new yet" / "When the app gets something new, you'll read about it here." |
| A further page fails | "Couldn't load more updates." or "Couldn't load more of What's New." / **Try again**, as one row |
| The app's plan has no roadmap, and a host app presents `RoadmapView` itself | "This app has no roadmap" / "This app doesn't share its plans." |
| The app's plan has no updates, and a host app presents `ChangelogView` itself | "This app doesn't post updates" / "If that changes, its updates will show up here." |

## Flow chart

```
DifferentRequestsView.swift   Tab inbox .badge(hub.inbox.unreadCount)   Stores/InboxStore.swift
        |
        v
InboxView.swift               .task: whoIsHere.read, store.load (page and unread count, one read)
   |  toolbar: Mark all as read -> InboxStore.markAllRead()   only while unreadCount > 0
   v
InboxContent.swift            switch store.read
   +-- failed -> LoadFailure.swift     +-- empty -> InboxEmpty.swift
   +-- loaded -> InboxList.swift       View+GroupedList.swift
         +-- WriteFailureNotice.swift
         +-- InboxRow.swift   -> UnreadDot.swift, DRNotification+InboxRow.swift
         |      push -> RequestDetailView.swift   .task -> InboxStore.markRead(notificationID:)
         |      swipe -> Mark as read -> InboxStore.markRead(notificationID:)
         +-- NextPageRow.swift

RoadmapView.swift             .task: Stores/RoadmapStore.swift load()
   v
RoadmapContent.swift          switch store.plan, then store.read
   +-- excluded -> AbsentSurface.swift -> SeeRequestsButton.swift
   +-- empty    -> RoadmapEmpty.swift
   +-- loaded   -> RoadmapList.swift
         +-- RoadmapHeading.swift   the status word and "%lld requests"
         +-- RoadmapRow.swift       push -> RequestDetailView.swift

ChangelogView.swift           View+FirstRead.swift -> Stores/ChangelogStore.swift load()
   v
ChangelogContent.swift        switch store.plan, then store.read
   +-- excluded -> AbsentSurface.swift
   +-- empty    -> ChangelogEmpty.swift
   +-- loaded   -> ChangelogList.swift
         +-- ChangelogEntryHeader.swift   title, "Version %@", Date+Ago.swift, notes
         +-- ChangelogAnswerRow.swift     push -> RequestDetailView.swift
         +-- NextPageRow.swift
```

## What was walked

- 2026-10-09, iPhone 17 Pro simulator "DR Redesign Walk", iOS 26.0, local server behind Caddy,
  signed in as Demo User, walked with AXe. A Pro app ("Calls Walk") and two Free apps ("Walk
  Provisioned App", "Identity Walk").
  - Roadmap on Pro: Planned with "1 request", In progress with "0 requests" and "No requests here
    yet.", Shipped with "2 requests"; each row a title and its votes in words.
  - What's New on Pro: one card headed "Version 1.0.0", its age, its notes, "Requests in this
    update" and one row that opens its request.
  - Inbox on Pro: the team replied twice to a request Demo User follows, from the dashboard. The
    Inbox tab showed 2 from the Requests tab. Both rows drew the dot and the heavier headline.
    Opening one read it: back on Inbox its dot was gone and the badge said 1. A swipe showed
    **Mark as read**. **Mark all as read** cleared the other, the badge and the button.
  - Inbox on Free: two read rows on one app, and "No updates yet" on the other.
  - Light and dark, the accessibility-extra-large text size (the request title and the age stack
    under the headline), and Arabic (the screens mirror).
  - Measured, in points, planned beside measured: Inbox row 370 wide and 70 tall planned, 370 by
    66.3 measured, because the system's lines are 20.3 and 18 high where the plan assumed 22 and
    20; headline at x 52 and 52.3; Mark all as read 164 by 44 planned and a 132 by 36 element in a
    44 pt glass capsule drawn by iOS; roadmap heading at x 32 and 32, row 68 planned and 64
    measured for the same reason; first group under the title at 187 and 188.
- Not walked: a read that fails on any of the three (the example app stops at its own "Can't reach
  Different Requests" before any SDK screen), a failed mark-read, an empty Roadmap or What's New,
  the next-page rows, and a host app presenting Roadmap or What's New for a Free app.
- Screenshots: `~/Developer/Screenshots/DifferentRequests/2026-10-09 SDK redesign build/`, the files
  that start `s3-`.
- macOS: the package and the example app build for macOS 26. The Mac layout was not looked at:
  reaching an SDK screen in the example means clicking in a window on the owner's desktop.
- The owner's real walk: not yet.
