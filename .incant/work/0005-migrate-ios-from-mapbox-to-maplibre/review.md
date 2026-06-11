---
id: "0005"
slug: migrate-ios-from-mapbox-to-maplibre
stage: review
reviewed: 2026-06-11
commit: 655f701460535e96ebc03cf364f65bdc385fa23e
---

# Migrate iOS From Mapbox To MapLibre — review

### Strengths
- `AustrianRocks.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved:5` and `AustrianRocks.xcodeproj/project.pbxproj:1410` — P2 resolves MapLibre Native through the public SwiftPM distribution package at `6.27.0` with a project requirement starting at `6.10.0`, satisfying the PMTiles-capable SDK version requirement and avoiding the unavailable repository named in the original plan.
- `AustrianRocks.xcodeproj/project.pbxproj:695` and `AustrianRocks.xcodeproj/project.pbxproj:716` — both app targets now link the `MapLibre` product, and the removed Mapbox package/products/token scripts are absent from active project and docs. Fresh static gate: `rg -n "import MapboxMaps|BrandConfig\\.Mapbox|MBXAccessToken|~/.mapbox|api\\.mapbox\\.com|mapbox-(maps|common|core-maps)-ios|turf-swift|MapboxMaps" AustrianRocks/Config AustrianRocks/UI AustrianRocks.xcodeproj README.md AustrianRocks.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved; test $? -eq 1` → no matches.
- `AustrianRocks/Config/BrandConfig.swift:39` — the active map configuration is now a centralized `BrandConfig.MapTiles` surface with the Rails manifest URL and cache keys, so controller code no longer carries provider URLs or token setup.
- `AustrianRocks/UI/Map/MapLibreView.swift:17` and `AustrianRocks/UI/Map/MapLibreViewController.swift:18` — the SwiftUI bridge/controller were renamed to MapLibre-neutral types and keep the existing MapState delegate boundary in place for later P3/P4 interaction work.
- `AustrianRocks/UI/Map/MapLibreViewController.swift:94` — the controller now resolves light/dark style choice from the manifest, uses the no-store manifest client, and attempts cached style fallback when the manifest fetch/decoding path fails.
- `AustrianRocks/UI/Map/MapUnavailableOverlay.swift:10` and `AustrianRocks/UI/Map/MapState.swift:37` — map unavailable/retry state is native SwiftUI and non-blocking instead of reverting to Mapbox or preventing the rest of the app from rendering.
- Fresh P2 quality gate: `xcodebuild -resolvePackageDependencies -project AustrianRocks.xcodeproj && xcodebuild -project AustrianRocks.xcodeproj -scheme AustrianRocks -configuration Debug -destination 'generic/platform=iOS Simulator' build && xcodebuild -project AustrianRocks.xcodeproj -scheme 'AustrianRocks dev' -configuration Debug -destination 'generic/platform=iOS Simulator' build` → **BUILD SUCCEEDED** for both app schemes with MapLibre Native `6.27.0` and no Mapbox token files.

### Blocker
- None.

### Major
- `AustrianRocks/UI/Map/MapLibreViewController.swift:102` — the last-known style cache is written before MapLibre proves that the style actually initialized, and `installStyle` marks the map available before assigning/loading the style (`AustrianRocks/UI/Map/MapLibreViewController.swift:123`). If the freshly fetched manifest points at a bad style, or the style load fails after assignment, `didFailLoadingMapWithError` only shows unavailable state (`AustrianRocks/UI/Map/MapLibreViewController.swift:141`) and never attempts the previously cached working style. This violates the P2/spec fallback contract: cache the last **successfully loaded** style and show unavailable only after neither fresh nor cached style can initialize. It can also poison the cache with an unproven URL and make retry on the same URL clear the overlay without reloading because of the `mapView.styleURL != url` guard. Fix by tracking the pending fresh/cached style attempt, recording cache success and calling `mapBecameAvailable()` only from the style-loaded callback, falling back to the prior cached style once when a fresh style load fails, and only surfacing unavailable after those attempts fail. status: open
- `AustrianRocks/UI/Map/MapLibreViewController.swift:94` — the new controller fallback state machine has no automated coverage, despite P2 depending on async manifest fetch, cache fallback, style-load success/failure, retry, and light/dark reload behavior. The existing tests cover the pure manifest/cache models, but not the integration logic that currently contains the cache-before-load/fresh-style-failure bug above. Add controller-level tests via injected manifest/cache/style-install seams or a small testable loader/state machine covering fresh success, manifest failure → cached style, fresh style failure → previous cache, no cache → unavailable, retry with same URL, and trait-change behavior. status: open

### Minor
- None.

### Nit
- None.

### Verdict
Ready to release? **No** — two open major findings remain for the 0005-P2 phase gate. The dependency/project migration builds cleanly, but the style initialization/cache fallback path does not yet meet the promised reliability semantics and needs a covered revise loop before advancing.
