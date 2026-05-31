---
id: "0004"
slug: update-privacy-app-review-metadata
branch: incant/0004-update-privacy-app-review-metadata
title: Update Privacy App Review Metadata
stage: spec
status: awaiting-approval
created: 2026-05-31
commit: b2e21e3f
updated: 2026-05-31
---

# Update Privacy App Review Metadata

## Goal
Make the production app's App Store, privacy, and permission metadata free of stale Boolder/fork references and safe for Austrian.rocks pre-release App Review.

## Context & codebase fit
The app is an iOS SwiftUI/UIKit project with release metadata spread across Xcode project settings, plist files, and a small brand configuration surface:

- `AustrianRocks/Config/BrandConfig.swift` already centralizes brand values and contains a string placeholder for the future App Store ID, but the Discover support section still hardcodes Boolder's App Store review app ID `1506614493` in `AustrianRocks/UI/Discover/DiscoverView.swift`.
- Production metadata lives in `AustrianRocks/Info.plist`; development metadata lives in `Dev-Info.plist`; localized permission strings live in `AustrianRocks/en.lproj/InfoPlist.strings` and `AustrianRocks/de.lproj/InfoPlist.strings`.
- The project includes `PrivacyInfo.xcprivacy` in resources and currently declares UserDefaults access with reason `CA92.1`.
- Location permission strings are required by the map flow: `MapboxViewController` imports `CoreLocation`, configures the Mapbox location puck, and centers on `mapView.location.latestLocation`.
- Camera permission strings are present, but scouting did not find live camera/photo-capture API usage; image loading appears focused on bundled/downloaded topo photos.
- The dev target bundle identifier in `AustrianRocks.xcodeproj/project.pbxproj` still uses the fork author's namespace: `com.nicolasmondollot.austrian-rocks-dev`; production already uses `com.maxblazek.austrian-rocks`.
- `LICENSE.md` still only lists `Copyright (c) 2023 Boolder`. The original license notice should remain, and Austrian.rocks should be added rather than replacing the fork's original copyright notice.

## Requirements
1. Replace the hardcoded Boolder App Store review ID in `DiscoverView` with `BrandConfig.AppStore` so no App Store URL in source points at app ID `1506614493`.
2. Represent the App Store app ID as an absent/not-yet-published value in `BrandConfig` until Austrian.rocks has its own App Store ID.
3. Hide or otherwise omit the “Rate app” support action when no App Store app ID is configured; when configured, the action must generate the write-review URL from that configured Austrian.rocks ID.
4. Remove unused camera permission declarations from production, development, and localized plist metadata unless implementation discovers active camera/photo-capture code before editing.
5. Preserve required location permission metadata for map location features, including precise-location temporary usage text where applicable.
6. Keep `PrivacyInfo.xcprivacy` accurate for current code: UserDefaults access remains declared if still used by the app or dependencies, and no unused privacy accessed API category is added.
7. Change development bundle identifiers from `com.nicolasmondollot.austrian-rocks-dev` to `com.maxblazek.austrian-rocks-dev`; production bundle identifiers must remain `com.maxblazek.austrian-rocks`.
8. Add an Austrian.rocks copyright line to `LICENSE.md` while preserving the original Boolder MIT copyright notice.
9. After implementation, repository search for App Store/permission cleanup terms must show no stale hardcoded Boolder App Store ID, no unused camera permission declaration, and no dev bundle ID under `com.nicolasmondollot`.

## In scope / Out of scope
**In scope:**
- App Store review-link configuration and behavior in the existing Discover support UI.
- `BrandConfig.AppStore` changes needed to represent an unreleased app safely.
- Production/dev plist and localized permission-string cleanup for camera/location usage descriptions.
- Privacy manifest sanity check and minimal correction if the current manifest is inaccurate.
- Dev bundle identifier cleanup from the fork author's namespace to the current namespace.
- Adding Austrian.rocks to the existing MIT license notice without deleting the original fork notice.

**Out of scope:**
- Creating an App Store Connect listing or choosing final App Store metadata text — reason: those values do not exist yet and live outside this repository.
- Changing the production bundle identifier — reason: it already uses the current namespace and changing it would affect release identity.
- Repo-wide source-header attribution cleanup for “Originally created for Boolder” / “Nicolas Mondollot” comments — reason: this item is focused on App Store, privacy, permissions, and release metadata, not broad provenance cleanup.
- Adding new privacy policy pages or website content — reason: website/content release work is separate from iOS repository metadata cleanup.
- Adding new user-facing permission flows — reason: this item removes unused metadata and keeps existing required location behavior unchanged.

## Approach
Use the existing brand-configuration pattern rather than adding another constants surface. Make `BrandConfig.AppStore.appID` optional or equivalently absent when unreleased, then have `DiscoverView` conditionally render the rate/review row only when an app ID exists. Remove camera usage descriptions from plist/localized metadata if no live camera API usage is found during implementation, keep location usage descriptions intact, update dev bundle identifiers in the Xcode project, and add Austrian.rocks to `LICENSE.md` without altering the original Boolder notice.

Rejected alternatives:
- Leaving the Boolder App Store ID until release was rejected because it can send users/App Review to the wrong app.
- Keeping a textual placeholder in runtime URL generation was rejected because placeholders can accidentally ship.
- Replacing the original Boolder license notice was rejected because the fork's original copyright notice should be preserved.

## Considerations
### Config vs code
The App Store app ID is configuration and belongs in `AustrianRocks/Config/BrandConfig.swift` under `BrandConfig.AppStore`. `DiscoverView` should consume that value instead of hardcoding an app ID. The default is an absent/nil value because Austrian.rocks has not been published yet; this prevents accidental placeholder or Boolder links from shipping.

Permission usage descriptions and privacy manifest declarations are platform metadata rather than app runtime configuration, so they should remain in plist/privacy manifest files where iOS and App Review expect them.

### Security
No secrets should be added or moved as part of this work. Mapbox token handling remains outside scope and must continue to avoid committed tokens. The main trust boundary is external URL opening: the review URL must be constructed only from the configured App Store ID, and no untrusted user input should be interpolated into it. Removing unused camera permission metadata reduces the app's sensitive-permission surface. Location permission metadata remains because current-location map behavior requires it; no new location collection or transmission is introduced by this item.

### Testability
Verification is mostly static and build-level because this item changes app metadata and simple UI configuration:
- Use repository searches to prove stale values are absent: Boolder app ID `1506614493`, `NSCameraUsageDescription`, and `com.nicolasmondollot.austrian-rocks-dev` should not remain in active metadata/code after implementation.
- Build the app with Xcode tooling to catch Swift and project-file errors. Preferred command: `xcodebuild -project AustrianRocks.xcodeproj -scheme AustrianRocks -configuration Debug -destination 'generic/platform=iOS Simulator' build` or the closest available scheme/destination in the local project.
- Manually inspect the Discover support section or relevant SwiftUI condition to confirm the rate row is hidden when `BrandConfig.AppStore.appID` is absent.
- Validate plist/privacy files with `plutil -lint` where applicable.

No new test seam is needed beyond keeping App Store ID access centralized in `BrandConfig` so behavior can be reasoned about and later tested by changing one value.

### Code documentation
This item should not add broad inline comments. A short comment in `BrandConfig.AppStore` is useful to explain that the app ID is intentionally absent until App Store release and that setting it enables the rate/review link. Other changes are metadata edits or straightforward UI conditional rendering and do not need additional comments.

## Acceptance criteria
- [ ] `AustrianRocks/UI/Discover/DiscoverView.swift` contains no hardcoded `1506614493` and builds its review URL from `BrandConfig.AppStore` only when an app ID is configured.
- [ ] With the default unreleased configuration, the “Rate app” support row is not shown or cannot open an App Store URL.
- [ ] `BrandConfig.AppStore` represents the missing App Store ID without a shippable placeholder string.
- [ ] Active production/dev plist and localized InfoPlist strings contain no `NSCameraUsageDescription` unless implementation finds live camera usage and documents why it remains.
- [ ] Location usage descriptions remain present for production and development targets.
- [ ] `PrivacyInfo.xcprivacy` remains valid XML and accurately declares the currently needed accessed API categories.
- [ ] Dev target bundle identifiers are `com.maxblazek.austrian-rocks-dev`; production bundle identifiers remain `com.maxblazek.austrian-rocks`.
- [ ] `LICENSE.md` preserves the Boolder MIT copyright notice and adds an Austrian.rocks copyright notice.
- [ ] Static verification commands/searches and an Xcode build or documented build-equivalent pass before review.

## Risks & open questions
- App Store Connect privacy-label answers are not stored in this repository and are not finalized by this item; this work only ensures repository metadata does not contradict current app behavior.
- If camera usage exists through an indirect or not-yet-scouted code path, the implementation must keep the permission text and document the path found.
- Build scheme names/destinations may differ locally; the plan should verify the exact available Xcode build command before using it as a gate.
