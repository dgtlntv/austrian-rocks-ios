---
id: "0004"
slug: update-privacy-app-review-metadata
stage: review
reviewed: 2026-05-31
commit: 6460b730
---

# Update Privacy App Review Metadata — review

### Strengths
- `AustrianRocks/Config/BrandConfig.swift:36` and `AustrianRocks/UI/Discover/DiscoverView.swift:219` — the App Store ID remains optional/default-nil and the rate row is rendered only when `BrandConfig.AppStore.reviewURL` exists, preserving the Phase 0004-P1 safety guarantee.
- `AustrianRocks/UI/Discover/DiscoverView.swift:219-222` — the support action opens only the centralized configured review URL, so no hardcoded Boolder App Store ID or user-controlled URL input is involved.
- `AustrianRocks/Info.plist:33-38`, `Dev-Info.plist:32-33`, `Dev-Info.plist:85-88`, `AustrianRocks/en.lproj/InfoPlist.strings:9-10`, and `AustrianRocks/de.lproj/InfoPlist.strings:9-10` — camera permission text has been removed while location and temporary precise-location metadata remain present.
- `PrivacyInfo.xcprivacy:7-11` and `AustrianRocks/UI/Map/MapContainerView.swift:263` — the privacy manifest continues to declare UserDefaults access with reason `CA92.1`, matching the remaining `UserDefaults.standard` usage.
- `AustrianRocks.xcodeproj/project.pbxproj:1015` and `AustrianRocks.xcodeproj/project.pbxproj:1042` — both development target bundle identifiers now use `com.maxblazek.austrian-rocks-dev`, while production remains `com.maxblazek.austrian-rocks` at `project.pbxproj:1193` and `project.pbxproj:1218`.
- `LICENSE.md:3-4` — the original Boolder MIT copyright notice is preserved and the Austrian.rocks notice is added directly below it.
- Fresh review verification passed: `plutil -lint AustrianRocks/Info.plist Dev-Info.plist PrivacyInfo.xcprivacy`; stale searches found no active `NSCameraUsageDescription`, `1506614493`, or `com.nicolasmondollot.austrian-rocks-dev` matches in the implementation surface.

### Blocker
- None.

### Major
- None.

### Minor
- None.

### Nit
- None.

### Verdict
Ready to release? **Yes** — Phase 0004-P2 satisfies the planned metadata, privacy-manifest, bundle-ID, and license slice with no open findings. This is still a phase-gate approval; Phase 0004-P3 must complete the final build/static verification before closing the item.
