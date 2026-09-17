# Signing the example in as anyone

## What it is

The example app signs in with `createSession` when it launches. Who it signs in as comes from two
environment variables, read the way `DIFFERENT_REQUESTS_APP_KEY` is:

| Variable | Unset |
|---|---|
| `DIFFERENT_REQUESTS_EXTERNAL_ID` | `demo-user` |
| `DIFFERENT_REQUESTS_DISPLAY_NAME` | `Demo User` |

So a walk can be a different person, or the same person under a new name, without editing the app.

## Surfaces

| Surface | Ships this? |
|---|---|
| The example app | **Yes** — `ProcessInfo+DemoPerson.swift`, read by `Session.start()` |
| The SDK library | **none** |
| The server, console, documentation | **none** |

## How to find it, trigger it, and what happens

Set either variable in the scheme (Run → Arguments → Environment Variables), or pass it when launching
on a simulator:

```sh
SIMCTL_CHILD_DIFFERENT_REQUESTS_EXTERNAL_ID=walk-ada \
SIMCTL_CHILD_DIFFERENT_REQUESTS_DISPLAY_NAME=Ada \
  xcrun simctl launch <device> productions.different.DifferentRequestsExample
```

The app signs in as that identifier with that name, and everything it does after is that person's.

## Expectations

### What works

| Given | When | Then |
|---|---|---|
| Neither variable set | The app launches | It signs in as `demo-user`, named `Demo User`, as before |
| `DIFFERENT_REQUESTS_EXTERNAL_ID=walk-ada` | The app launches | The session is `walk-ada`'s |
| `DIFFERENT_REQUESTS_DISPLAY_NAME=Ada` | The app launches | `createSession` sends the name `Ada` |

### What does not happen

| Given | When | Then |
|---|---|---|
| A variable set to an empty string | The app launches | Treated as unset: `demo-user` / `Demo User` |
| `DIFFERENT_REQUESTS_APP_KEY` unset | The app launches | Unchanged: the app says what to set and signs nobody in |

## Flow chart of the real code path

```
DifferentRequestsExampleApp · RemoteNotificationDelegate.session
  └─ Session.start()                                          (Session.swift)
       ├─ DemoConfig.isConfigured == false ──► .unconfigured
       └─ Session.signIn()
            └─ client.createSession(
                 externalID:  ProcessInfo.processInfo.demoExternalUserID  (ProcessInfo+DemoPerson.swift)
                                ├─ DIFFERENT_REQUESTS_EXTERNAL_ID non-empty ──► that
                                └─ otherwise ────────────────────────────────► DemoConfig.externalUserID
                 displayName: ProcessInfo.processInfo.demoDisplayName
                                ├─ DIFFERENT_REQUESTS_DISPLAY_NAME non-empty ──► that
                                └─ otherwise ────────────────────────────────► DemoConfig.displayName
                 proof:       DemoBackend.vouchFor(externalID:)            (DemoBackend.swift)
               )
```

## UI map

No screen changes. The name appears wherever the SDK draws the signed-in person, such as a request they
file, and on the console's People page.

```
Example app → board → a request they filed
┌──────────────────────────────────────┐
│ Bigger type                          │
│ Ada                                  │ ← the author name: DIFFERENT_REQUESTS_DISPLAY_NAME, for a new person
└──────────────────────────────────────┘
While starting: a progress view reading "Starting…", until what this app offers has been read.
```

## Platform differences

| Platform | Difference |
|---|---|
| iOS simulator | `SIMCTL_CHILD_` prefix passes a variable through `simctl launch` |
| Xcode run | The scheme's environment variables |

## What walks the chart

| Walk | Result |
|---|---|
| Build the example | `** BUILD SUCCEEDED **`, and CI builds it on every change |
| Launch with `DIFFERENT_REQUESTS_EXTERNAL_ID` and `DIFFERENT_REQUESTS_DISPLAY_NAME` against development | The console's People page finds that identifier |
