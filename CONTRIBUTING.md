# Contributing to Momento

Thanks for your interest in Momento. This document describes how the repository
is developed and what is expected from a change before it is merged.

## Project constraints

Momento is deliberately **local-first**. Before proposing a change, note that the
project intentionally has:

- no user accounts and no backend,
- no analytics or third-party SDKs,
- no copies of photo files — only references to assets in Apple Photos.

Changes that break these constraints are unlikely to be accepted. Everything else
is open for discussion.

## Development setup

### Prerequisites

- macOS with **Xcode 26** or newer (the app targets iOS 26)
- An iOS 26 Simulator, or a physical device with a signing team
- Optional: [XcodeGen](https://github.com/yonaskolb/XcodeGen) and
  [SwiftLint](https://github.com/realm/SwiftLint) (`brew install xcodegen swiftlint`)

### Getting started

```bash
git clone git@github.com:Selimo100/momento.git
cd momento
open Momento.xcodeproj
```

Select the `Momento` scheme and run it on an iOS 26 Simulator. No dependency
installation step is required — the app uses only Apple frameworks.

To build from the command line:

```bash
xcodebuild build \
  -project Momento.xcodeproj \
  -scheme Momento \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO
```

### The Xcode project and `project.yml`

`project.yml` is the XcodeGen specification and is the readable description of
the target, build settings, and deployment target. The generated
`Momento.xcodeproj` is **also committed**, because Xcode Cloud and CI build from
it directly.

Because of that, do not run `xcodegen generate` casually: regenerating the
project resets locally configured signing settings. If you change build settings,
change them in `project.yml` and in Xcode, and describe the change in your pull
request.

### Linting

```bash
swiftlint            # uses .swiftlint.yml
swiftlint --fix      # applies the autocorrectable rules
```

Warnings are tolerated; SwiftLint errors fail CI. The thresholds in
`.swiftlint.yml` are tuned for SwiftUI view bodies, which are naturally long.

### Tests

The project currently has no automated test target. If you add logic that is
testable without UIKit — date maths, completion scoring, capsule state — adding a
unit test target alongside it is very welcome. See
[docs/architecture.md](docs/architecture.md) for where such logic lives.

## Branching

Work happens on short-lived branches off `main`:

```text
feature/<description>
fix/<description>
docs/<description>
refactor/<description>
chore/<description>
ci/<description>
```

Example: `feature/time-capsule-reminders`.

## Commit messages

The repository follows a lightweight [Conventional Commits](https://www.conventionalcommits.org/)
style for new commits:

```text
feat: add reminder dates to time capsules
fix: keep private moments hidden after backgrounding
docs: document the export flow
refactor: move capsule scheduling into TimeCapsuleService
test: add completion scoring tests
chore: update app icon assets
ci: run SwiftLint on pull requests
```

Keep the subject in the imperative mood and under ~72 characters. Git history is
not rewritten; the convention applies going forward.

## Coding standards

- Swift 6, SwiftUI-first. Follow the
  [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/).
- Respect the existing layering: `Views` → `ViewModels`/`Services` → `Models`.
  Views should not talk to `PHPhotoLibrary`, `LAContext`, or `UNUserNotificationCenter`
  directly; that is what the services in `Momento/Services` are for.
- Keep components in `Momento/Components` presentational and reusable.
- Comment only what the code cannot say itself: migration constraints, Apple API
  quirks, and non-obvious product decisions.
- SwiftData model changes must stay lightweight-migration safe. New stored
  properties must be optional or carry a default value, otherwise existing users
  lose their data on upgrade.
- Any new capability that touches user data needs a matching usage description in
  `Momento/App/Info.plist`.

## Pull requests

1. Open an issue first for anything larger than a small fix.
2. Branch from `main`, keep the change focused.
3. Make sure the app builds and SwiftLint is clean.
4. Fill in the pull request template, including how you tested on device or simulator.
5. Add an entry under `Unreleased` in [CHANGELOG.md](CHANGELOG.md).

## Reporting bugs

Use the [bug report form](.github/ISSUE_TEMPLATE/bug_report.yml). Include the
device, iOS version, and steps to reproduce. Never attach personal photos or
contact data — a screen recording with placeholder content is enough.

Security issues follow a different path: see [SECURITY.md](SECURITY.md).

## Recommended repository settings

These are settings for the GitHub repository itself rather than the codebase, and
they describe how `main` is intended to be protected:

- require a pull request before merging into `main`
- require the `Build (iOS Simulator)` and `SwiftLint` status checks to pass
- require conversation resolution before merging
- block force pushes and branch deletion on `main`
- automatically delete head branches after merge
