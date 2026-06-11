---
id: "0005"
slug: migrate-ios-from-mapbox-to-maplibre
branch: incant/0005-migrate-ios-from-mapbox-to-maplibre
title: Migrate iOS From Mapbox To MapLibre
stage: review
status: phase-0005-P2-complete
created: 2026-06-11
commit: 3e3720ef
updated: 2026-06-11
---

# Migrate iOS From Mapbox To MapLibre — plan

## Status
- Phase: 0005-P2 complete (of 5) · stage: review
- Branch: incant/0005-migrate-ios-from-mapbox-to-maplibre
- Next: `/incant:review 0005` for the 0005-P2 phase gate review.
- Blockers: none.
- Quality gate evidence (2026-06-11):
  - `xcodebuild -resolvePackageDependencies -project AustrianRocks.xcodeproj && xcodebuild -project AustrianRocks.xcodeproj -scheme AustrianRocks -configuration Debug -destination 'generic/platform=iOS Simulator' build && xcodebuild -project AustrianRocks.xcodeproj -scheme 'AustrianRocks dev' -configuration Debug -destination 'generic/platform=iOS Simulator' build` → **BUILD SUCCEEDED** for both app schemes after package resolution. MapLibre Native resolved through the public Swift package distribution repository `https://github.com/maplibre/maplibre-gl-native-distribution.git` at `6.27.0`; no Mapbox token files or GitHub credentials were required in the CLI gate.
- Phase notes (2026-06-11):
  - The plan named `https://github.com/maplibre/maplibre-native-ios.git`, but that repository does not exist publicly. Package resolution succeeded with MapLibre's public SwiftPM distribution repository `maplibre-gl-native-distribution`, which provides the `MapLibre` product and resolves MapLibre Native iOS `6.27.0` (>= 6.10.0).
  - P2 establishes the MapLibre dependency, renamed bridge/controller files, manifest/cache-driven style loading, retry/unavailable state, Mapbox token-script removal, and README cleanup. Interaction queries, selected-layer filters/animations, and detailed camera inference remain assigned to 0005-P3 as planned.
- Review fixes (2026-06-11):
  - Addressed review major from `review.md` about hostless/malformed HTTP(S) URLs by requiring HTTP(S) URLs to include a non-empty host in the shared `URL.isHTTPOrHTTPS` validator used by manifest/cache/card URL checks.
  - Added regression coverage for `https:foo`, `https:///path`, and `http://` in `SafeURLTests`, plus manifest decoding rejection for hostless HTTP(S) URLs in `MapTileManifestTests`.
  - Fresh verification: `xcodebuild test -project AustrianRocks.xcodeproj -scheme AustrianRocks -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.3.1' -only-testing:AustrianRocksTests` → **TEST SUCCEEDED**, 17 tests passed, and the existing Mapbox-based app target built during the test action.
  - Addressed P2 review majors about cache-before-load and missing fallback-state coverage by extracting `MapStyleLoadCoordinator`, so fresh manifest styles are only recorded after MapLibre reports a loaded style, fresh style-load failure falls back once to the prior cached style, cached-style failure is the point where unavailable is surfaced, and retry reinstalls the same URL instead of treating it as already available.
  - Added `MapStyleLoadCoordinatorTests` coverage for fresh success, manifest failure → cached style, fresh style failure → previous cache without poisoning, no cache → unavailable, retry with the same URL, and light/dark trait-change style selection.
  - Fresh verification: `xcodebuild -resolvePackageDependencies -project AustrianRocks.xcodeproj && xcodebuild test -project AustrianRocks.xcodeproj -scheme AustrianRocks -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.3.1' -only-testing:AustrianRocksTests && xcodebuild -project AustrianRocks.xcodeproj -scheme AustrianRocks -configuration Debug -destination 'generic/platform=iOS Simulator' build && xcodebuild -project AustrianRocks.xcodeproj -scheme 'AustrianRocks dev' -configuration Debug -destination 'generic/platform=iOS Simulator' build` → package resolution succeeded, **TEST SUCCEEDED** (23 tests passed), and **BUILD SUCCEEDED** for both app schemes.
  - Addressed P2 review major about canceled/stale style loads by making `MapStyleLoadCoordinator` treat `CancellationError` as `.none`, adding task-cancellation guards before `MapLibreViewController` applies async style load actions, and covering canceled manifest loads so they neither install cached fallback nor surface unavailable.
  - Fresh verification: `xcodebuild test -project AustrianRocks.xcodeproj -scheme AustrianRocks -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.3.1' -only-testing:AustrianRocksTests` → **TEST SUCCEEDED** (24 tests passed, including the new cancellation regression). `xcodebuild -resolvePackageDependencies -project AustrianRocks.xcodeproj && xcodebuild -project AustrianRocks.xcodeproj -scheme AustrianRocks -configuration Debug -destination 'generic/platform=iOS Simulator' build && xcodebuild -project AustrianRocks.xcodeproj -scheme 'AustrianRocks dev' -configuration Debug -destination 'generic/platform=iOS Simulator' build` → package resolution succeeded and **BUILD SUCCEEDED** for both app schemes.
- Quality gate evidence (2026-06-11):
  - `xcodebuild test -project AustrianRocks.xcodeproj -scheme AustrianRocks -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:AustrianRocksTests` could not start because this Xcode install has iPhone 16 only at OS 18.3.1 while `OS:latest` resolves to a newer unavailable runtime.
  - Equivalent available-destination gate passed: `xcodebuild test -project AustrianRocks.xcodeproj -scheme AustrianRocks -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.3.1' -only-testing:AustrianRocksTests` → **TEST SUCCEEDED**, 16 tests passed, and the existing Mapbox-based app target built during the test action. A local ignored `AustrianRocks/Config/Secrets.xcconfig` was copied from `Secrets.sample.xcconfig` to satisfy the existing project base configuration.
- Key decisions:
  - The spec commit `0c9dd19c` is one commit behind current HEAD `3e3720ef`; the intervening changes are incant artifacts only, so no app or Rails code invalidates the spec.
  - Use the Rails manifest at `https://tiles.austrian.rocks/map_tiles/current.json` and load `styles.light` or `styles.dark`; do not add an iOS PMTiles adapter because MapLibre Native iOS 6.10.0+ handles `pmtiles://https://...` style sources.
  - Keep iOS-native problem details and use native SwiftUI cards for region, cluster, area, and POI selections; tile properties are the display source and SQLite is only used for optional native detail navigation.
  - Treat the Rails shared layer/property contract as authoritative: `problemId`, `areaId`, `clusterId`, `regionId`, `poiId`; selected layers `problems-selected`, `areas-selected`, `clusters-selected`, `regions-selected`, `pois-selected`; cleared sentinel `-1`.

## Files touched
- `AustrianRocks.xcodeproj/project.pbxproj` (edit) — replace Mapbox package/products/scripts with MapLibre, add renamed map files and the XCTest target files to both app targets as appropriate.
- `AustrianRocks.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` (edit) — resolve MapLibre Native iOS `>= 6.10.0` and remove Mapbox/Turf pins.
- `AustrianRocks.xcodeproj/xcshareddata/xcschemes/AustrianRocks.xcscheme` (new or edit) — include `AustrianRocksTests` in the app scheme's test action.
- `AustrianRocks/Config/BrandConfig.swift` (edit) — replace `BrandConfig.Mapbox` with a centralized `BrandConfig.MapTiles` config holding manifest URL and cache keys.
- `AustrianRocks/UI/Map/MapboxView.swift` (delete after rename) — remove the Mapbox-named SwiftUI bridge.
- `AustrianRocks/UI/Map/MapboxViewController.swift` (delete after rename) — remove the Mapbox-named UIKit controller.
- `AustrianRocks/UI/Map/MapLibreView.swift` (new) — SwiftUI bridge that passes `MapState` into `MapLibreViewController` and delegates native selections back to SwiftUI.
- `AustrianRocks/UI/Map/MapLibreViewController.swift` (new) — MapLibre Native UIKit controller for manifest/style loading, gestures, rendering callbacks, camera, queries, filters, and selection.
- `AustrianRocks/UI/Map/MapContainerView.swift` (edit) — render `MapLibreView`, show map-unavailable retry UI, present native feature cards, and preserve existing overlays and problem sheet behavior.
- `AustrianRocks/UI/Map/MapState.swift` (edit) — add native map-card selection state, map load retry triggers, and explicit clear-selection helpers while preserving problem/topo state.
- `AustrianRocks/UI/Map/PoiActionSheet.swift` (edit) — keep existing external-maps behavior reusable from the POI map card without showing broken Google directions actions.
- `AustrianRocks/UI/Map/MapTileManifest.swift` (new) — typed manifest model with `version`, `pmtilesUrl`, `spriteUrl`, `styles.light`, `styles.dark`, and `publishedAt` decoding.
- `AustrianRocks/UI/Map/MapTileManifestClient.swift` (new) — no-store manifest fetcher with injectable `URLSession` for tests.
- `AustrianRocks/UI/Map/MapTileStyleCache.swift` (new) — last-known manifest/style persistence and fallback resolution.
- `AustrianRocks/UI/Map/MapStyleChoice.swift` (new) — light/dark style selection and color-scheme mapping.
- `AustrianRocks/UI/Map/MapLayerContract.swift` (new) — typed constants for shared source/layer ids, selected-layer ids, id properties, and sentinel values.
- `AustrianRocks/UI/Map/MapSelectionController.swift` (new) — MapLibre selected-layer filter state machine plus grow/shrink/wiggle animation helpers.
- `AustrianRocks/UI/Map/MapFeatureBounds.swift` (new) — safe tile bounds parsing and region main-cluster bounds preference.
- `AustrianRocks/UI/Map/MapFeatureCardModel.swift` (new) — parse untrusted PMTiles properties into native region/cluster/area/POI card view models.
- `AustrianRocks/UI/Map/MapFeatureCardView.swift` (new) — SwiftUI native bottom/docked map card UI with CTAs and missing-detail states.
- `AustrianRocks/UI/Map/MapFeatureCardGradeHistogramView.swift` (new) — native grade histogram rendering from `gradeHistogramJson`.
- `AustrianRocks/UI/Map/MapUnavailableOverlay.swift` (new) — non-blocking retry/unavailable overlay when fresh and cached style initialization both fail.
- `AustrianRocks/Models/Poi.swift` (edit) — allow card-created POIs to omit an unsafe Google URL while preserving existing SQLite POIs.
- `AustrianRocks/Models/AcknowledgementCatalog.swift` (edit) — update audit comment from planned Mapbox migration to current MapLibre audit guidance.
- `AustrianRocks/Acknowledgements.json` (edit) — replace removed Mapbox package notices with MapLibre Native iOS and resolved non-Apple Swift Package dependency notices.
- `AustrianRocks/en.lproj/Localizable.strings` (edit) — add English labels for map cards, unavailable/retry states, CTAs, missing detail, POI types, and histogram/access rows.
- `AustrianRocks/de.lproj/Localizable.strings` (edit) — add German labels for map cards, unavailable/retry states, CTAs, missing detail, POI types, and histogram/access rows.
- `AustrianRocksTests/MapTileManifestTests.swift` (new) — manifest decoding and light/dark style selection tests.
- `AustrianRocksTests/MapTileStyleCacheTests.swift` (new) — last-known manifest/style fallback tests with no network dependency.
- `AustrianRocksTests/MapFeatureCardModelTests.swift` (new) — PMTiles property parsing, localization, optional-row omission, bounds, histogram, and missing SQLite detail action tests.
- `AustrianRocksTests/SafeURLTests.swift` (new) — HTTP(S)-only URL validation tests for guidebook, parking, and POI directions fields.
- `AustrianRocksTests/MissingDetailActionTests.swift` (new) — absent `Region`, `Cluster`, or `Area` records hide/disable secondary detail navigation without crashing.
- `README.md` (edit) — remove Mapbox token setup and document that maps load the Rails MapLibre manifest without local token files.

## Phase 0005-P1 — pure map contract support and tests
Goal: add the pure Swift seams for manifest loading, style fallback, tile-property parsing, localization, safe URLs, and missing-detail behavior before touching the map engine.

- [x] Step 1: read `AustrianRocks/Config/BrandConfig.swift`, `AustrianRocks/UI/Map/MapState.swift`, `AustrianRocks/UI/Map/PoiActionSheet.swift`, `AustrianRocks/Models/Poi.swift`, `AustrianRocks/en.lproj/Localizable.strings`, and `AustrianRocks/de.lproj/Localizable.strings` before editing.
- [x] Step 2: add `BrandConfig.MapTiles` to `AustrianRocks/Config/BrandConfig.swift` with `manifestURL = URL(string: "https://tiles.austrian.rocks/map_tiles/current.json")!`, `lastKnownManifestCacheKey = "mapTiles.lastKnownManifest"`, and `lastKnownStyleCacheKey = "mapTiles.lastKnownStyle"`; leave `BrandConfig.Mapbox` in place for this phase so the existing app still builds.
- [x] Step 3: create `AustrianRocks/UI/Map/MapStyleChoice.swift` with `enum MapStyleChoice { case light, dark }`, `init(userInterfaceStyle: UIUserInterfaceStyle)`, and `manifestKey` returning `"light"` or `"dark"`.
- [x] Step 4: create `AustrianRocks/UI/Map/MapTileManifest.swift` with `Decodable` structs for `version`, `pmtilesUrl`, `spriteUrl`, `styles.light`, `styles.dark`, `publishedAt`, URL validation that accepts only HTTP(S) manifest/style/sprite/PMTiles URLs, and `styleURL(for:)` that throws a typed error when a style is missing or invalid.
- [x] Step 5: create `AustrianRocks/UI/Map/MapTileManifestClient.swift` with `func fetchManifest(from url: URL) async throws -> MapTileManifest` using `URLRequest(cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)`, status-code validation, and injected `URLSession`/data-loader closure for tests.
- [x] Step 6: create `AustrianRocks/UI/Map/MapTileStyleCache.swift` with `recordSuccess(manifest:choice:styleURL:)`, `lastKnownStyle(for:)`, and `clear()` backed by injected `UserDefaults`; persist the manifest JSON and chosen style URL without storing secrets.
- [x] Step 7: create `AustrianRocks/UI/Map/MapLayerContract.swift` containing source id `austrian-rocks`, layer ids `problems`, `boulders`, `areas`, `areas-hulls`, `clusters`, `cluster-hulls`, `regions`, `region-hulls`, `pois`, selected-layer ids, id property names, and `clearedSentinel = -1`.
- [x] Step 8: create `AustrianRocks/UI/Map/MapFeatureBounds.swift` to parse numeric `southWestLat`, `southWestLon`, `northEastLat`, `northEastLon`, prefer `mainClusterSouthWestLat/Lon` and `mainClusterNorthEastLat/Lon` for region show-on-map when valid, and reject missing/non-finite values.
- [x] Step 9: create `AustrianRocks/UI/Map/MapFeatureCardModel.swift` that builds region/cluster/area/POI card models from `[String: Any]` tile properties: localized title uses `nameEn` for English when present otherwise `name`; optional rows are omitted when absent; histogram JSON is parsed into ordered grade entries; guidebook/parking/Google links use HTTP(S)-only URL validation; secondary detail availability checks `Region.load`, `Cluster.load`, or `Area.load` by id without force-unwrapping.
- [x] Step 10: edit `AustrianRocks/Models/Poi.swift` so non-SQLite POI card values can represent `googleUrl` as optional while existing `Poi.load` still fills SQLite POIs with their stored URL.
- [x] Step 11: add English and German localization keys for `map.card.show_on_map`, `map.card.details`, `map.card.details_unavailable`, `map.card.directions`, `map.card.warning`, `map.card.guidebook`, `map.card.problems`, `map.card.grade_distribution`, `map.card.close`, `map.unavailable.title`, `map.unavailable.message`, `map.unavailable.retry`, `map.poi_type.parking`, and `map.poi_type.train_station`.
- [x] Step 12: add `AustrianRocksTests` XCTest target to `AustrianRocks.xcodeproj/project.pbxproj` and `AustrianRocks.xcodeproj/xcshareddata/xcschemes/AustrianRocks.xcscheme`, then create `AustrianRocksTests/MapTileManifestTests.swift`, `AustrianRocksTests/MapTileStyleCacheTests.swift`, `AustrianRocksTests/MapFeatureCardModelTests.swift`, `AustrianRocksTests/SafeURLTests.swift`, and `AustrianRocksTests/MissingDetailActionTests.swift` covering the pure seams from the spec.

**Quality gate:** `xcodebuild test -project AustrianRocks.xcodeproj -scheme AustrianRocks -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:AustrianRocksTests` → the new XCTest target builds, all pure map-support tests pass, and the existing Mapbox-based app target still builds during the test action.

## Phase 0005-P2 — MapLibre dependency, manifest style loading, and unavailable fallback
Goal: replace the SDK and create a working MapLibre map that loads the Rails shared style, retries via fresh manifest/cache fallback, and no longer needs Mapbox token files.

- [x] Step 1: read `AustrianRocks.xcodeproj/project.pbxproj`, `AustrianRocks.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`, `AustrianRocks/UI/Map/MapboxView.swift`, `AustrianRocks/UI/Map/MapboxViewController.swift`, `AustrianRocks/UI/Map/MapContainerView.swift`, `AustrianRocks/Config/BrandConfig.swift`, and `README.md` before editing.
- [x] Step 2: in `AustrianRocks.xcodeproj/project.pbxproj`, remove the `mapbox-maps-ios` package reference, `MapboxMaps` product dependencies, `MapboxMaps in Frameworks` entries, Mapbox shell-script build phases that read `~/.mapbox` or `~/mapbox`, and transitive Mapbox/Turf pins by resolving packages after adding MapLibre's public SwiftPM distribution package `https://github.com/maplibre/maplibre-gl-native-distribution.git` with an up-to-next-major requirement starting at `6.10.0` and product `MapLibre` for both `AustrianRocks` and `AustrianRocks dev` targets.
- [x] Step 3: rename `AustrianRocks/UI/Map/MapboxView.swift` to `AustrianRocks/UI/Map/MapLibreView.swift`; rename `MapboxView` to `MapLibreView`, `MapBoxViewDelegate` to `MapLibreViewDelegate`, coordinator comments to MapLibre-neutral wording, and imports from `MapboxMaps` to `MapLibre`.
- [x] Step 4: rename `AustrianRocks/UI/Map/MapboxViewController.swift` to `AustrianRocks/UI/Map/MapLibreViewController.swift`; rename the class and comments, import `MapLibre`, use MapLibre Native equivalents for map view construction, camera state, location puck/user tracking, ornaments/attribution, style loaded callbacks, tap gestures, camera-change throttling, query-rendered-features, layer/source updates, camera fitting, and fly/ease animation.
- [x] Step 5: remove the current Mapbox-hosted `lightStyleURI`, `darkStyleURI`, `BrandConfig.Mapbox.problemsTilesetURL`, manual vector-source setup, and custom `problems` source creation from the controller; initialize MapLibre with a resolved HTTP(S) style URL from `MapTileManifestClient`/`MapTileStyleCache`, relying on the shared style's `austrian-rocks` PMTiles source, glyphs, sprites, basemap.at, terrain, contours, and overlay layers.
- [x] Step 6: edit `AustrianRocks/UI/Map/MapContainerView.swift` so the `mapbox` computed property becomes `mapLibre`, renders `MapLibreView(mapState:)`, and overlays `MapUnavailableOverlay` only when the controller reports that neither a fresh manifest nor a cached style initialized the map.
- [x] Step 7: edit `AustrianRocks/UI/Map/MapState.swift` to add `mapUnavailableMessage`, `mapRetryCount`, `requestMapRetry()`, `markMapUnavailable(_:)`, and `markMapAvailable()` so retry UI is native and non-blocking.
- [x] Step 8: implement trait/color-scheme changes in `MapLibreViewController` by resolving `MapStyleChoice(userInterfaceStyle:)`, fetching the latest manifest with no-store, recording successful `styles.light` or `styles.dark` into `MapTileStyleCache`, falling back to the cached choice if fetch fails, and showing unavailable state only when no fresh or cached URL can load.
- [x] Step 9: edit `README.md` to remove Mapbox account, `~/.mapbox`, and `.netrc` instructions and document that maps use the Rails-published MapLibre manifest with no local token setup.
- [x] Step 10: run package resolution so `AustrianRocks.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` contains MapLibre Native iOS `>= 6.10.0`, SQLite, and no Mapbox/Turf pins.

**Quality gate:** `xcodebuild -resolvePackageDependencies -project AustrianRocks.xcodeproj && xcodebuild -project AustrianRocks.xcodeproj -scheme AustrianRocks -configuration Debug -destination 'generic/platform=iOS Simulator' build && xcodebuild -project AustrianRocks.xcodeproj -scheme 'AustrianRocks dev' -configuration Debug -destination 'generic/platform=iOS Simulator' build` → package resolution succeeds, both app schemes build for a generic iOS Simulator destination, and no Mapbox token file is required.

## Phase 0005-P3 — shared selection, problem flow, filters, and camera context
Goal: port interaction behavior to the Rails shared layer contract while preserving iOS problem details, topo selection, filters, and panning-based area/cluster context.

- [ ] Step 1: read `AustrianRocks/UI/Map/MapLibreView.swift`, `AustrianRocks/UI/Map/MapLibreViewController.swift`, `AustrianRocks/UI/Map/MapState.swift`, `AustrianRocks/Models/Problem.swift`, `AustrianRocks/Models/Area.swift`, `AustrianRocks/Models/Cluster.swift`, `AustrianRocks/Models/Region.swift`, `/Users/maximilianblazek/Documents/GitHub/austrian-rocks-rails/app/javascript/map/selection.js`, and `/Users/maximilianblazek/Documents/GitHub/austrian-rocks-rails/app/javascript/controllers/map_controller.js` before editing.
- [ ] Step 2: create `AustrianRocks/UI/Map/MapSelectionController.swift` to manage one selected feature at a time with selected-layer filters using the id property and `-1` sentinel; exclude selected region/cluster/area/POI ids from base symbol layers when those layers exist; skip base exclusion for problems.
- [ ] Step 3: implement selected grow/settle/shrink animation constants matching Rails: icon grow scale `1.25`, icon clear scale `0.72`, circle grow scale `1.4`, circle clear scale `1.0`, grow duration about `520 ms`, clear duration about `220 ms`, symbol wiggle about `5°`; mutate MapLibre layer paint/layout properties and restore original values after clear.
- [ ] Step 4: update tap queries in `MapLibreViewController` to use shared layer ids and properties: `problems.problemId`, `areas.areaId`, `areas-hulls.areaId`, `clusters.clusterId`, `cluster-hulls.clusterId`, `regions.regionId`, `region-hulls.regionId`, and `pois.poiId/poiType/googleUrl`; preserve zoom predicates from Rails where compatible with iOS UX.
- [ ] Step 5: for problem taps, load `Problem.load(id: problemId)`, call `mapState.selectProblem(problem, source: .map)`, set `presentProblemDetails = true`, select through `problems-selected`, and keep topo sibling selection by passing cached sibling problem ids from `MapLibreView` into the controller.
- [ ] Step 6: for empty/background taps and changing selections, clear the prior selected layer with the animated shrink and dismiss only map-card selections; preserve `ProblemDetailsView` dismissal behavior for problem deselection.
- [ ] Step 7: port `applyFilters(_:)` to MapLibre style APIs using shared `problems` and `problems-selected` layers with `grade`, `featured`, `problemId`, local favorites, and local ticks; use `problemId` instead of the old Mapbox `id` property and document that iOS keeps popular/favorite/ticked filters in addition to Rails grade filtering.
- [ ] Step 8: port camera operations for `centerOnProblem`, `centerOnArea`, `centerOnBoulderCoordinates`, `centerOnCurrentLocation`, show-on-map bounds fitting, fly/ease animations, safe padding, and post-animation detector triggers to MapLibre APIs.
- [ ] Step 9: preserve camera-based area and cluster inference by querying `areas-hulls` when zoom is above `14.5`, `cluster-hulls` when zoom is at least `12`, updating `mapState.selectedArea` and `mapState.selectedCluster`, and clearing area below `14.5` and cluster below `11`.
- [ ] Step 10: ensure required attribution remains visible through MapLibre's attribution control and the shared style source attributions; keep the scale bar hidden and position compass/attribution similarly to the current iOS UI without hiding attribution.

**Quality gate:** `xcodebuild test -project AustrianRocks.xcodeproj -scheme AustrianRocks -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:AustrianRocksTests && xcodebuild -project AustrianRocks.xcodeproj -scheme AustrianRocks -configuration Debug -destination 'generic/platform=iOS Simulator' build && xcodebuild -project AustrianRocks.xcodeproj -scheme 'AustrianRocks dev' -configuration Debug -destination 'generic/platform=iOS Simulator' build` → pure tests pass and both schemes build after the MapLibre selection/filter/camera port.

## Phase 0005-P4 — native map cards and navigation/directions actions
Goal: add native SwiftUI cards for non-problem selectable features with tile-property-first content and graceful SQLite drift handling.

- [ ] Step 1: read `AustrianRocks/UI/Map/MapContainerView.swift`, `AustrianRocks/UI/Map/MapState.swift`, `AustrianRocks/UI/Map/PoiActionSheet.swift`, `AustrianRocks/UI/Discover/DiscoverRouter.swift`, `AustrianRocks/UI/Discover/RegionDetailView.swift`, `AustrianRocks/UI/Discover/ClusterDetailView.swift`, `AustrianRocks/UI/Map/AreaView.swift`, `AustrianRocks/en.lproj/Localizable.strings`, `AustrianRocks/de.lproj/Localizable.strings`, and `/Users/maximilianblazek/Documents/GitHub/austrian-rocks-rails/app/javascript/map/info_card.js` before editing.
- [ ] Step 2: edit `MapState` to store `selectedMapFeatureCard: MapFeatureCardModel?`, clear it when a problem is selected or background tap clears selection, and expose methods `selectMapFeatureCard(_:)`, `dismissMapFeatureCard()`, and `openPoiDirections(_:)` that do not interfere with `presentProblemDetails` or topo mode.
- [ ] Step 3: create `AustrianRocks/UI/Map/MapFeatureCardGradeHistogramView.swift` rendering the parsed grade histogram with localized accessibility text and no rows when the histogram is absent or invalid.
- [ ] Step 4: create `AustrianRocks/UI/Map/MapFeatureCardView.swift` as a native SwiftUI card docked above the map on wide screens and bottom-aligned on phones; render cover photo when `coverPhotoUrl` is safe, localized title, problem count, grade range/histogram, warning, guidebook link, parking/directions rows, and omit absent optional rows cleanly.
- [ ] Step 5: implement primary CTA behavior for region/cluster/area cards by calling back into `MapLibreViewController` to fit bounds from `MapFeatureBounds`; region cards must prefer main-cluster bounds when valid and fall back to region bounds.
- [ ] Step 6: implement secondary CTA behavior for region/cluster/area cards: if `Region.load`, `Cluster.load`, or `Area.load` succeeds, open the existing native `RegionDetailView`, `ClusterDetailView`, or `AreaView`; if the SQLite record is absent, hide the action or show a localized unavailable disabled state instead of crashing.
- [ ] Step 7: implement POI card directions as the primary CTA only when `googleUrl` is a validated HTTP(S) URL; preserve Apple Maps and Waze behavior by adapting the existing `PoiActionSheet` helpers or equivalent native `openURL` actions; never show a broken Google Maps action.
- [ ] Step 8: edit `MapLibreView.Coordinator` and `MapLibreViewController` delegate methods so region/cluster/area/POI taps build `MapFeatureCardModel` from tile properties and show cards, while problem taps still present `ProblemDetailsView` directly with no intermediate card.
- [ ] Step 9: connect card close buttons to selection clearing so selected-layer filters return to `-1`, base layers restore, animations shrink, and `selectedMapFeatureCard` becomes nil.
- [ ] Step 10: verify English and German localization coverage for every new label/action/error string used by `MapFeatureCardView`, `MapFeatureCardGradeHistogramView`, and `MapUnavailableOverlay`.

**Quality gate:** `xcodebuild test -project AustrianRocks.xcodeproj -scheme AustrianRocks -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:AustrianRocksTests && xcodebuild -project AustrianRocks.xcodeproj -scheme AustrianRocks -configuration Debug -destination 'generic/platform=iOS Simulator' build && xcodebuild -project AustrianRocks.xcodeproj -scheme 'AustrianRocks dev' -configuration Debug -destination 'generic/platform=iOS Simulator' build` → card parsing/action tests pass, new localized SwiftUI card code compiles, and both schemes build.

## Phase 0005-P5 — legal/docs cleanup and final verification
Goal: remove remaining Mapbox references from active code/project/docs, update acknowledgements, and prove the migration acceptance criteria.

- [ ] Step 1: read `AustrianRocks/Acknowledgements.json`, `AustrianRocks/Models/AcknowledgementCatalog.swift`, `AustrianRocks.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`, `README.md`, and MapLibre/SQLite license files from Xcode `SourcePackages/checkouts` before editing legal notices.
- [ ] Step 2: update `AustrianRocks/Acknowledgements.json` audit metadata from the resolved package pins, replacing Mapbox Maps, Mapbox Common, Mapbox Core Maps, and Turf entries with MapLibre Native iOS plus current non-Apple Swift Package dependencies; keep SQLite and app notices current; remove obsolete Mapbox omission notes.
- [ ] Step 3: edit `AustrianRocks/Models/AcknowledgementCatalog.swift` comments so the audit guidance describes the current MapLibre dependency audit instead of a planned Mapbox migration.
- [ ] Step 4: run `xcodebuild -list -project AustrianRocks.xcodeproj` and confirm the schemes are `AustrianRocks` and `AustrianRocks dev` only, with no Mapbox package scheme listed.
- [ ] Step 5: run `rg -n "import MapboxMaps|BrandConfig\\.Mapbox|MBXAccessToken|~/.mapbox|api\\.mapbox\\.com|mapbox-(maps|common|core-maps)-ios|turf-swift|MapboxMaps" AustrianRocks AustrianRocks.xcodeproj README.md AustrianRocks.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` and ensure it returns no matches.
- [ ] Step 6: run the full automated test/build suite and read the output: `xcodebuild test -project AustrianRocks.xcodeproj -scheme AustrianRocks -destination 'platform=iOS Simulator,name=iPhone 16' && xcodebuild -project AustrianRocks.xcodeproj -scheme AustrianRocks -configuration Debug -destination 'generic/platform=iOS Simulator' build && xcodebuild -project AustrianRocks.xcodeproj -scheme 'AustrianRocks dev' -configuration Debug -destination 'generic/platform=iOS Simulator' build`.
- [ ] Step 7: manually verify in the iPhone 16 simulator or a device: online map loads the Rails shared style; light/dark mode reloads `styles.light`/`styles.dark`; PMTiles problem/area/cluster/region/POI layers render; selected pins/circles grow, settle, and shrink; problem taps open `ProblemDetailsView`; region/cluster/area/POI taps show native cards; show-on-map fits bounds; missing SQLite detail actions are safe; POI directions opens only for valid URLs; grade/popular/favorite/ticked filters affect problem rendering; area toolbar/download context update while panning; retry overlay appears only when fresh and cached styles cannot initialize; attribution remains visible.
- [ ] Step 8: update this plan's Status block phase/checklist as implementation progresses and commit completed implementation phases individually as `incant 0005-P1: ...` through `incant 0005-P5: ...`.

**Quality gate:** `xcodebuild -list -project AustrianRocks.xcodeproj && rg -n "import MapboxMaps|BrandConfig\\.Mapbox|MBXAccessToken|~/.mapbox|api\\.mapbox\\.com|mapbox-(maps|common|core-maps)-ios|turf-swift|MapboxMaps" AustrianRocks AustrianRocks.xcodeproj README.md AustrianRocks.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved; test $? -eq 1 && xcodebuild test -project AustrianRocks.xcodeproj -scheme AustrianRocks -destination 'platform=iOS Simulator,name=iPhone 16' && xcodebuild -project AustrianRocks.xcodeproj -scheme AustrianRocks -configuration Debug -destination 'generic/platform=iOS Simulator' build && xcodebuild -project AustrianRocks.xcodeproj -scheme 'AustrianRocks dev' -configuration Debug -destination 'generic/platform=iOS Simulator' build` → only app schemes are listed, the Mapbox-removal search has no matches, all tests pass, and both schemes build.

## Requirements coverage self-review
- [x] R1, R2: Phase 0005-P2 replaces package/products/scripts and removes token setup; Phase 0005-P5 verifies no Mapbox package or token references remain.
- [x] R3, R4, R5, R6, R7: Phases 0005-P1 and 0005-P2 add centralized manifest config, light/dark style resolution, built-in PMTiles style loading, cache fallback, and native retry/unavailable UI.
- [x] R8, R14, R15: Phase 0005-P3 preserves direct native problem details/topo support and implements the selected-layer sentinel/filter animation model.
- [x] R9, R10, R11, R12, R13: Phase 0005-P4 adds native non-problem cards, tile-property rendering, bounds/directions CTAs, native detail actions, and missing-SQLite safeguards.
- [x] R16, R17, R18: Phase 0005-P3 preserves camera-based area/cluster inference, iOS filters, search/current-location/download overlays, and topo/problem navigation patterns.
- [x] R19: Phase 0005-P2 renames Mapbox bridge/controller/config surfaces to MapLibre-neutral names.
- [x] R20: Phases 0005-P1 and 0005-P4 add English/German strings and localized feature title selection.
- [x] R21: Phase 0005-P3 keeps MapLibre attribution and shared style source attributions visible.
- [x] R22: Phase 0005-P5 updates acknowledgements and audit metadata from resolved packages.
- [x] R23: Phase 0005-P1 creates XCTest coverage for manifest/cache/card parsing/localization/safe URL/missing-detail behavior; later phases keep it passing.
- [x] R24: Phases 0005-P2 through 0005-P5 build both app schemes without Mapbox token files.
- [x] Acceptance criteria: Phase 0005-P5 includes the final `xcodebuild -list`, package/static-search, test/build, and manual simulator verification evidence needed before review.
- [x] Symbol/signature consistency: planned names use `MapLibreView`, `MapLibreViewController`, `MapLibreViewDelegate`, `MapTileManifest`, `MapTileManifestClient`, `MapTileStyleCache`, `MapLayerContract`, `MapSelectionController`, `MapFeatureBounds`, `MapFeatureCardModel`, `MapFeatureCardView`, `MapFeatureCardGradeHistogramView`, and `MapUnavailableOverlay` consistently.
- [x] Completeness check: every phase has concrete paths, actions, commands, expected results, and named follow-up work.
