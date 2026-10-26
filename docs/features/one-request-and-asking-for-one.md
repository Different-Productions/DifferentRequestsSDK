# One request, and asking for one

Issue #167, second slice. The mockup, its rule sheet and its planned frames are in the Second Brain:
`projects/different-requests/documents/2026-10-09-sdk-redesign-mockup.html`.

## What it is and how to trigger it

**The request screen.** Pushed from any list of requests. It has a back button and no title in the
bar: the request's own title is the heading, in the requestTitle role.

- Under the title: status as a symbol and a word, who asked, and how long ago, on one line.
- What was written, in Body.
- Two buttons of one size in their own row, 12 pt apart. **Vote** shows a triangle and the count in
  words, and is filled with the tint once voted. **Follow** shows a bell; once following it shows a
  checkmark and says **Following**.
- A write that fails says so in a row under those buttons: a symbol, the sentence, and a 44 by 44
  pt Dismiss button. VoiceOver reads it when it appears.
- Comments are a grouped list under a "Comments" heading. A comment is the name, the Team mark (a
  seal and the word, where the team wrote it) and the age on one line, then the text in Body.
- The comment field is a bottom bar on glass: a 44 pt field and a 44 by 44 pt Send circle, filled
  with the tint once there is something to send. Comments scroll under it. The tab bar is hidden.

**The notification card.** One button, **Turn on notifications**, which opens Apple's prompt. Owner
ruling 2026-10-09: **Not now** is gone. The card has a 44 by 44 pt Dismiss button in its corner, as
the rule sheet's "make it easy for people to dismiss or avoid the help" asks.

**New request is a pushed screen.** Owner ruling 2026-10-09: only one sheet is ever up, so the form
is pushed onto the Requests stack. **Cancel** is leading and **Send** is trailing and filled. Each
field has a heading above it and help under it, and the character count has its own line. Leaving
with something typed asks first. After Send, the form goes and the new request's own screen opens.
The "Your request is posted" card that left after 4 seconds is gone.

**"What is this?"** no longer opens Safari as a sheet over the sheet. **About Different Requests** is
a row that opens the site in the browser.

Trigger: in the example app open **Requests**, tap a request; tap the plus button for the form.

## Expectations

| When it works | What the person sees |
|---|---|
| Opens a request | Its title as the heading, status, author and age, what was written, Vote and Follow |
| Taps Vote | The button fills with the tint, the triangle goes solid and the count goes up |
| Taps Follow | A checkmark and **Following** |
| First vote or follow, Pro app, permission never asked | The notification card under the request: heading, one sentence, **Turn on notifications**, and Dismiss |
| Taps **Turn on notifications** | The card goes and Apple's prompt comes up |
| Taps the card's Dismiss | The card goes and is not offered again on this phone |
| Types a comment | Send fills with the tint; near the limit a count appears over the field |
| Sends a comment | It joins the thread, the field empties and the keyboard goes |
| Nobody is signed in | A count in words in place of the two buttons, and no comment field |
| Taps the plus on Requests | The form is pushed: Cancel, "New request", Send |
| Types a title | Send can be tapped. A Clear button empties the title |
| Taps Cancel with nothing typed | The form goes |
| Taps Cancel with something typed | "Discard this request?" with **Discard request**. **Keep writing** is drawn where the system draws a cancel choice; on iPhone, iOS 26 leaves it to a tap outside |
| Taps Send | Send shows a spinner, then the form goes and the new request's screen opens |
| Taps **About Different Requests** | The site opens in the browser |

| When it fails | Exact text |
|---|---|
| The request cannot be read | "This request couldn't load" / the sentence for the kind of trouble / **Try again** |
| The request is gone | "This request is gone" / "It was removed, or the link that got you here is out of date." |
| A vote is refused | "Your vote didn't go through. Try again." with Dismiss |
| Taking a vote back is refused | "Couldn't remove your vote. Try again." with Dismiss |
| A follow is refused | "Couldn't follow this request. Try again." with Dismiss |
| A comment is refused | "Your comment didn't send. What you wrote is still here. Choose Send to try again." |
| The comments cannot be read | "Couldn't load the comments." / **Try again**, as one row |
| The app takes no comments | "Comments are off" / "This app doesn't have comments. Vote to show you want this." where the field would be |
| The title is over its limit | "12 characters too many" with a symbol, under the title field, and Send cannot be tapped |
| Send is refused | The form stays with what was typed, and the sentence for that refusal sits under Details with Dismiss |
| Apple's prompt cannot be asked | "Notifications couldn't be turned on. You can turn them on in Settings." with **OK** |

## Flow chart

```
RequestRow.swift / any list  -- push -->  RequestDetailView.swift      owns Stores/RequestDetailStore.swift
        |  .task: whoIsHere.read, store.load (again when NewsAboutRequests says it changed)
        v
RequestContent.swift            switch store.read
   +-- unread, reading -> ProgressView
   +-- failed          -> LoadFailure.swift
   +-- empty           -> "This request is gone"
   +-- loaded          -> RequestLoaded.swift     List, View+GroupedList.swift
         +-- RequestHeader.swift     title, StatusBadge.swift, RequestAuthor.swift, RequestAge.swift, body
         |     +-- RequestStateNote.swift   a decline's reason, or the link to the request it duplicates
         +-- RequestActions.swift
         |     +-- VoteButton.swift   -> PillButtonStyle.swift -> store.toggleVote()
         |     +-- FollowButton.swift -> PillButtonStyle.swift -> store.toggleFollow()
         |     +-- WriteFailureNotice.swift   State/WriteAttempt+Messages.swift picks the sentence
         +-- NotificationOfferCard.swift -> Stores/NotificationOffer.swift accept() / decline()
         +-- RequestThread.swift -> CommentRow.swift, CommentByline.swift, CommentAuthor.swift, TeamMark.swift,
         |                          NextPageRow.swift, RetryRow.swift
         +-- .safeAreaBar(bottom) RequestComposerBar.swift   switch store.commenting
               +-- included -> CommentComposer.swift -> SendButtonStyle.swift -> store.postComment()
               |                CharactersLeft.swift
               +-- excluded -> CommentsOff.swift

RequestsToolbar.swift  NewRequestButton.swift -> hub.beginSubmission(), isComposing = true
        v
RequestsScreen.swift   .navigationDestination(isPresented: isComposing)
        v
SubmitRequestView.swift          Stores/SubmitStore.swift
   Cancel -> store.holdsDraft() ? confirmationDialog : dismiss
   Send   -> DifferentRequestsHub.fileRequest() -> SubmitStore.submit() -> board.load()
        |  success: dismiss
        v
RequestsScreen.swift   isComposing became false and submission.submitted is held
        |  openedRequestID = submitted.id; SubmitStore.putAwaySubmitted()
        v
.navigationDestination(item: openedRequestID) -> RequestDetailView.swift

PoweredByRow.swift -- push --> PoweredByPage.swift   Link -> the browser
```

## What was walked

- 2026-10-09, iPhone 17 Pro simulator "DR Redesign Walk", iOS 26.0, local server behind Caddy,
  signed in as Demo User, walked with AXe. A Pro app ("Calls Walk") and a Free app ("Walk
  Provisioned App").
  - A request opened with its title as the heading and no title in the bar. Vote took the count
    from 1 to 2, filled with the tint and drew the one-time line. Follow went to **Follow** and
    back to **Following**.
  - The notification card followed the vote on Pro: one button and Dismiss. **Turn on
    notifications** put it away and brought up Apple's prompt.
  - Two comments were typed and sent. Send filled once there was text, the comment joined the
    thread, the field emptied and the keyboard went.
  - A vote refused by the server drew "Couldn't remove your vote. Try again." under the buttons
    with Dismiss, and Dismiss put it away.
  - The plus pushed the form. Cancel with a title typed asked "Discard this request?" with
    **Discard request**; iOS 26 draws the question as a popover and leaves **Keep writing** to a
    tap outside it. Send filed "Redesign walk: filed from the pushed form", the form went, and that
    request's own screen opened.
  - "What is this?" pushed from the Powered by row, as rows with a link row at the end. The link
    was not tapped.
  - Light and dark, the accessibility-extra-large text size (Vote and Follow stack, the byline
    stacks), and Arabic (the screen mirrors, Send is leading).
  - Measured, in points, planned beside measured: Vote and Follow 163 by 50 at x 32 and 207, and
    the same; request title at 32, 150 and 32, 151; Send circle 44 by 44 at x 342, and the same;
    comment field 314 wide at x 16, and the same; the card's Dismiss and the notice's Dismiss 44 by
    44; **Turn on notifications** 338 by 50 and 338 by 49.7; Cancel 88 by 44 planned and a 36 pt
    high element in a 44 pt glass capsule drawn by iOS; title field row 52 and 52.
- Not walked: a read that fails (the example app stops at its own "Can't reach Different Requests"
  when nothing answers, before any SDK screen), a comment that is refused, the over-limit count,
  nobody signed in, an app that takes no comments, and the card's Dismiss button.
- Screenshots: `~/Developer/Screenshots/DifferentRequests/2026-10-09 SDK redesign build/`, the files
  that start `s2-`.
- macOS: builds. Not walked.
- The owner's real walk: not yet.
