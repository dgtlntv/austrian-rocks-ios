---
id: "0005"
slug: migrate-ios-from-mapbox-to-maplibre
stage: review
reviewed: 2026-06-11
commit: 6b9674802a732365723d1a00f86a63235e7d63b8
---

# Migrate iOS From Mapbox To MapLibre — review

### Strengths
- `AustrianRocks/UI/Map/MapSelectionController.swift:87` — P3 initializes all selected layers with the shared `-1` sentinel after style load, then reapplies the current selection without falling back to MapLibre feature-state.
- `AustrianRocks/UI/Map/MapSelectionController.swift:151` — selected-layer predicates are built from the shared id properties and support topo sibling problem ids, while `AustrianRocks/UI/Map/MapSelectionController.swift:166` skips base-layer exclusion for problems and excludes selected symbol ids for the other feature kinds.
- `AustrianRocks/UI/Map/MapSelectionController.swift:196` and `AustrianRocks/UI/Map/MapSelectionController.swift:207` — the grow/settle and clear animations carry over the Rails timing and scale constants, including symbol wiggle and selected problem circle scaling.
- `AustrianRocks/UI/Map/MapLibreViewController.swift:257` — problem taps use the shared `problemId` property, select through `problems-selected`, and still route directly to the native `ProblemDetailsView` flow through the existing delegate.
- `AustrianRocks/UI/Map/MapLibreViewController.swift:287` through `AustrianRocks/UI/Map/MapLibreViewController.swift:317` — area, cluster, region, and POI taps now query the shared MapLibre layer/property contract and preserve the current native state callbacks until the planned P4 card work lands.
- `AustrianRocks/UI/Map/MapLibreViewController.swift:328` and `AustrianRocks/UI/Map/MapLibreViewController.swift:341` — camera-based area and cluster inference is restored against `areas-hulls` and `cluster-hulls` with the planned zoom thresholds, keeping toolbar/download context updates tied to panning.
- `AustrianRocks/UI/Map/MapLibreViewController.swift:368` — iOS-specific grade, popular, favorite, and ticked filters are reapplied on the shared `problems` layer with local Core Data-backed favorite/tick ids, and the selected problem layer receives the same supplemental predicate.
- Fresh P3 review gate: `xcodebuild test -project AustrianRocks.xcodeproj -scheme AustrianRocks -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.3.1' -only-testing:AustrianRocksTests && xcodebuild -project AustrianRocks.xcodeproj -scheme AustrianRocks -configuration Debug -destination 'generic/platform=iOS Simulator' build && xcodebuild -project AustrianRocks.xcodeproj -scheme 'AustrianRocks dev' -configuration Debug -destination 'generic/platform=iOS Simulator' build` → **TEST SUCCEEDED** and **BUILD SUCCEEDED** for both app schemes.
- Fresh active-code Mapbox-removal check: `rg -n "import MapboxMaps|BrandConfig\\.Mapbox|MBXAccessToken|~/.mapbox|api\\.mapbox\\.com|mapbox-(maps|common|core-maps)-ios|turf-swift|MapboxMaps" AustrianRocks/Config AustrianRocks/UI AustrianRocks.xcodeproj README.md AustrianRocks.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved; test $? -eq 1` → no matches. Remaining Mapbox acknowledgement entries are still expected until planned P5 legal cleanup.

### Blocker
- None.

### Major
- `AustrianRocks/UI/Map/MapStyleLoadCoordinator.swift:77` and `AustrianRocks/UI/Map/MapLibreViewController.swift:131` — addressed. Fresh style success is recorded only from the style-loaded callback; fresh style-load failure falls back to the prior cached URL before surfacing unavailable; retry of the same URL forces a reinstall instead of marking the map available prematurely. status: addressed
- `AustrianRocksTests/MapStyleLoadCoordinatorTests.swift:6` — addressed. The fallback state machine has automated coverage for fresh success, manifest failure to cached style, fresh-style failure fallback without cache poisoning, no-cache unavailable, retrying the same URL, light/dark style choice, and cancellation. status: addressed
- `AustrianRocks/UI/Map/MapLibreViewController.swift:108`, `AustrianRocks/UI/Map/MapLibreViewController.swift:110`, and `AustrianRocks/UI/Map/MapStyleLoadCoordinator.swift:64` — addressed. Canceled style loads now return `.none`, and the controller checks cancellation before applying async actions, so canceled/stale loads no longer install cached fallback or show unavailable over a newer request. status: addressed

### Minor
- None.

### Nit
- None.

### Verdict
Ready to release? **No** — the 0005-P3 phase gate has no open blocker or major findings, and the fresh P3 tests/builds pass. The item is not ready to finalize yet because planned P4 native map cards and P5 legal/docs/final verification remain incomplete.
