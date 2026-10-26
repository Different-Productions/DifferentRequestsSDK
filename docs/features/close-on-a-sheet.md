# Close on a sheet

## What it is and how to trigger it

Every SDK screen that is the first screen of a sheet draws the system close button, leading, and
draws nothing when it was pushed, because a pushed screen already has its back button. The host app
adds no button of its own. It replaced a **Done** button on 2026-10-09 (#167): Apple's rule is
"Use the standard Back and Close buttons", and Done alone says finishing a task is the only way out
of a sheet that is only read.

SwiftUI's `isPresented` is true both for a sheet's first screen and for a pushed one, so the SDK
reads the answer from the platform: an empty view controller behind the screen checks, each time the
screen appears, whether its navigation stack was presented and whether this screen is that stack's
first.

Trigger: present `DifferentRequestsView(hub:)` in a sheet and look at any of its tabs; or
present `NavigationStack { InboxView(hub:) }` (or Roadmap, or What's New) in a sheet.

## Expectations

| When it works | What the user sees |
|---|---|
| Any tab of the SDK's sheet, at its first screen | The close button at the top leading corner; tapping it closes the sheet |
| Inbox, Roadmap or What's New shown alone as a sheet | The same |
| A request pushed from any list | A back button, and no close button |
| The same screen pushed onto the host app's own list | A back button, and no close button |
| The same screen as a host app's own tab root, not presented | No close button |
| macOS | The close button whenever the screen is inside a sheet window. macOS gives no view controller stack to read, so a screen pushed inside a sheet shows it too, and there it goes back one screen |

| When it fails | Exact error text the user sees |
|---|---|
| Nothing can fail here | None |

## Flow chart

```
RequestsScreen / InboxView / RoadmapView / ChangelogView
        |      RequestsScreen.swift · InboxView.swift · RoadmapView.swift · ChangelogView.swift
        |  .sheetCloseButton()
        v
SheetClose (ViewModifier)                    SheetClose.swift · View+SheetClose.swift
        |  @State isSheetRoot, .background { SheetRootProbe($isSheetRoot) }
        v
SheetRootProbe                               SheetRootProbe.swift
   iOS   -> SheetRootProbeController.viewWillAppear     SheetRootProbeController.swift
              navigationController.presentingViewController != nil
              and this screen descends from viewControllers.first
   macOS -> SheetRootProbeView.viewDidMoveToWindow       SheetRootProbeView.swift
              window.sheetParent != nil
        |
        v
isSheetRoot ? ToolbarItem(.cancellationAction) { Button(role: .close) { dismiss() } } : nothing
```

The example app's `RootView.swift` presents the screens with no toolbar of its own; its
`DoneButton.swift` stays for Diagnostics, which is the example's own screen.

## What was walked

- 2026-09-26, iPhone simulator "DR Calls Walk", iOS 27, local server, when the button was still
  **Done**: Inbox, empty Roadmap and empty What's New from the example's list each drew it and it
  closed the sheet; the same screens pushed drew a back button and no Done.
- 2026-10-09, iPhone 17 Pro simulator "DR Redesign Walk", iOS 26.0, local server: the close button
  drew at the top leading corner of Requests, Roadmap, What's New and Inbox inside the SDK's sheet,
  and closed the sheet from Inbox. A request pushed from Requests, and "What is this?", drew a back
  button and no close button.
- macOS: builds. Not walked; the Mac walk waits for the owner's go-ahead.
- The owner's real walk: not yet.
