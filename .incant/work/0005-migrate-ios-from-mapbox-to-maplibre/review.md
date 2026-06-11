---
id: "0005"
slug: migrate-ios-from-mapbox-to-maplibre
stage: review
reviewed: 2026-06-11
commit: 4d43176efa9b25dfb99877548ec2e000fe7055f0
---

# Migrate iOS From Mapbox To MapLibre — review

### Strengths
- `AustrianRocks.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved:5` and `AustrianRocks.xcodeproj/project.pbxproj:1420` — P2 resolves MapLibre Native through the public SwiftPM distribution package at `6.27.0` with a project requirement starting at `6.10.0`, satisfying the PMTiles-capable SDK version requirement and avoiding the unavailable repository named in the original plan.
- `AustrianRocks/Config/BrandConfig.swift:44` — the active map configuration is centralized as `BrandConfig.MapTiles` with the Rails manifest URL and cache keys; controller code no longer carries Mapbox/provider URL configuration.
- `AustrianRocks/UI/Map/MapStyleLoadCoordinator.swift:52` through `AustrianRocks/UI/Map/MapStyleLoadCoordinator.swift:90` — the manifest/cache/style-load state machine now keeps fresh installs pending until MapLibre reports success, falls back from failed fresh styles to the prior cached style, and treats `CancellationError` as `.none` instead of surfacing stale unavailable state.
- `AustrianRocks/UI/Map/MapLibreViewController.swift:108` and `AustrianRocks/UI/Map/MapLibreViewController.swift:110` — canceled async style-load tasks are guarded before applying actions back to the controller, which addresses the stale light/dark or retry-result race from the prior review.
- `AustrianRocksTests/MapStyleLoadCoordinatorTests.swift:75` — cancellation behavior now has regression coverage proving a canceled manifest load neither installs cached fallback nor surfaces unavailable.
- Fresh review gates: `rg -n "import MapboxMaps|BrandConfig\\.Mapbox|MBXAccessToken|~/.mapbox|api\\.mapbox\\.com|mapbox-(maps|common|core-maps)-ios|turf-swift|MapboxMaps" AustrianRocks/Config AustrianRocks/UI AustrianRocks.xcodeproj README.md AustrianRocks.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved; test $? -eq 1` → no matches; `xcodebuild -list -project AustrianRocks.xcodeproj` → schemes are `AustrianRocks` and `AustrianRocks dev` only; `xcodebuild -resolvePackageDependencies -project AustrianRocks.xcodeproj && xcodebuild test -project AustrianRocks.xcodeproj -scheme AustrianRocks -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.3.1' -only-testing:AustrianRocksTests && xcodebuild -project AustrianRocks.xcodeproj -scheme AustrianRocks -configuration Debug -destination 'generic/platform=iOS Simulator' build && xcodebuild -project AustrianRocks.xcodeproj -scheme 'AustrianRocks dev' -configuration Debug -destination 'generic/platform=iOS Simulator' build` → package resolution succeeded, **TEST SUCCEEDED**, and **BUILD SUCCEEDED** for both app schemes.

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
Ready to release? **No** — the 0005-P2 phase gate has no open blocker or major findings, and the prior cancellation major is addressed with passing gates. The full item should continue to the planned P3–P5 implementation before final release/finalize.
