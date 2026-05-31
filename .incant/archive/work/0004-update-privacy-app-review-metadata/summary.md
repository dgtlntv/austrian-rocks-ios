---
id: "0004"
slug: update-privacy-app-review-metadata
stage: archived
completed: 2026-05-31
commit: c5df4a6c
---

# Update Privacy App Review Metadata — summary

## What was built
- Centralized the App Store review link behind `BrandConfig.AppStore`, with `appID` intentionally absent (`nil`) until Austrian.rocks has a real App Store ID.
- Hid the Discover “Rate app” support row when no App Store review URL is configured, preventing the app from shipping a Boolder review link or placeholder App Store URL.
- Removed unused camera permission metadata from production, development, and localized InfoPlist metadata while preserving required location and precise-location permission strings.
- Verified the privacy manifest remains valid and continues to declare only UserDefaults access with reason `CA92.1` for current app usage.
- Updated development bundle identifiers to `com.maxblazek.austrian-rocks-dev` while preserving production `com.maxblazek.austrian-rocks` identifiers.
- Added `Copyright (c) 2026 Austrian.rocks` to `LICENSE.md` without removing the original Boolder MIT notice.

## Deviations from spec
- None. The implementation followed the approved spec and plan.

## Key decisions
- The App Store ID stays optional and defaults to `nil` until Austrian.rocks is published; setting it later enables the rate/review link from one configuration point.
- The review URL is constructed only from the configured App Store ID and is not rendered/opened when that ID is absent.
- Camera usage descriptions were removed after implementation-time searches did not find active camera/photo-capture usage.
- Location permission metadata remains because map/current-location behavior still requires it.
- UserDefaults remains in `PrivacyInfo.xcprivacy` because `AustrianRocks/UI/Map/MapContainerView.swift` still uses `UserDefaults.standard`.

## Verification
- `xcodebuild -list -project AustrianRocks.xcodeproj` passed and listed `AustrianRocks`, `AustrianRocks dev`, and `MapboxMaps` schemes.
- Stale-value searches found no active `1506614493`, `NSCameraUsageDescription`, or `com.nicolasmondollot.austrian-rocks-dev` matches in source/metadata.
- `plutil -lint AustrianRocks/Info.plist Dev-Info.plist PrivacyInfo.xcprivacy` passed.
- `xcodebuild -project AustrianRocks.xcodeproj -scheme AustrianRocks -configuration Debug -destination 'generic/platform=iOS Simulator' build` passed with `** BUILD SUCCEEDED **`.
- Final review found no blocker, major, minor, or nit findings and gave a release verdict of **Yes**.

## Links
- Branch: `incant/0004-update-privacy-app-review-metadata`
- Commits:
  - `6bfb9bf2` — `incant 0004: spec`
  - `3d476b2a` — `incant 0004: plan`
  - `c0878fc2` — `incant 0004-P1: app store review configuration`
  - `6460b730` — `incant 0004-P2: update privacy metadata`
  - `c5df4a6c` — `incant 0004-P3: final verification`

## Sessions
- `019e7e91-c30d-76fc-9d26-7a339a80aa84`
- `019e7e9d-8481-7428-815e-8da4f1a8d16c`
- `019e7ea1-f6fd-720f-9437-89c983a8a48a`
- `019e7ea8-c900-7307-bf7b-7e4ed42a9a77`
- `019e7eab-ad6b-73a1-8095-72cebf6e128e`
- `019e7eae-e6d0-760f-8f0b-2557330454f3`
- `019e7eb2-d36d-75dd-bd2c-e05dfb83dcd5`
- `019e7eb4-f44f-72eb-98b0-cadb6af0f508`

## Follow-ups
- None.
