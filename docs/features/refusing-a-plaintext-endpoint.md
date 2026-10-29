# Refusing a plaintext endpoint

## What it is

This SDK will not dial `http`.

Every call it makes carries `X-App-Key`, and every call made for a person carries their session
token. Over plain `http` both cross the wire in the clear — and nothing about the request looks
wrong. **It works, which is the problem.**

The built-in production URL is `https`, so this only ever fires on an address a developer supplied
themselves: a staging endpoint, a local server, or a typo.

**Refused where it is written, and again where it is dialed.** `SecureBaseURL` is a generated
message whose initializers refuse anything but `https`, rather than a check inside the client, so
the failure lands on the line that wrote the URL and names it. A check on the first call alone would
report a broken request instead of a wrong address. The client still reads the address back through
the same check each time it dials, so a value whose `url` was set by hand is refused before anything
leaves the device.

## Surfaces

| Surface | Ships this? |
|---|---|
| `DifferentRequestsClient` | **Yes** — `init(appKey:baseURL:)` takes `SecureBaseURL` |
| `SecureBaseURL` | **Yes** — a generated message: `init(_:) throws`, `init(literal:)` and `init(service:)` |
| `SecureBaseURL(service: .production)` | **Non-throwing.** Production is a known `https` literal, so it cannot fail |
| The example app | Reads `DIFFERENT_REQUESTS_BASE_URL` and refuses a non-https one loudly |
| The server | **None.** This is a client-side refusal; the server never sees the call it prevents |

## How to find it, trigger it, and what happens

**The ordinary case needs no `try`.**

```swift
let client = DifferentRequestsClient(appKey: "dr_…", baseURL: SecureBaseURL(service: .production))
```

**A staging endpoint now says so:**

```swift
let staging = try SecureBaseURL(URL(string: "https://api-dev.differentrequests.com")!)
let client = DifferentRequestsClient(appKey: "dr_…", baseURL: staging)
```

**And a plaintext one throws where it is written:**

```swift
try SecureBaseURL(URL(string: "http://localhost:8080")!)
// throws DifferentRequestsError(invalidBaseURL: http://localhost:8080)
```

The error already existed for a URL this client will not use; nothing new was invented for it.

**The scheme is compared lowercased**, so `HTTPS://` is accepted rather than refused on spelling.

## Expectations

### It works

| Given | When | Then |
|---|---|---|
| `SecureBaseURL(service: .production)` named | `init(appKey:baseURL:)` | Production, and no `try` at the call site |
| An `https` URL | `SecureBaseURL(_:)` | Wrapped, and the client dials it |
| `HTTPS://` in capitals | `SecureBaseURL(_:)` | Accepted — the scheme is compared lowercased |
| The example app with no `DIFFERENT_REQUESTS_BASE_URL` | It launches | Production |
| The example app with an https one | It launches | That endpoint |

### It refuses

| Given | When | Then |
|---|---|---|
| `http://…` | `SecureBaseURL(_:)` | Throws `invalidBaseURL`, naming that URL. **Nothing is sent** |
| `ftp://…`, or any other scheme | `SecureBaseURL(_:)` | Same |
| A URL with no scheme | `SecureBaseURL(_:)` | Same |
| A `SecureBaseURL` whose `url` was set by hand to `http://…` | Any call | `dialable()` throws `invalidBaseURL` before the request is built. **Nothing is sent** |
| The example app with a non-https `DIFFERENT_REQUESTS_BASE_URL` | It launches | Stops, naming the variable and the value. **It does not fall back to production** — somebody who named a staging endpoint and silently got production would be reading the wrong board and believing it was theirs |

## The path

```
  developer's code
    │  try SecureBaseURL(url)
    ▼
  SecureBaseURL.init(_:) ............................ SecureBaseURL+Https.swift
    ├─ url.scheme?.lowercased() != "https" ──▶ throw DifferentRequestsError(invalidBaseURL:)
    │                                           nothing built, nothing sent
    └─ https ─────────────────────────────────▶ SecureBaseURL
                                                     │
    ┌────────────────────────────────────────────────┘
    ▼
  DifferentRequestsClient.init(appKey:baseURL:)
       assigns baseURL and nothing else
    │
    ▼
  DifferentRequestsClient.perform(_:query:body:)
    └─ baseURL.dialable() ........................... SecureBaseURL+Https.swift
         ├─ not an https URL ──▶ throw DifferentRequestsError(invalidBaseURL:), nothing sent
         └─ https ────────────▶ the URL the request is built on

  SecureBaseURL(service: .production) ............... SecureBaseURL+Https.swift
       init(literal:) on a known https literal, so passing it needs no try
```

## The screen

```
None. This SDK draws screens, but this is an initializer that refuses.

What a developer sees is a compiler error where they used to pass a URL:

    cannot convert value of type 'URL' to expected argument type 'SecureBaseURL'

and, once they wrap it, the throw at the line that names the address rather
than a request that quietly worked.
```

## Platform differences

None. It is a scheme comparison.

## Which tests walk the chart

There is no test target in this package. Walked by building the example app against an `http`
endpoint and confirming it stops naming the variable, then against the development `https` endpoint
and confirming it runs.

Closes #122.
