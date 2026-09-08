# Refusing a plaintext endpoint

## What it is

This SDK will not dial `http`.

Every call it makes carries `X-App-Key`, and every call made for a person carries their session
token. Over plain `http` both cross the wire in the clear — and nothing about the request looks
wrong. **It works, which is the problem.**

The built-in production URL is `https`, so this only ever fires on an address a developer supplied
themselves: a staging endpoint, a local server, or a typo.

**Refused where it is written, not where it is dialled.** `SecureBaseURL` is a type rather than a
check inside the client, so the failure lands on the line that wrote the URL and names it. A check
on the first call would report a broken request instead of a wrong address, and by then a key has
already been sent.

## Surfaces

| Surface | Ships this? |
|---|---|
| `DifferentRequestsClient` | **Yes** — `init(appKey:baseURL:session:)` and `make(appKey:baseURL:)` take `SecureBaseURL` |
| `SecureBaseURL` | **Yes** — `init(_:) throws`, and `.production` |
| `make(appKey:)` | **Unchanged and still non-throwing.** Production is known `https`, so it is built through the trusted path and cannot fail |
| The example app | Reads `DIFFERENT_REQUESTS_BASE_URL` and refuses a non-https one loudly |
| The server | **None.** This is a client-side refusal; the server never sees the call it prevents |

## How to find it, trigger it, and what happens

**The ordinary case is untouched.**

```swift
let client = DifferentRequestsClient.make(appKey: "dr_…")
```

**A staging endpoint now says so:**

```swift
let staging = try SecureBaseURL(URL(string: "https://api-dev.differentrequests.com")!)
let client = DifferentRequestsClient.make(appKey: "dr_…", baseURL: staging)
```

**And a plaintext one throws where it is written:**

```swift
try SecureBaseURL(URL(string: "http://localhost:8080")!)
// throws DifferentRequestsError.invalidBaseURL(http://localhost:8080)
```

The error already existed for a URL this client will not use; nothing new was invented for it.

**The scheme is compared lowercased**, so `HTTPS://` is accepted rather than refused on spelling.

## Expectations

### It works

| Given | When | Then |
|---|---|---|
| No base URL named | `make(appKey:)` | Production, and no `try` at the call site |
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
| The example app with a non-https `DIFFERENT_REQUESTS_BASE_URL` | It launches | Stops, naming the variable and the value. **It does not fall back to production** — somebody who named a staging endpoint and silently got production would be reading the wrong board and believing it was theirs |

## The path

```
  developer's code
    │  try SecureBaseURL(url)
    ▼
  SecureBaseURL.init(_:) ............................ SecureBaseURL.swift
    ├─ url.scheme?.lowercased() != "https" ──▶ throw DifferentRequestsError.invalidBaseURL(url)
    │                                           nothing built, nothing sent
    └─ https ─────────────────────────────────▶ SecureBaseURL
                                                     │
    ┌────────────────────────────────────────────────┘
    ▼
  DifferentRequestsClient.init(appKey:baseURL:session:)
       assigns baseURL.url and nothing else — the check already happened

  .production ....................................... SecureBaseURL.swift
       built through the private trusted path from DifferentRequestsClient.productionBaseURL,
       which is a known https literal, so make(appKey:) needs no try
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
