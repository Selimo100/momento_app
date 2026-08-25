## Summary

<!-- What does this change do, and why? Link any related issue with "Closes #123". -->

## Changes

<!-- Bullet the notable changes. Mention new files, models, or services. -->

-

## Testing

<!-- How did you verify this? e.g. "Built and ran on iPhone 17 Pro simulator, created a
     time capsule, confirmed the unlock notification fires." -->

- Device / simulator:
- Steps performed:

## Checklist

- [ ] The app builds (`xcodebuild build -project Momento.xcodeproj -scheme Momento -destination 'generic/platform=iOS Simulator'`)
- [ ] `swiftlint` reports no new violations
- [ ] Changes to the SwiftData models are lightweight-migration safe (new properties are optional or have defaults)
- [ ] New `Info.plist` usage descriptions were added for any new permission
- [ ] Documentation (`README.md` / `docs/`) updated where behaviour changed
- [ ] `CHANGELOG.md` updated under `Unreleased`
- [ ] No secrets, signing assets, or personal data were committed
