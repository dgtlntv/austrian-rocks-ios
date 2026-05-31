---
id: "0004"
slug: update-privacy-app-review-metadata
stage: review
reviewed: 2026-05-31
commit: c0878fc2ed8d268cf164e8fa0c0877efb36f29de
---

# Update Privacy App Review Metadata — review

### Strengths
- `AustrianRocks/Config/BrandConfig.swift:36` — the App Store ID is now represented as `String? = nil`, so the default unreleased configuration has no shippable placeholder or stale Boolder ID.
- `AustrianRocks/Config/BrandConfig.swift:38` — `reviewURL` centralizes review-link construction under `BrandConfig.AppStore` and returns `nil` for absent or empty IDs, matching the config-vs-code principle and the plan.
- `AustrianRocks/UI/Discover/DiscoverView.swift:219` — the support UI gates the rate row on `BrandConfig.AppStore.reviewURL`, so the default nil app ID omits the row instead of opening an invalid or wrong App Store URL.
- `AustrianRocks/UI/Discover/DiscoverView.swift:221` — the button action uses the configured URL directly and no longer constructs a local URL from a hardcoded app ID.
- `.incant/work/0004-update-privacy-app-review-metadata/plan.md:22` — the phase records quality-gate evidence, and fresh review verification reran the same gate successfully with `xcodebuild` ending in `** BUILD SUCCEEDED **`.

### Blocker
- None.

### Major
- None.

### Minor
- None.

### Nit
- None.

### Verdict
Ready to release? **Yes** — Phase 0004-P1 satisfies its planned App Store review configuration and Discover behavior slice, with no open blocker or major findings. This is a phase-gate approval only; complete P2/P3 before final item release.
