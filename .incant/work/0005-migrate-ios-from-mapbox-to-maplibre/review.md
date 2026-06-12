---
id: "0005"
slug: migrate-ios-from-mapbox-to-maplibre
stage: review
reviewed: 2026-06-12
commit: 7f130a657f5cce8c0307f44f2f9ff37bac90787e
---

# Migrate iOS From Mapbox To MapLibre — review

### Strengths
- `AustrianRocks/UI/Map/MapLibreViewController.swift:109` through `AustrianRocks/UI/Map/MapLibreViewController.swift:111` plus `AustrianRocks/UI/Map/MapContainerView.swift:344` through `AustrianRocks/UI/Map/MapContainerView.swift:360` — the P6 ornament change removes the colliding MapLibre wordmark/default attribution control and replaces it with a persistent, subdued info FAB that opens About & Acknowledgements from the map.
- `AustrianRocks/UI/Discover/AcknowledgementsView.swift:56` through `AustrianRocks/UI/Discover/AcknowledgementsView.swift:91` — the attribution destination now includes localized project/about copy and a data/basemap section with basemap.at and Austrian Rocks attribution, preserving a native one-tap attribution path after hiding the default ornaments.
- `AustrianRocks/UI/Map/MapLayerContract.swift:44` through `AustrianRocks/UI/Map/MapLayerContract.swift:48` and `AustrianRocks/UI/Map/MapLibreViewController.swift:48` through `AustrianRocks/UI/Map/MapLibreViewController.swift:67` — Austria bounds are centralized from the shared style contract, with minimum zoom and a small panning margin rather than scattered magic values.
- `AustrianRocks/UI/Map/MapLibreViewController.swift:183` through `AustrianRocks/UI/Map/MapLibreViewController.swift:184` and `AustrianRocks/UI/Map/MapLibreViewController.swift:515` through `AustrianRocks/UI/Map/MapLibreViewController.swift:526` — camera constraints and show-on-map fitting now use a single computed destination camera with min/max zoom clamping before one animation, avoiding the prior racing zoom calls.
- `AustrianRocks/UI/Map/MapContainerView.swift:77` through `AustrianRocks/UI/Map/MapContainerView.swift:81`, `AustrianRocks/UI/Map/MapLibreView.swift:93` through `AustrianRocks/UI/Map/MapLibreView.swift:95`, and `AustrianRocks/UI/Map/MapLibreViewController.swift:287` through `AustrianRocks/UI/Map/MapLibreViewController.swift:289` — problem-sheet dismissal now routes through a problem-only map-selection clear, so swiping the sheet clears the selected dot without wiping a newer non-problem selection.
- `AustrianRocks/UI/Map/MapSelectionController.swift:33` through `AustrianRocks/UI/Map/MapSelectionController.swift:75` and `AustrianRocks/UI/Map/MapSelectionController.swift:146` through `AustrianRocks/UI/Map/MapSelectionController.swift:147` — selection animation now has a display-link driver seam, softened problem-dot grow scale, and a clear target of exactly base scale; `AustrianRocksTests/MapSelectionControllerTests.swift:46` through `AustrianRocksTests/MapSelectionControllerTests.swift:48` and `AustrianRocksTests/MapSelectionControllerTests.swift:71` cover those P6 constants and the atomic selected/base handoff.
- `AustrianRocks/Models/Region.swift:34` through `AustrianRocks/Models/Region.swift:41`, `AustrianRocks/Models/Region.swift:72` through `AustrianRocks/Models/Region.swift:96`, and `AustrianRocks/UI/Misc/CoverPhotoView.swift:13` through `AustrianRocks/UI/Misc/CoverPhotoView.swift:78` — region covers are now defensive and Rails-managed: missing columns, NULLs, and unsafe URLs render the placeholder, while valid covers load through a dedicated disk cache.
- `AustrianRocks/UI/Discover/RegionDetailView.swift:81` through `AustrianRocks/UI/Discover/RegionDetailView.swift:105` — region-to-cluster navigation uses the same router-aware split as cluster details, fixing sheet-presented region rows without breaking Discover stack navigation.
- Fresh P6 review gate (run this session): `xcodebuild test -project AustrianRocks.xcodeproj -scheme AustrianRocks -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.3.1' && xcodebuild -project AustrianRocks.xcodeproj -scheme AustrianRocks -configuration Debug -destination 'generic/platform=iOS Simulator' build && xcodebuild -project AustrianRocks.xcodeproj -scheme 'AustrianRocks dev' -configuration Debug -destination 'generic/platform=iOS Simulator' build` → **TEST SUCCEEDED** and **BUILD SUCCEEDED** for both app schemes.
- Static release checks re-run this session: `xcodebuild -list -project AustrianRocks.xcodeproj` lists only `AustrianRocks` and `AustrianRocks dev`; the Mapbox-removal `rg` command returns no active Mapbox SDK/import/token references.

### Blocker
- None.

### Major
- None.

### Minor
- None.

### Nit
- None.

### Verdict
Ready to release? **No** — the 0005-P6 phase gate has no open blocker or major findings, and the fresh automated tests/builds plus static checks pass. The item is not ready to finalize because planned 0005-P7 card/visual unification remains incomplete, and the P6 manual visual spot-check remains a human verification item before final close.
