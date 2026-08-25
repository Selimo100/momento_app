# Security Policy

## Scope

Momento is a local-first iOS app. It has no backend, no user accounts, and sends
no data to external servers. The security surface is therefore limited to what
happens on the device:

- access to the Apple Photos library (selection and album export)
- access to Contacts when tagging people in a moment
- local biometric authentication (Face ID / Touch ID) guarding Private Moments
- local notifications used by Time Capsules
- data stored on device by SwiftData

Findings in any of these areas — for example a way to view Private Moments
without authenticating, or an unintended write to the user's photo library — are
in scope.

## Supported versions

The project is pre-1.0 in the sense that only the latest state of the `main`
branch is maintained. Fixes are made on `main` and shipped in the next release;
older builds do not receive backported patches.

| Version | Supported |
| ------- | --------- |
| `main` (latest) | ✅ |
| Older TestFlight / App Store builds | ❌ |

## Reporting a vulnerability

**Please do not open a public issue for a security problem.**

Report it privately through GitHub's Private Vulnerability Reporting:

1. Go to the repository's **Security** tab.
2. Choose **Report a vulnerability**
   ([direct link](https://github.com/Selimo100/momento/security/advisories/new)).
3. Describe the issue, the affected iOS version and build, and the steps to
   reproduce it.

If private reporting is unavailable to you, contact the repository owner
privately through their GitHub profile instead of filing a public issue.

Please include a proof of concept where possible, and avoid attaching real
personal photos or contact data when demonstrating an issue.

## What to expect

The project is maintained by a single developer, so responses are best-effort:
an acknowledgement of the report, an assessment of impact, and — once a fix is
available on `main` — public credit in the release notes if you would like it.

## Handling of secrets

The repository contains no credentials, API keys, or signing assets. Signing is
configured locally per developer and must never be committed. If you believe
something sensitive has been committed, report it privately using the process
above rather than opening an issue.
