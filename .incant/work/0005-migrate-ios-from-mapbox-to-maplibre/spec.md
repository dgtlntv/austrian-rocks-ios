---
id: "0005"
slug: migrate-ios-from-mapbox-to-maplibre
branch: incant/0005-migrate-ios-from-mapbox-to-maplibre
title: Migrate iOS From Mapbox To MapLibre
stage: spec
status: approved
created: 2026-06-11
commit: 0c9dd19c
updated: 2026-06-11
---

# Migrate iOS From Mapbox To MapLibre

## Goal
Replace the iOS app's Mapbox-based map with a MapLibre Native iOS map that consumes the Rails-published Austrian.rocks PMTiles manifest, shared styles, glyphs, sprites, and interaction contract while preserving current native iOS problem details, filters, area/cluster context, and download-entry behavior.

## Context & codebase fit
The current iOS app is a SwiftUI/UIKit hybrid with a Mapbox UIKit bridge embedded in the SwiftUI map container:

- `AustrianRocks/UI/Map/MapContainerView.swift` renders `MapboxView`, overlays search, area toolbar, download/location FABs, and presents `ProblemDetailsView` as the native problem bottom sheet.
- `AustrianRocks/UI/Map/MapboxView.swift` bridges SwiftUI `MapState` into `MapboxViewController` and maps UIKit callbacks back to native selections for problems, areas, clusters, regions, and POIs.
- `AustrianRocks/UI/Map/MapboxViewController.swift` imports `MapboxMaps`, creates `MapView`, injects Mapbox-hosted style/tileset sources from `BrandConfig.Mapbox`, manually adds problem circles/name layers, queries rendered features on taps, updates feature-state for selected problems/topo siblings, applies iOS-only filters, infers area/cluster from the map center, and drives fly/ease camera behavior.
- `AustrianRocks/Config/BrandConfig.swift` still has `BrandConfig.Mapbox` with Mapbox account/style/tileset URLs. The Xcode project still depends on `mapbox-maps-ios`, `mapbox-common-ios`, `mapbox-core-maps-ios`, and `turf-swift`, and still contains build scripts that inject `MBXAccessToken` from `~/.mapbox`.
- `AustrianRocks/Acknowledgements.json` and `AustrianRocks/Models/AcknowledgementCatalog.swift` were prepared for third-party legal notices and still list Mapbox SDK packages; the backlog explicitly requires replacing those acknowledgements with MapLibre entries.
- `README.md` still documents Mapbox public/secret token setup.
- The Rails app at `/Users/maximilianblazek/Documents/GitHub/austrian-rocks-rails` has already moved the web map to MapLibre GL JS plus PMTiles. Its `config/map_tiles.yml`, `config/map_styles/README.md`, `docs/map_tiles.md`, and `tmp/map_tiles/current.json` define the shared artifact contract: clients fetch `https://tiles.austrian.rocks/map_tiles/current.json`, choose `styles.light` or `styles.dark`, and load the style's `pmtiles://https://...` source, self-hosted Inter glyphs, versioned sprite, basemap.at sources, terrain/contour layers, and Austrian Rocks overlay layers.
- Rails `app/javascript/controllers/map_controller.js`, `app/javascript/map/selection.js`, and `app/javascript/map/info_card.js` define the shared interaction model: selectable region/cluster/area/POI pins and selected layers, `problems-selected`, sentinel `-1` filters, grow/shrink animation, bottom/docked cards, feature-property card content, and “show on map” camera fitting.
- The current iOS app has native `RegionDetailView`, `ClusterDetailView`, `AreaView`, POI directions handling, and `ProblemDetailsView`; the migration should use native SwiftUI views/cards rather than web HTML or WebViews.

## Requirements
1. Replace the Mapbox iOS SDK dependency with the official MapLibre Native iOS Swift Package at a version `>= 6.10.0`, because MapLibre Native iOS supports `pmtiles://` vector sources starting at 6.10.0.
2. Remove Mapbox SDK products, Mapbox transitive package pins, Mapbox access-token build scripts, `MBXAccessToken` injection, and README instructions that require `~/.mapbox` or `.netrc` Mapbox tokens.
3. Add a centralized MapLibre/map-tile configuration surface under `BrandConfig` or an equivalent dedicated config module, with the manifest URL defaulting to `https://tiles.austrian.rocks/map_tiles/current.json` for current app targets and with no map URLs scattered through map controller logic.
4. Fetch the Rails-published manifest, select `styles.light` or `styles.dark` from the current iOS color scheme, and initialize MapLibre from that versioned style URL so iOS uses the same PMTiles, sprites, glyphs, basemap.at style sources, terrain/contours, and Austrian Rocks overlay layers as the Rails web map.
5. Use MapLibre Native's built-in `pmtiles://https://...` support for remote PMTiles; do not add a PMTiles adapter dependency, rewrite the Rails artifact pipeline, or run a local tile server in the app for this item.
6. Cache the last successfully loaded manifest/style choice locally and use it as a best-effort fallback when the manifest fetch fails, so previously viewed/cached map resources can still load in airplane mode or transient network failures when MapLibre's own resource cache has the necessary files.
7. Show a native non-blocking “map unavailable” overlay/card with retry only when neither a fresh manifest nor a cached last-known manifest/style can initialize the map; the rest of the app must remain usable and there must be no fallback to Mapbox.
8. Preserve iOS's current native problem behavior: tapping a problem opens/presents the existing `ProblemDetailsView` flow directly, keeps topo selection support, and does not insert a lightweight intermediate problem card.
9. Add native iOS map cards for non-problem selectable features: regions, clusters, areas, and POIs. These cards must be SwiftUI/native UIKit views, not WebViews or Rails-rendered HTML.
10. Render native map-card content from PMTiles feature properties according to the Rails shared contract: localized title, problem count, grade range/histogram, cover photo, warning, guidebook, parking, bounds, and POI direction fields when present; omit absent optional rows cleanly.
11. For region, cluster, and area cards, make the primary CTA “show on map” / fit or zoom to that entity using feature bounds, with region cards preferring main-cluster bounds when those properties are present. The secondary CTA opens the existing native detail view (`RegionDetailView`, `ClusterDetailView`, or `AreaView`) when the corresponding SQLite record exists.
12. For POI cards, make directions the primary CTA when `googleUrl` is present and preserve the existing native external-maps/directions behavior. If no usable directions URL exists, the card must not show a broken directions action.
13. Handle PMTiles-to-SQLite drift gracefully: map cards must display from tile properties even when the matching SQLite record is absent, and secondary native-detail navigation must be hidden or disabled with a clear unavailable state rather than crashing.
14. Implement the shared selection-state model for selectable layers where MapLibre Native supports it: one selected entity at a time, selected layer filters using the entity id and `-1` cleared sentinel, base symbol exclusion for selected symbol pins where needed, and problem selection through `problems-selected` rather than Mapbox `feature-state`.
15. Match the web-led selection animation style: selected symbol pins grow/settle with a subtle wiggle, selected problem circles grow/settle, clearing shrinks/restores, and selecting a new feature clears the previous selection first.
16. Keep iOS-specific camera-based area and cluster inference from the map center so the area toolbar, selected cluster, and download button context continue to update while panning/zooming.
17. Preserve iOS-specific native filters (`gradeRange`, popular, favorites, ticked) on top of the shared `problems` layer using shared PMTiles properties and local persistence data; document any intentional difference from Rails web, whose current UI applies grade filtering only.
18. Preserve existing SwiftUI map overlays and navigation patterns: search overlay/sheet, area toolbar, current-location FAB, download FAB/placeholder, POI action flow, and problem details/fullscreen/topo behavior must continue to work after the map engine migration.
19. Rename Mapbox-specific iOS bridge/controller files, types, comments, and config names to MapLibre-neutral names such as `MapLibreView` / `MapLibreViewController` or `MapViewBridge` / `MapViewController`, except where historical legal notices require the word Mapbox.
20. Add or update English and German localizations for all new map-card labels, actions, empty/unavailable states, and retry/error text. Localized feature names must use `nameEn` when the app language is English and that PMTiles property exists, otherwise `name`.
21. Keep required map attribution visible through MapLibre's attribution mechanisms and the style source attributions, including basemap.at attribution from the shared style.
22. Update `Acknowledgements.json` and related audit metadata from `Package.resolved` so in-app third-party notices list MapLibre Native iOS and its resolved non-Apple Swift Package dependencies, and no longer list removed Mapbox SDK packages.
23. Add an XCTest target or equivalent automated test target for pure migration support code: manifest decoding, last-known manifest/style cache fallback, PMTiles feature-property card model parsing/localization selection, safe URL validation, and graceful missing-SQLite-detail behavior.
24. The app must build for both `AustrianRocks` and `AustrianRocks dev` schemes after the migration without requiring local Mapbox token files.

## In scope / Out of scope
**In scope:**
- Mapbox-to-MapLibre dependency replacement and Xcode project/package updates.
- Shared Rails manifest/style/PMTiles/sprite/glyph consumption in iOS.
- Best-effort last-known manifest/style fallback and retry UI for map initialization failures.
- Native iOS selection model, selected-layer animation, and feature interaction for regions, clusters, areas, POIs, and problems.
- Native iOS map cards for region/cluster/area/POI selections, with tile-property content and native detail/directions actions.
- Existing problem details, current-location, search, area toolbar, download button context, and iOS filters continuing to work.
- MapLibre-neutral naming cleanup for map bridge/controller/config surfaces.
- English/German localization for new UI strings.
- README and legal acknowledgement updates caused by the dependency migration.
- Automated tests for pure parsing/cache/card-model/error-handling seams plus manual simulator verification for MapLibre rendering and gestures.

**Out of scope:**
- Guaranteed offline map downloads, resumable PMTiles downloads, or region/area/cluster offline coverage — reason: backlog item `0006` owns offline maps and resumable downloads.
- A full PMTiles ↔ bundled SQLite ↔ Rails DB data-version parity contract — reason: the user wants that coupling later; `0005` only handles drift gracefully.
- Rails map artifact pipeline changes — reason: Rails already publishes the target manifest/styles/PMTiles/sprites/glyphs for this migration.
- Rails web UI changes — reason: this item changes the iOS app while following the web contract.
- WebViews or Rails-rendered HTML cards in iOS — reason: selected feature cards must be native iOS views.
- Reworking `ProblemDetailsView` design — reason: it is already the desired native problem card/detail experience.
- Circuit cleanup — reason: backlog item `0007` owns removing remaining circuit-specific code/data.
- Broad Discover-card redesign beyond detail destinations used by map-card secondary CTAs — reason: backlog item `0008` owns Discover card rework.
- App Store release metadata unrelated to map dependencies — reason: completed item `0004` covered privacy/App Review metadata, and this item only changes dependency/legal docs tied to MapLibre.

## Approach
Use Rails as the source of truth for map artifacts and interaction vocabulary, while keeping iOS native for presentation and navigation. Introduce a MapLibre-neutral map bridge/controller that fetches the manifest, records the last successful manifest/style selection, initializes MapLibre Native with the versioned shared style URL, and relies on the style's own PMTiles source, glyphs, sprites, basemap.at sources, terrain/contours, and Austrian Rocks layers. Port the shared selection-state behavior from the Rails `MapSelection` model into Swift/MapLibre Native concepts: selected layer filters, sentinel clearing, base-layer exclusion, one active selection, and lightweight grow/shrink animations.

Use PMTiles feature properties as the source for lightweight region/cluster/area/POI cards so card display does not block on SQLite and remains robust to tile/database drift. Use stable ids only for native secondary actions that navigate to existing detail views; those actions must tolerate missing local records. Keep current iOS-specific behavior where it is part of the app experience rather than the shared web baseline: direct `ProblemDetailsView` for problem taps, camera-based area/cluster inference for toolbar/download context, and native favorite/ticked/popular filters.

Rejected alternatives:
- Keeping Mapbox and only changing style URLs was rejected because the backlog explicitly requires replacing Mapbox with MapLibre and updating licenses.
- Porting Rails HTML cards or using WebViews was rejected because iOS already has native detail views and the desired card experience should be native.
- Building a separate iOS-only tiles/style pipeline was rejected because Rails already publishes the shared PMTiles/styles/glyphs/sprites contract.
- Adding a PMTiles adapter dependency was rejected after confirming MapLibre Native iOS `>= 6.10.0` supports `pmtiles://` sources directly.
- Implementing guaranteed offline downloads now was rejected because `0006` owns offline maps and resumable downloads; `0005` only preserves best-effort cache behavior and last-known manifest/style fallback.

## Considerations
### Config vs code
Map tile delivery configuration belongs in a dedicated config surface, not in map controller logic. The required configuration values are the manifest URL, default style preference behavior, and any cache keys for the last-known manifest/style fallback. The default manifest URL is `https://tiles.austrian.rocks/map_tiles/current.json` because Rails publishes the canonical current production map release there; both current iOS targets use it until a dev/E2E override is intentionally introduced.

The code should consume this config by injecting or reading the centralized config once in the map-loading layer, then passing resolved style URLs into MapLibre initialization. Layer ids and PMTiles property names are part of the shared Rails map contract and may be represented as typed constants/enums in the map module to avoid string drift, but they should not be duplicated as scattered literals across UI/card/filter code.

### Security
The main trust boundary is network-delivered map metadata and PMTiles feature properties. Manifest JSON, style URLs, sprite/glyph URLs, and feature properties must be treated as untrusted input: decode with typed models, validate expected URL schemes for user-opened links, and render text through SwiftUI `Text` rather than HTML interpolation. External card links are limited to documented HTTP(S) fields such as `guidebookUrl`, `parkingGoogleUrl`, and `googleUrl`; invalid or unsupported URLs must result in omitted actions/rows.

No Mapbox or MapLibre access tokens should be committed or required. Removing Mapbox token scripts reduces local secret handling. The migration must not write secrets into `.incant/`, source, README examples, or sessions. The blast radius of a bad manifest/style should be contained to the map surface: show retry/unavailable UI and keep the rest of the app usable. Missing SQLite records for tile ids must not crash or expose invalid navigation behavior.

### Testability
The migration needs both automated pure-code checks and manual rendering checks:
- Add an XCTest target or equivalent test target for manifest decoding, style selection by light/dark mode, last-known manifest/style cache fallback, map-card model parsing from representative PMTiles property dictionaries, localized title selection, safe URL validation, and missing-SQLite-detail action handling.
- Run the automated tests with an Xcode command such as `xcodebuild test -project AustrianRocks.xcodeproj -scheme AustrianRocks -destination 'platform=iOS Simulator,name=iPhone 16'` or the closest installed simulator destination discovered during planning.
- Build both app schemes with `xcodebuild -project AustrianRocks.xcodeproj -scheme AustrianRocks -configuration Debug -destination 'generic/platform=iOS Simulator' build` and the equivalent `AustrianRocks dev` build to catch project/package/resource errors.
- Use static searches to prove Mapbox SDK imports, Mapbox package pins, Mapbox token scripts, and stale `BrandConfig.Mapbox` usage are gone from active code/project files.
- Manually verify in simulator/device that the map loads the Rails shared style, dark/light style switching works, PMTiles layers render, selection animation/card behavior works for region/cluster/area/POI/problem, iOS filters still affect problem rendering, area/cluster inference still updates toolbar/download context, and retry/fallback behavior works for fresh and cached map states.

MapLibre rendering, native gestures, and SDK resource-cache behavior are not practical to unit test in this repository without heavy UI automation; they require manual or simulator quality gates. Pure parsing/cache/card-model behavior should not depend on MapLibre and must be testable without network access.

### Code documentation
Document the new map-loading/cache boundary and native card model boundary because future maintainers need to understand why iOS follows the Rails manifest/style contract and why card display is tile-property-first. Concise comments or type documentation should clarify:
- The manifest URL/config defaults and last-known fallback behavior.
- The shared selection-layer sentinel/filter model and why it avoids MapLibre feature-state for cross-client parity.
- Which iOS behaviors intentionally differ from Rails web: direct problem details, camera-based area/cluster inference, and native favorite/ticked/popular filters.
- URL validation and missing-SQLite-detail behavior for map-card actions.

Avoid noisy comments that paraphrase obvious Swift. Existing comments that say Mapbox should be renamed or removed unless they are historical legal/provenance references.

## Acceptance criteria
- [ ] `xcodebuild -list -project AustrianRocks.xcodeproj` lists only app schemes and no Mapbox package scheme.
- [ ] `Package.resolved` and `AustrianRocks.xcodeproj/project.pbxproj` contain a MapLibre Native iOS dependency at version `>= 6.10.0` and contain no Mapbox SDK package references or Mapbox product dependencies.
- [ ] Repository search of active source/project/docs finds no `import MapboxMaps`, no `BrandConfig.Mapbox`, no Mapbox access-token build script, and no README instructions requiring `~/.mapbox` or Mapbox `.netrc` setup.
- [ ] Launching the app online loads the Rails manifest at the configured URL and displays the shared MapLibre style with Austrian Rocks PMTiles overlays, sprites, glyphs, basemap.at, terrain, and contours.
- [ ] Light/dark mode selects the manifest's light/dark style URLs and reloads the map style without losing required iOS overlays/state beyond expected style reload behavior.
- [ ] After one successful manifest/style load, blocking manifest fetches still lets the app attempt the last-known style path; if no fresh or cached style can initialize, a native retry overlay appears and non-map tabs remain usable.
- [ ] Region, cluster, area, and POI taps show native iOS map cards populated from PMTiles feature properties, with absent optional rows omitted and no WebView/HTML card rendering.
- [ ] Region, cluster, and area cards have a primary “show on map” action that fits/zooms to the selected entity; their secondary detail action opens the existing native detail view when a local SQLite record exists and handles missing records gracefully.
- [ ] POI cards show a directions action only for a validated usable directions URL and preserve the native external maps flow.
- [ ] Problem taps still open/present the existing native `ProblemDetailsView` flow directly.
- [ ] Selection uses one active selected feature at a time, selected-layer filters with `-1` cleared sentinel, and grow/shrink animation consistent with the web-led interaction style.
- [ ] Camera-based area/cluster inference continues to update the area toolbar and download button context while panning/zooming.
- [ ] Existing iOS problem filters for grade range, popular, favorites, and ticked still update the shared `problems` rendering correctly.
- [ ] New English and German localizations cover all new map-card, retry, unavailable, and action labels.
- [ ] `Acknowledgements.json` lists MapLibre Native iOS and current resolved non-Apple Swift Package dependencies, and no longer lists removed Mapbox SDK packages.
- [ ] The `AustrianRocks` and `AustrianRocks dev` schemes build for a generic iOS Simulator destination without requiring Mapbox token files.
- [ ] Added automated tests pass for manifest decoding/cache fallback/card parsing/localization URL validation/missing-detail behavior.

## Risks & open questions
- MapLibre Native iOS API differences from Mapbox Maps v11 may require more refactoring than a direct import/package swap, especially for style expressions, query APIs, camera fitting, location puck, ornaments, and gesture callbacks.
- The Rails shared style may expose layer ids/properties that differ from current iOS assumptions (`problemId` vs current `id`, `poiType` vs current `type`, `cluster-hulls` naming, selected layers, etc.); implementation must follow the Rails contract rather than preserving stale iOS names.
- Best-effort cached map behavior depends partly on MapLibre Native's resource cache and cannot guarantee offline coverage; guaranteed offline PMTiles downloads remain for `0006`.
- PMTiles and bundled SQLite data can drift until a future data-version contract exists; this item mitigates crashes and broken card display but does not solve release parity.
- No blocking spec questions remain after the interview.
