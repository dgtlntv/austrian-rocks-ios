---
id: "0002"
slug: remove-bleau-leftovers
stage: archived
completed: 2026-05-31
commit: 4caf5bbcc998d5341f1c266f188a83ef1f13e974
---

# Remove Bleau Leftovers — summary

## What was built
- Rewrote launch-facing repository copy for Austrian.rocks and removed old Boolder/Fontainebleau/Bleau product copy, URLs, and `hello@boolder.com` references.
- Removed the Bleau Météo dry-fast link from the Discover UI.
- Replaced the Fontainebleau current-location fallback with the approved Austria-wide map bounds.
- Swept launch-facing metadata, shared schemes, app/launch asset metadata, plist values, and stale Swift app-name headers for old non-attribution references.
- Preserved and classified legal/provenance references in acknowledgements, license text, and original copyright headers.

## Deviations from spec
- No Austria-wide replacement weather/drying link was added; the Bleau Météo row was removed because no verified Austria-appropriate static replacement was available in the repository.
- Required legal/provenance references to Boolder and Nicolas Mondollot were retained and explicitly classified rather than removed, as required by the spec.

## Key decisions
- `AustrianRocks/UI/Map/MapboxViewController.swift` keeps the Austria fallback bounds local to `centerOnCurrentLocation()` as a single clearly named `austriaFallbackBounds` value.
- Swift headers with stale `//  Boolder` app-name lines now use `//  Austrian.rocks`, while original provenance is preserved with `Originally created for Boolder by Nicolas Mondollot...` where applicable.
- `AustrianRocks.xcodeproj/project.pbxproj` organization metadata was changed to `Austrian.rocks`; user-specific `xcuserdata` churn was not part of the item.

## Links
- Commits:
  - `c6de6dd4` — `incant 0002: spec`
  - `6a9fca86` — `incant 0002: plan`
  - `f76f0bbd` — `incant 0002-P1: product copy cleanup`
  - `538348fa` — `incant 0002-P2: map fallback and metadata sweep`
  - `4caf5bbc` — `incant 0002-P3: final classification and build verification`

## Sessions
- `019e7e47-c851-7ddb-9691-e23bd2e3cc08`
- `019e7e53-a61e-7549-8d6d-8c7c4475c9ab`
- `019e7e5d-7271-72ea-be68-a6a9184121a6`
- `019e7e61-84a3-757e-ab86-10a528bb09de`
- `019e7e62-8adc-7c0c-90c4-3e6a8cc2ae07`
- `019e7e68-9eb9-7901-8250-12cb9b0fa49b`
- `019e7e6a-a84a-7926-bd69-223787d792bd`
- `019e7e6d-d015-7684-8459-c9cd1e95ee2b`

## Follow-ups
- None.
