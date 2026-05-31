---
id: "0004"
slug: update-privacy-app-review-metadata
branch: incant/0004-update-privacy-app-review-metadata
title: Update Privacy App Review Metadata
stage: review
status: pending-review
created: 2026-05-31
commit: 6bfb9bf2
updated: 2026-05-31
---

# Update Privacy App Review Metadata — plan

## Status
- Phase: 0004-P2 (of 3) · stage: review
- Branch: incant/0004-update-privacy-app-review-metadata
- Next: run `/incant:review 0004` for the Phase 0004-P2 gate before continuing to Phase 0004-P3.
- Blockers: none
- Completed this session:
  - 0004-P2 removed unused camera permission metadata, fixed the dev precise-location plist structure, updated dev bundle identifiers, preserved the privacy manifest, and added the Austrian.rocks license notice.
- Quality gate evidence (2026-05-31):
  - `rg -n "UIImagePicker|AVCapture|NSCameraUsageDescription|PHPhoto|PhotosUI|camera|Camera" AustrianRocks Dev-Info.plist` found no live photo/camera capture APIs; matches were permission metadata scheduled for removal and Mapbox map camera APIs only.
  - `plutil -lint AustrianRocks/Info.plist Dev-Info.plist PrivacyInfo.xcprivacy && ! rg -n "NSCameraUsageDescription|com\\.nicolasmondollot\\.austrian-rocks-dev" AustrianRocks Dev-Info.plist AustrianRocks.xcodeproj/project.pbxproj && rg -n "NSLocationWhenInUseUsageDescription|NSLocationAlwaysAndWhenInUseUsageDescription|LocationAccuracyAuthorizationDescription|com\\.maxblazek\\.austrian-rocks|Copyright \\(c\\)" AustrianRocks/Info.plist Dev-Info.plist AustrianRocks.xcodeproj/project.pbxproj LICENSE.md` passed; plist/privacy files linted OK, stale camera/fork bundle-ID search returned no matches, and evidence showed preserved location metadata, `com.maxblazek` bundle IDs, and both license copyright notices.
- Decisions:
  - `BrandConfig.AppStore.appID` will be optional and default to `nil` until Austrian.rocks has a real App Store ID.
  - The Discover support section will render the rate/review row only when `BrandConfig.AppStore.reviewURL` can be formed from the configured ID.
  - Camera usage descriptions will be removed unless a fresh implementation-time source search finds live photo capture or camera APIs.
  - Production bundle identifiers stay unchanged; only the dev target identifiers move to `com.maxblazek.austrian-rocks-dev`.

## Files touched
- `AustrianRocks/Config/BrandConfig.swift` (edit) — represent the unpublished App Store ID as absent and expose a configured review URL helper.
- `AustrianRocks/UI/Discover/DiscoverView.swift` (edit) — remove the hardcoded Boolder review ID and conditionally show/open the rate row from brand configuration.
- `AustrianRocks/Info.plist` (edit) — remove unused camera permission metadata while preserving location permission metadata and precise-location temporary usage text.
- `Dev-Info.plist` (edit) — remove unused camera permission metadata and keep development location permission metadata, including the temporary precise-location purpose text.
- `AustrianRocks/en.lproj/InfoPlist.strings` (edit) — remove the localized camera usage string while preserving localized location strings.
- `AustrianRocks/de.lproj/InfoPlist.strings` (edit) — remove the localized camera usage string while preserving localized location strings.
- `PrivacyInfo.xcprivacy` (edit if needed) — verify the privacy manifest remains valid and keep UserDefaults access declared while current app/dependency usage requires it.
- `AustrianRocks.xcodeproj/project.pbxproj` (edit) — change development target bundle identifiers to `com.maxblazek.austrian-rocks-dev` without changing production identifiers.
- `LICENSE.md` (edit) — add an Austrian.rocks copyright notice while preserving the original Boolder MIT notice.

## Phase 0004-P1 — App Store review configuration and Discover behavior
Goal: Remove the stale Boolder App Store review link from runtime code and make the rate action absent while Austrian.rocks is unpublished.

- [x] Read `AustrianRocks/Config/BrandConfig.swift` and `AustrianRocks/UI/Discover/DiscoverView.swift` before editing.
- [x] In `AustrianRocks/Config/BrandConfig.swift`, change `BrandConfig.AppStore.appID` from a shippable string value to `static let appID: String? = nil`.
- [x] In `AustrianRocks/Config/BrandConfig.swift`, add `static var reviewURL: URL?` inside `BrandConfig.AppStore` that returns `nil` when `appID` is `nil` or empty and otherwise builds the write-review URL by interpolating the configured ID into the `https://itunes.apple.com/app/id` path only.
- [x] In `AustrianRocks/Config/BrandConfig.swift`, add a short comment next to `appID` explaining that it is intentionally absent until App Store release and setting it enables the rate/review link.
- [x] In `AustrianRocks/UI/Discover/DiscoverView.swift`, replace the unconditional rate button with `if let reviewURL = BrandConfig.AppStore.reviewURL { ... }` so the “Rate app” row and its divider are omitted when no URL exists.
- [x] In `AustrianRocks/UI/Discover/DiscoverView.swift`, update the rate button action to call `openURL(reviewURL)` and remove all local hardcoded App Store IDs and URL strings for the review action.

**Quality gate:** `! rg -n "1506614493|appID = \"" AustrianRocks/Config/BrandConfig.swift AustrianRocks/UI/Discover/DiscoverView.swift && xcodebuild -project AustrianRocks.xcodeproj -scheme AustrianRocks -configuration Debug -destination 'generic/platform=iOS Simulator' build` → stale Boolder ID and hardcoded non-optional App Store ID assignment search returns no matches; `xcodebuild` completes successfully for the production scheme.

## Phase 0004-P2 — Permission metadata, privacy manifest, bundle IDs, and license
Goal: Make release metadata match current app behavior and current ownership without changing runtime behavior.

- [x] Run and read `rg -n "UIImagePicker|AVCapture|NSCameraUsageDescription|PHPhoto|PhotosUI|camera|Camera" AustrianRocks Dev-Info.plist` before editing; if live camera/photo-capture API usage is found, keep the camera permission keys and document the exact file path in this plan before continuing.
- [x] Read `AustrianRocks/Info.plist`, then remove only the `NSCameraUsageDescription` key and value from production metadata while leaving `NSLocationAlwaysAndWhenInUseUsageDescription`, `NSLocationWhenInUseUsageDescription`, and `NSLocationTemporaryUsageDescriptionDictionary` intact.
- [x] Read `Dev-Info.plist`, then remove only the `NSCameraUsageDescription` key and value from development metadata while leaving location permission keys intact.
- [x] In `Dev-Info.plist`, ensure `NSLocationTemporaryUsageDescriptionDictionary` contains `LocationAccuracyAuthorizationDescription` as a child key with the existing precise-location explanation string, matching the production plist structure.
- [x] Read `AustrianRocks/en.lproj/InfoPlist.strings` and remove only the `NSCameraUsageDescription` line.
- [x] Read `AustrianRocks/de.lproj/InfoPlist.strings` and remove only the `NSCameraUsageDescription` line.
- [x] Read `PrivacyInfo.xcprivacy`; keep `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1` because `AustrianRocks/UI/Map/MapContainerView.swift` uses `UserDefaults.standard`, and do not add any new accessed API category.
- [x] Read `AustrianRocks.xcodeproj/project.pbxproj`, then change both development target `PRODUCT_BUNDLE_IDENTIFIER` values from `com.nicolasmondollot.austrian-rocks-dev` to `com.maxblazek.austrian-rocks-dev` and leave both production `com.maxblazek.austrian-rocks` values unchanged.
- [x] Read `LICENSE.md`, then add `Copyright (c) 2026 Austrian.rocks` directly below the existing Boolder copyright line without deleting or rewriting the original MIT license notice.

**Quality gate:** `plutil -lint AustrianRocks/Info.plist Dev-Info.plist PrivacyInfo.xcprivacy && ! rg -n "NSCameraUsageDescription|com\.nicolasmondollot\.austrian-rocks-dev" AustrianRocks Dev-Info.plist AustrianRocks.xcodeproj/project.pbxproj && rg -n "NSLocationWhenInUseUsageDescription|NSLocationAlwaysAndWhenInUseUsageDescription|LocationAccuracyAuthorizationDescription|com\.maxblazek\.austrian-rocks" AustrianRocks/Info.plist Dev-Info.plist AustrianRocks.xcodeproj/project.pbxproj LICENSE.md` → plist and privacy files lint successfully; stale camera and fork dev bundle ID search returns no matches; evidence search shows location metadata still present, dev and production bundle IDs under `com.maxblazek`, and the license remains readable with both copyright notices.

## Phase 0004-P3 — Final static and build verification
Goal: Prove the repository meets all App Review metadata acceptance criteria after the runtime and metadata slices are complete.

- [ ] Run and read `xcodebuild -list -project AustrianRocks.xcodeproj` to confirm the available schemes still include `AustrianRocks` and `AustrianRocks dev`.
- [ ] Run and read `rg -n "1506614493|NSCameraUsageDescription|com\.nicolasmondollot\.austrian-rocks-dev" .` from the repository root; investigate and remove any active metadata/code matches, while ignoring only historical `.incant` spec/plan references if they are the sole remaining matches.
- [ ] Run and read `rg -n "NSPrivacyAccessedAPICategoryUserDefaults|UserDefaults\.standard|NSLocationWhenInUseUsageDescription|NSLocationAlwaysAndWhenInUseUsageDescription|LocationAccuracyAuthorizationDescription|com\.maxblazek\.austrian-rocks-dev|com\.maxblazek\.austrian-rocks" AustrianRocks Dev-Info.plist PrivacyInfo.xcprivacy AustrianRocks.xcodeproj/project.pbxproj` and confirm privacy, location, dev bundle ID, and production bundle ID evidence is present.
- [ ] Run and read `plutil -lint AustrianRocks/Info.plist Dev-Info.plist PrivacyInfo.xcprivacy` and fix any syntax errors before review.
- [ ] Run and read `xcodebuild -project AustrianRocks.xcodeproj -scheme AustrianRocks -configuration Debug -destination 'generic/platform=iOS Simulator' build`; if the local environment cannot complete this exact build for signing, SDK, or secret-injection reasons, run the closest available `xcodebuild` build-equivalent, capture the exact failure/output, and document why it still covers the changed surface.
- [ ] Manually inspect `AustrianRocks/UI/Discover/DiscoverView.swift` after edits and confirm the rate row is guarded by `BrandConfig.AppStore.reviewURL` so the default `nil` app ID cannot display or open an App Store review URL.

**Quality gate:** `xcodebuild -project AustrianRocks.xcodeproj -scheme AustrianRocks -configuration Debug -destination 'generic/platform=iOS Simulator' build && plutil -lint AustrianRocks/Info.plist Dev-Info.plist PrivacyInfo.xcprivacy && ! rg -n "1506614493|NSCameraUsageDescription|com\.nicolasmondollot\.austrian-rocks-dev" AustrianRocks Dev-Info.plist AustrianRocks.xcodeproj/project.pbxproj` → build and plist/privacy lint pass; final stale-value search returns no active source or metadata matches.

## Requirement coverage self-review
- [x] Requirement 1 maps to Phase 0004-P1 steps that replace the hardcoded Boolder ID in `DiscoverView` with `BrandConfig.AppStore` review URL usage.
- [x] Requirement 2 maps to Phase 0004-P1 steps that make `BrandConfig.AppStore.appID` optional and absent by default.
- [x] Requirement 3 maps to Phase 0004-P1 steps that conditionally render the rate row only when `reviewURL` exists.
- [x] Requirement 4 maps to Phase 0004-P2 source search and plist/localized string cleanup steps.
- [x] Requirement 5 maps to Phase 0004-P2 location-preservation steps and Phase 0004-P3 evidence searches.
- [x] Requirement 6 maps to Phase 0004-P2 privacy manifest verification and Phase 0004-P3 lint/evidence searches.
- [x] Requirement 7 maps to Phase 0004-P2 project-file bundle identifier edits and Phase 0004-P3 stale/current bundle ID searches.
- [x] Requirement 8 maps to Phase 0004-P2 license edit.
- [x] Requirement 9 maps to Phase 0004-P3 final static searches, plist/privacy lint, Discover inspection, and Xcode build.
- [x] Symbol/signature consistency checked: `BrandConfig.AppStore.appID` and `BrandConfig.AppStore.reviewURL` are the only new/changed Swift access points named in the phases.
- [x] No unresolved filler remains in the implementation steps; every step names concrete files and actions.

## Human approval checkpoint
This plan is ready for human approval. Do not change application code or metadata until the plan is approved. After approval, continue with `/incant:implement 0004`.
