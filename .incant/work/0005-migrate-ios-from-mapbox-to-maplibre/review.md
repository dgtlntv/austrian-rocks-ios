---
id: "0005"
slug: migrate-ios-from-mapbox-to-maplibre
stage: review
reviewed: 2026-06-11
commit: a94db58941ca3f87d5171c492bafb1b57d0546ad
---

# Migrate iOS From Mapbox To MapLibre — review

### Strengths
- `AustrianRocks/UI/Map/MapFeatureCardModel.swift:84` through `AustrianRocks/UI/Map/MapFeatureCardModel.swift:116` — card models are built tile-property-first from the shared id keys, choose localized `nameEn`/base text, validate HTTP(S) card links, parse bounds and POI coordinates safely, and keep SQLite detail availability as an optional capability rather than a prerequisite for display.
- `AustrianRocks/UI/Map/MapFeatureBounds.swift:45` through `AustrianRocks/UI/Map/MapFeatureBounds.swift:61` — show-on-map bounds parsing validates finite coordinate boxes and implements the required region main-cluster preference before falling back to region bounds.
- `AustrianRocks/UI/Map/MapFeatureCardView.swift:149` through `AustrianRocks/UI/Map/MapFeatureCardView.swift:176` — CTA rendering matches the contract: POIs only expose directions when a safe URL and coordinate are available, region/cluster/area cards expose show-on-map when bounds exist, and missing SQLite details become a disabled localized state instead of a crash path.
- `AustrianRocks/UI/Map/MapLibreViewController.swift:284` through `AustrianRocks/UI/Map/MapLibreViewController.swift:345` — non-problem taps now build native card models from MapLibre feature attributes while problem taps still bypass cards and route directly through the existing native `ProblemDetailsView` path.
- `AustrianRocks/UI/Map/MapContainerView.swift:90` through `AustrianRocks/UI/Map/MapContainerView.swift:140` — the SwiftUI overlay wires close/show-on-map/detail/directions actions cleanly and re-checks SQLite records before presenting `RegionDetailView`, `ClusterDetailView`, or `AreaView`.
- `AustrianRocks/UI/Map/MapState.swift:133` through `AustrianRocks/UI/Map/MapState.swift:165` — map-card state is separate from problem/topo presentation, close requests clear the MapLibre selected layer, and POI directions reuse the existing native action-sheet flow.
- `AustrianRocks/UI/Map/MapFeatureCardGradeHistogramView.swift:24` through `AustrianRocks/UI/Map/MapFeatureCardGradeHistogramView.swift:50` plus the new English/German strings — the grade histogram omits empty data, renders localized labels, and adds an accessibility summary for the parsed distribution.
- Fresh P4 review gate: `xcodebuild test -project AustrianRocks.xcodeproj -scheme AustrianRocks -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.3.1' -only-testing:AustrianRocksTests && xcodebuild -project AustrianRocks.xcodeproj -scheme AustrianRocks -configuration Debug -destination 'generic/platform=iOS Simulator' build && xcodebuild -project AustrianRocks.xcodeproj -scheme 'AustrianRocks dev' -configuration Debug -destination 'generic/platform=iOS Simulator' build` → **TEST SUCCEEDED** and **BUILD SUCCEEDED** for both app schemes.

### Blocker
- None.

### Major
- None.

### Minor
- None.

### Nit
- None.

### Verdict
Ready to release? **No** — the 0005-P4 phase gate has no open blocker or major findings, and the fresh P4 tests/builds pass. The item is not ready to finalize yet because planned 0005-P5 legal/docs cleanup and final verification remain incomplete.
