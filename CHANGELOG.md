# Changelog

All notable changes to Momento are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
for its `MARKETING_VERSION`.

## [Unreleased]

### Added

- Repository documentation and automation: contribution guide, security policy,
  architecture documentation, issue forms, pull request template, Dependabot
  configuration, and a GitHub Actions CI workflow that builds the app and runs
  SwiftLint.
- Shared `Momento` Xcode scheme, so the project can be built by CI and by any
  contributor without recreating it locally.
- SwiftLint configuration tuned for SwiftUI (`.swiftlint.yml`) and an
  `.editorconfig` for consistent whitespace.

### Changed

- Rewrote `README.md` around the app's actual feature set and architecture.
- Renamed a number of single-letter local variables and applied SwiftLint's
  autocorrectable rules. No behaviour changes.

### Removed

- Local assistant state (`.claude/memory/`, `skills-lock.json`) is no longer
  tracked in version control.

<!--
Release sections are added here as versions ship, newest first, e.g.

## [1.0.0] - YYYY-MM-DD
-->
