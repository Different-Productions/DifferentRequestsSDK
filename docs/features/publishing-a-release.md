# Publishing a release

## What it is

This repository is private. The package a developer adds to Xcode is its **public copy**,
`Different-Productions/DifferentRequestsSDK`, and that copy only ever receives releases.

Pushing a release tag here — `0.9.0` — publishes **one commit** to the public copy: the tag's files,
without `.github`, on top of the previous public release, tagged `0.9.0`. Work in progress, issues,
pull requests and commit history stay private.

**A published tag never moves.** SwiftPM records the commit behind every tag it resolves and refuses a
tag that later points somewhere else, so the publisher refuses a version the public copy already has,
and the public copy's rules refuse tag updates and deletions from anyone.

The contract package works the same way (`differentrequests-proto-private` → `differentrequests-proto`),
through the same action, which lives here at `.github/actions/publish-release-copy` and is shared with
the organization's repositories. This SDK keeps depending on the contract's public copy by URL; no
source is copied between the two.

## Surfaces

| Surface | Ships this? |
|---|---|
| This private repository | **Yes** — `.github/workflows/publish-release-copy.yml`, and the action `.github/actions/publish-release-copy/` (`action.yml`, `publish-release-copy.sh`), whose Actions access is set to the organization |
| The contract's private repository | **Yes** — its own `publish-release-copy.yml` uses this action at `master` |
| The public copy `DifferentRequestsSDK` | **Yes** — receives release commits and tags; issues, wiki and projects are off; rulesets let only the release key create or change branches and tags |
| Xcode / SwiftPM in a developer's app | **Yes** — `https://github.com/Different-Productions/DifferentRequestsSDK.git`, unchanged; every tag published before 2026-09-11 points at the same commit it always did |
| The SDK library | **None** — no code changes |
| The example app | **None** |
| The server | **None** — it resolves the contract's public copy, as before |
| The console | **None** |

## How to find it, trigger it, and what happens

**Release.** Tag the commit and push the tag to this repository:

```sh
git tag -a 0.9.0 -m 0.9.0
git push origin 0.9.0
```

The tag push starts **Publish release copy** on the organization's Mac. It clones the public copy,
refuses if `0.9.0` is already there, replaces the tree with `git archive 0.9.0` minus `.github`,
commits `Release 0.9.0` as `github-actions[bot]`, tags it, and pushes the branch and the tag
atomically with the write key in `RELEASE_COPY_DEPLOY_KEY`. It then reads the tag back from the
public copy and fails unless it points at the commit it made.

**Rehearse.** Actions → Publish release copy → Run workflow, with a version and **publish**
unchecked. It builds the same commit and prints it; nothing is pushed.

## Expectations

**Positive**

| Given | When | Then |
|---|---|---|
| A new version tag `X.Y.Z` pushed here | the workflow runs | One commit `Release X.Y.Z` on the public copy's `master`, parented on the previous release, and tag `X.Y.Z` on it |
| The published tag | a developer resolves `exact: "X.Y.Z"` | It resolves over HTTPS with no credentials |
| A rehearsal (`publish` unchecked) | the workflow runs | `Release X.Y.Z of DifferentRequestsSDK: <commit> on top of <previous> (master)` and `Rehearsal: nothing was pushed.` |
| Any tag published before 2026-09-11 | resolved again | The same commit as before the repositories moved; no fingerprint error |
| The public copy after a release | its tree is read | Exactly the tag's tracked files minus `.github`, including files `.gitignore` names, such as `Package.resolved` |
| The first release after the move | published | It also deletes `.github/workflows/swift.yml`, the last workflow file on the public copy, so nothing runs there and no public workflow can reach the organization's runners |

**Negative**

| Given | When | Then | What is shown |
|---|---|---|---|
| A version already on the public copy | publish | Refused, nothing pushed | `X.Y.Z is already published on DifferentRequestsSDK. A published tag never moves; release a new version instead.` |
| A version that is not three numbers | dispatch | Refused | `v1 is not a release version. Release tags are three numbers, like 0.9.0.` |
| A version with no tag here | dispatch | Refused | `There is no tag X.Y.Z in this repository.` |
| Publishing without the key | publish | Refused before anything is cloned | `Publishing needs the write key for the public copy in DEPLOY_KEY.` |
| The script run by hand without `PUBLISH` | run | Refused | `Set PUBLISH to true to push, or false to rehearse.` |
| Anyone, an organization admin included, creating a branch on the public copy | `git push` | Refused by the ruleset **Only the release publisher writes branches**; nothing is created | `GH013: Repository rule violations found for refs/heads/<branch>.` then `Cannot create ref due to creations being restricted.` |
| Anyone, an organization admin included, creating a tag on the public copy | `git push` | Refused by the ruleset **Release tags are made once and never move**; nothing is created | `GH013: Repository rule violations found for refs/tags/<tag>.` then `Cannot create ref due to creations being restricted.` |
| Anyone updating `master`, or moving or deleting a public tag | `git push`, `git push --force`, `git push --delete` | Refused by the update, non-fast-forward and deletion rules of the same rulesets | Not walked: a rule that failed would move or delete a real release |
| The push lands but the tag reads back elsewhere | after pushing | The run fails | `DifferentRequestsSDK does not show X.Y.Z at <commit> after the push.` |

## The path

```
git push origin X.Y.Z                         (this private repository)
        │
        ▼
.github/workflows/publish-release-copy.yml     on: push tags [0-9]+.[0-9]+.[0-9]+
        │  runs-on [self-hosted, macOS, ARM64], concurrency sdk-release-copy
        │  checkout, fetch-depth 0
        ▼
.github/actions/publish-release-copy/action.yml   @master, public-copy DifferentRequestsSDK
        │
        ▼
.github/actions/publish-release-copy/publish-release-copy.sh
        │
        ├── VERSION, PUBLIC_COPY or PUBLISH empty ► error, exit 1
        ├── VERSION not N.N.N ───────────────► error, exit 1
        ├── no refs/tags/VERSION here ────────► error, exit 1
        ├── PUBLISH true, no DEPLOY_KEY ──────► error, exit 1
        │
        ▼
git clone https://github.com/Different-Productions/DifferentRequestsSDK.git
        │
        ├── tag VERSION already there ────────► error, exit 1   (tags never move)
        │
        ▼
git rm -r .  →  git archive VERSION | tar -x  →  rm -rf .github  →  git add --all --force
        │
        ▼
commit "Release VERSION" (github-actions[bot])  →  tag -a VERSION
        │
        ├── PUBLISH != true ──────────────────► print, exit 0   (rehearsal)
        │
        ▼
ssh key from RELEASE_COPY_DEPLOY_KEY  →  git push --atomic master refs/tags/VERSION
        │                                        │
        │                              public copy rulesets:
        │                              branches and tags writable only by the deploy key
        ▼
git ls-remote refs/tags/VERSION^{}  ── not the new commit ──► error, exit 1
        │
        ▼
"Published VERSION to DifferentRequestsSDK at <commit>."
```

## The screen

There is no app screen. What a person sees is the Actions run and the public copy.

```
 Actions ▸ Publish release copy ▸ Run workflow            (manual rehearsal)
 ┌──────────────────────────────────────────────────────────┐
 │ Use workflow from   [ master ▾ ]                          │
 │ A release tag that exists in this repository.             │
 │ [ 0.9.0                                   ]  ← required   │
 │ [ ] Push to the public copy. Unchecked prints what…       │  ← unchecked = rehearsal
 │                                   ( Run workflow )        │
 └──────────────────────────────────────────────────────────┘

 Run log, rehearsal                  (real output; tag 9.9.9 existed only in a local rehearsal)
   Release 9.9.9 of DifferentRequestsSDK: 81c970126ed6… on top of a5648906bc6f… (master)
    1 file changed, 65 deletions(-)          ← the old .github/workflows/swift.yml going away
   Rehearsal: nothing was pushed.

 Run log, refused                    (real output: Run workflow, 0.8.0, publish unchecked)
   Download action repository 'Different-Productions/DifferentRequestsSDK-private@master'
   Run bash "$GITHUB_ACTION_PATH/publish-release-copy.sh"
   ##[error]0.8.0 is already published on DifferentRequestsSDK. A published tag never moves;
   release a new version instead.                                        ← run fails, red X

 github.com/Different-Productions/DifferentRequestsSDK        (public copy)
 ┌──────────────────────────────────────────────────────────┐
 │ master · Release 0.9.0 · github-actions[bot]              │
 │ Tags: 0.9.0  0.8.0  …                                     │
 │ Issues: off   Wiki: off   Projects: off                   │
 └──────────────────────────────────────────────────────────┘
 In flight: the run is queued behind any other run on the Mac (queue: max); a second
 tag waits rather than racing the first.
```

## Platform differences

**None.** Releases are source; SwiftPM resolves the same tag for iOS and macOS apps.

The one split is **where it runs**: the private repository's workflows run on the organization's
Mac, and the public copy runs nothing — its tree carries no `.github`, and the organization's runner
group refuses public repositories.

## What walks this chart

There is no test target (Different-Productions/DifferentRequests-Server#144).

Walked on 2026-09-11 when the repositories moved (Different-Productions/DifferentRequests-Server#190):

1. Before the move: `master` and all 28 tags recorded from the public repository.
2. After the move: the new public copy read anonymously over HTTPS — `master` and all 28 tags at the
   same commits.
3. A new package on a machine with an empty home directory, no Git credentials, resolved
   `DifferentRequestsSDK` `exact: "0.8.0"` → `differentrequests-proto` 0.23.0 → `swift-protobuf`
   1.38.1.
4. The server's own `swift package resolve`, with this Mac's existing SwiftPM fingerprints, succeeded
   and left `Package.resolved` unchanged.
5. `publish-release-copy.sh` run against a bare clone of the public copy and a clone of this
   repository carrying a local tag `9.9.9`, through `PUBLIC_REMOTE_OVERRIDE`:
   - rehearsal printed the release and pushed nothing;
   - publish pushed one commit on top of the public `master`, and `9.9.9` read back at that commit;
   - publishing `9.9.9` again, `v1`, a tag that does not exist, no `PUBLISH`, and no `DEPLOY_KEY`
     against GitHub each exited 1 with the text in the table above;
   - the published tree matched `9.9.9` file for file, minus `.github`, `Package.resolved` included;
   - `0.8.0` was unchanged, and GitHub never received `9.9.9`.
6. **Run workflow** on `master` with `0.8.0` and *publish* unchecked ran on the organization's Mac.
   It downloaded the action and refused with the text in the table above.
7. The owner's own credentials, as an organization admin, pushed the already-public `master` commit
   to a new branch and to a new tag on the public copy. GitHub refused both with the text in the
   table above, and neither ref existed afterwards.
8. Not walked yet: the first real release through the workflow with the deploy key. Updating `master`
   and moving or deleting a tag were not tried: a rule that failed would damage a real release.
