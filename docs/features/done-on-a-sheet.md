# Done on a sheet

## What it is and how to trigger it

Owner ruling 2026-09-26, piece 23. **Inbox**, **Roadmap** and **What's New** draw their own
**Done** when they are the first screen of a sheet, and draw nothing when they were pushed — a
pushed screen already has its back button. The host app no longer adds a Done of its own.

SwiftUI's `isPresented` is true both for a sheet's first screen and for a pushed one, so the SDK
reads the answer from the platform: an empty view controller behind the screen checks, each time the
screen appears, whether its navigation stack was presented and whether this screen is that stack's
first.

Trigger: present `NavigationStack { InboxView(hub:) }` (or Roadmap, or What's New) in a sheet; or
push the same screen from the board's **…** menu.

## Expectations

| When it works | What the user sees |
|---|---|
| Inbox, Roadmap or What's New shown as a sheet | **Done** at the top left; tapping it closes the sheet |
| The same screen pushed from the board's **…** menu | A back button, and no Done |
| The same screen pushed onto the host app's own list | A back button, and no Done |
| The same screen as a tab's root, not presented | No Done |
| macOS | **Done** whenever the screen is inside a sheet window. macOS gives no view controller stack to read, so a screen pushed inside a sheet shows Done too, and there it goes back one screen. Not walked: the Mac walk waits for the owner's go-ahead |

| When it fails | Exact error text the user sees |
|---|---|
| Nothing can fail here | — |

## Flow chart

```
InboxView / RoadmapView / ChangelogView     InboxView.swift · RoadmapView.swift · ChangelogView.swift
        |  .sheetDoneButton()
        v
SheetDone (ViewModifier)                     SheetDone.swift · View+SheetDone.swift
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
isSheetRoot ? ToolbarItem(.cancellationAction) { Button("Done") { dismiss() } } : nothing
```

The example app's `RootView.swift` presents the three screens with no toolbar of its own; its
`DoneButton.swift` stays for Diagnostics, which is the example's own screen.

## What was walked

- 2026-09-26, iPhone simulator "DR Calls Walk", iOS 27, local server: opened Inbox from the
  example's list — **Done** top left, **Mark all as read** top right; Done closed it. Opened the
  board, then **…** › Inbox — back button, no Done. Opened empty Roadmap and What's New from the
  list — Done on both. **…** › Roadmap from the board — back button, no Done.
- macOS: the SDK builds for macOS (`xcodebuild -scheme DifferentRequests -destination
  platform=macOS`). Not walked; the Mac walk waits for the owner's go-ahead.
- The owner's real walk: not yet.
