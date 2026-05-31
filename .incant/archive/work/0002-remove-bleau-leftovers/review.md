---
id: "0002"
slug: remove-bleau-leftovers
stage: review
reviewed: 2026-05-31
commit: 4caf5bbcc998d5341f1c266f188a83ef1f13e974
---

# Remove Bleau Leftovers — review

### Strengths
- `README.md:1` and `README.md:3` now present the repository as Austrian.rocks, and the old Boolder/Fontainebleau/Bleau product copy, old URLs, and `hello@boolder.com` contact have been removed while preserving secret-safe Mapbox setup instructions.
- `AustrianRocks/en.lproj/Localizable.strings:127` replaces the Fontainebleau-specific intermediate-grade warning with neutral area-variation copy; the remaining `top_areas.dry_fast.useful_link` value at `AustrianRocks/en.lproj/Localizable.strings:135` is unused by the cleaned dry-fast UI and contains no stale brand/place text.
- `AustrianRocks/UI/Discover/TopAreasDryFast.swift:62`-`73` now contains only the dry-fast warning block; the Bleau Météo button and Facebook URL were removed rather than replaced with an unverified weather source.
- `AustrianRocks/UI/Map/MapboxViewController.swift:646` introduces clearly named `austriaFallbackBounds`, and `AustrianRocks/UI/Map/MapboxViewController.swift:647`-`648` use the exact Austria-wide southwest/northeast coordinates required by the spec.
- `AustrianRocks/UI/Map/MapboxViewController.swift:653` and `AustrianRocks/UI/Map/MapboxViewController.swift:663` consistently use the Austria fallback bounds for both in-bounds centering and extend-to-current-location camera behaviour.
- The stale Swift header sweep removes launch-facing `//  Boolder` app-name headers while preserving legal/provenance context, e.g. `AustrianRocks/Models/Boulder.swift:3` now uses `Austrian.rocks` and `AustrianRocks/Models/Boulder.swift:5` explicitly records original Boolder/Nicolas provenance.
- `AustrianRocks.xcodeproj/project.pbxproj:661` changes generated project organization metadata from the original author name to `Austrian.rocks`, satisfying the launch-facing metadata sweep without churning user-specific Xcode data.
- Remaining grep hits are appropriately classified: `AustrianRocks/Acknowledgements.json:71`-`77` is intentional attribution/copyright/license content, `LICENSE.md:3` is copyright/license text, and `AustrianRocks/Config/BrandConfig.swift:31` is the current Austrian.rocks contact rather than an old Boolder email.
- Fresh review gates passed: `rg -n "boolder|fontainebleau|bleau|nmondollot|hello@" .` reported only the acknowledgement ID and current Austrian.rocks contact; the supplemental case-insensitive grep reported only legal/provenance headers, acknowledgement/license text, and the current contact; the P2 stale-reference grep produced no output (`exit=1`).
- Fresh build verification passed: `xcodebuild -project AustrianRocks.xcodeproj -scheme AustrianRocks -destination 'generic/platform=iOS Simulator' build` exited 0 with `** BUILD SUCCEEDED **` and only the expected Mapbox-token warning/run-script warning.

### Blocker
- None.

### Major
- None.

### Minor
- None.

### Nit
- None.

### Verdict
Ready to release? **Yes** — all acceptance criteria are met, remaining old-brand references are legal/provenance or current-contact classifications, and the static gates plus simulator build pass with no open findings.
