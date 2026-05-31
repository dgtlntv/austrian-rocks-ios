---
id: "0004"
slug: update-privacy-app-review-metadata
stage: review
reviewed: 2026-05-31
commit: c5df4a6c
---

# Update Privacy App Review Metadata — review

### Strengths
- `AustrianRocks/Config/BrandConfig.swift:35-40` and `AustrianRocks/UI/Discover/DiscoverView.swift:219-232` — the App Store ID is optional/default-nil, the review URL is centralized in `BrandConfig.AppStore`, and the “Rate app” row/divider are omitted unless that configured URL exists.
- `AustrianRocks/UI/Discover/DiscoverView.swift:219-222` — the support action opens only the configured `reviewURL`, so the stale Boolder ID is not present in runtime URL generation and no user-controlled URL input is introduced.
- `AustrianRocks/Info.plist:32-40`, `Dev-Info.plist:32-35` and `Dev-Info.plist:85-88`, plus `AustrianRocks/en.lproj/InfoPlist.strings:9-10` and `AustrianRocks/de.lproj/InfoPlist.strings:9-10` — camera permission declarations are gone while required location and precise-location copy remain present in production, development, and localized metadata.
- `PrivacyInfo.xcprivacy:8-12` and `AustrianRocks/UI/Map/MapContainerView.swift:263` — the privacy manifest still declares UserDefaults with reason `CA92.1`, matching actual `UserDefaults.standard` usage and adding no unnecessary accessed API category.
- `AustrianRocks.xcodeproj/project.pbxproj:1015` and `AustrianRocks.xcodeproj/project.pbxproj:1042` — both dev bundle identifiers now use `com.maxblazek.austrian-rocks-dev`; production remains `com.maxblazek.austrian-rocks` at `project.pbxproj:1193` and `project.pbxproj:1218`.
- `LICENSE.md:3-4` — the original Boolder MIT copyright notice is preserved and the Austrian.rocks copyright line is added directly below it.
- Fresh review gates passed: `xcodebuild -list -project AustrianRocks.xcodeproj` listed the expected schemes; `plutil -lint AustrianRocks/Info.plist Dev-Info.plist PrivacyInfo.xcprivacy` passed; active source/metadata searches found no `1506614493`, `NSCameraUsageDescription`, or `com.nicolasmondollot.austrian-rocks-dev`; and `xcodebuild -project AustrianRocks.xcodeproj -scheme AustrianRocks -configuration Debug -destination 'generic/platform=iOS Simulator' build` ended with `** BUILD SUCCEEDED **`.
- Commit history follows incant conventions: `incant 0004: spec`, `incant 0004: plan`, and phase commits `incant 0004-P1`, `incant 0004-P2`, and `incant 0004-P3` are present.

### Blocker
- None.

### Major
- None.

### Minor
- None.

### Nit
- None.

### Verdict
Ready to release? **Yes** — all acceptance criteria are met, the final static/build verification passed, and there are no open findings. The item is ready for `/incant:finalize 0004`.
