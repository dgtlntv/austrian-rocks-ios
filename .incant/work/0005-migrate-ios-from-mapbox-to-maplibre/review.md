---
id: "0005"
slug: migrate-ios-from-mapbox-to-maplibre
stage: review
reviewed: 2026-06-11
commit: 3c9ea968a884c19bdcbdeb1f3e3f8d187a09d73f
---

# Migrate iOS From Mapbox To MapLibre — review

### Strengths
- `AustrianRocks.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved:5` and `AustrianRocks.xcodeproj/project.pbxproj:1420` — P2 resolves MapLibre Native through the public SwiftPM distribution package at `6.27.0` with a project requirement starting at `6.10.0`, satisfying the PMTiles-capable SDK version requirement and avoiding the unavailable repository named in the original plan.
- `AustrianRocks/Config/BrandConfig.swift:44` — the active map configuration is centralized as `BrandConfig.MapTiles` with the Rails manifest URL and cache keys; controller code no longer carries Mapbox/provider URL configuration.
- `AustrianRocks/UI/Map/MapStyleLoadCoordinator.swift:75` and `AustrianRocks/UI/Map/MapStyleLoadCoordinator.swift:88` — the cache/fallback state is now explicit: fresh styles are cached only after a style-loaded callback, fresh style failures can fall back once to a prior cached style, and cached failures surface unavailable.
- `AustrianRocksTests/MapStyleLoadCoordinatorTests.swift:6` through `AustrianRocksTests/MapStyleLoadCoordinatorTests.swift:106` — the previous fallback review gap is covered with focused tests for cache-after-load, manifest failure to cached style, fresh-style failure fallback without cache poisoning, no-cache unavailable, retrying the same URL, and light/dark style selection.
- `AustrianRocks/UI/Map/MapLibreViewController.swift:131` — retrying the same style URL now forces a reload by clearing `styleURL` before reinstalling, so retry no longer silently treats the old URL as already available.
- Fresh review gates: `rg -n "import MapboxMaps|BrandConfig\\.Mapbox|MBXAccessToken|~/.mapbox|api\\.mapbox\\.com|mapbox-(maps|common|core-maps)-ios|turf-swift|MapboxMaps" AustrianRocks/Config AustrianRocks/UI AustrianRocks.xcodeproj README.md AustrianRocks.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved; test $? -eq 1` → no matches; `xcodebuild -list -project AustrianRocks.xcodeproj` → schemes are `AustrianRocks` and `AustrianRocks dev` only; `xcodebuild -resolvePackageDependencies -project AustrianRocks.xcodeproj && xcodebuild test -project AustrianRocks.xcodeproj -scheme AustrianRocks -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.3.1' -only-testing:AustrianRocksTests && xcodebuild -project AustrianRocks.xcodeproj -scheme AustrianRocks -configuration Debug -destination 'generic/platform=iOS Simulator' build && xcodebuild -project AustrianRocks.xcodeproj -scheme 'AustrianRocks dev' -configuration Debug -destination 'generic/platform=iOS Simulator' build` → package resolution succeeded, **TEST SUCCEEDED**, and **BUILD SUCCEEDED** for both app schemes.

### Blocker
- None.

### Major
- `AustrianRocks/UI/Map/MapStyleLoadCoordinator.swift:75` and `AustrianRocks/UI/Map/MapLibreViewController.swift:139` — addressed. Fresh style success is now recorded only from the style-loaded callback; fresh style-load failure falls back to the prior cached URL before surfacing unavailable; retry of the same URL forces a reinstall instead of marking the map available prematurely. status: addressed
- `AustrianRocksTests/MapStyleLoadCoordinatorTests.swift:6` — addressed. The fallback state machine now has automated coverage for the scenarios requested in the prior review. status: addressed
- `AustrianRocks/UI/Map/MapLibreViewController.swift:100` and `AustrianRocks/UI/Map/MapStyleLoadCoordinator.swift:64` — canceled style loads can still publish stale actions. `loadStyleFromManifestOrCache()` cancels the previous `styleLoadTask`, but the task applies whatever action returns after `await styleLoader.loadStyle(...)` without checking cancellation (`MapLibreViewController.swift:105-110`), and the coordinator catches all errors, including cancellation, as a normal manifest failure that can install a cached URL or mark the map unavailable (`MapStyleLoadCoordinator.swift:64-71`). A quick trait change or retry during an in-flight manifest request can therefore let the canceled light/dark load overwrite the newer choice or show an unavailable overlay while a newer request is still pending, violating the P2 light/dark reload and “unavailable only after fresh/cached initialization fail” contract. Fix by treating `CancellationError` as `.none` or guarding `!Task.isCancelled` before handling the action, and add a regression test for canceled/stale loads. status: open

### Minor
- None.

### Nit
- None.

### Verdict
Ready to release? **No** — one open major remains for the 0005-P2 phase gate. The previous cache-before-load and test-coverage findings are addressed and the fresh gates pass, but cancellation/stale-result handling still needs a revise loop before advancing.
