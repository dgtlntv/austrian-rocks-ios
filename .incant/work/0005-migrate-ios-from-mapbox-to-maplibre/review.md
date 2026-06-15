---
id: "0005"
slug: migrate-ios-from-mapbox-to-maplibre
stage: review
reviewed: 2026-06-12
commit: afb1b336237d6037582d730539ff5c3352010f7b
---

# Migrate iOS From Mapbox To MapLibre — review

### Strengths
- `AustrianRocks/UI/Map/MapStyleLoadCoordinator.swift:49` through `AustrianRocks/UI/Map/MapStyleLoadCoordinator.swift:93` — style loading now has a clear fresh/cached/unavailable state machine: fresh styles are cached only after MapLibre reports load success, failed fresh loads fall back once to the previous cached style, and cancellation does not poison availability.
- `AustrianRocks/UI/Map/MapLibreViewController.swift:93` through `AustrianRocks/UI/Map/MapLibreViewController.swift:169` — MapLibre initialization is token-free, manifest/cache driven, reloads on light/dark trait changes, and keeps filters/selection re-applied after style loads.
- `AustrianRocks/UI/Map/MapLibreViewController.swift:331` through `AustrianRocks/UI/Map/MapLibreViewController.swift:384` — problem taps still go straight to native `ProblemDetailsView`, while region/cluster/area/POI taps build native card models from rendered PMTiles feature properties.
- `AustrianRocks/UI/Map/MapSelectionController.swift:121` through `AustrianRocks/UI/Map/MapSelectionController.swift:267` — the shared selected-layer/sentinel selection model is centralized and scoped by feature kind, including problem-only clears and selected-symbol base-layer exclusion.
- `AustrianRocks/UI/Map/MapContainerView.swift:52` through `AustrianRocks/UI/Map/MapContainerView.swift:67` and `AustrianRocks/UI/ContentView.swift:48` through `AustrianRocks/UI/ContentView.swift:56` — the final card presentation unifies non-problem map selections with compact, expandable bottom sheets instead of the deleted duplicate overlay card.
- `AustrianRocks/UI/Misc/GradeDistributionView.swift:18` through `AustrianRocks/UI/Misc/GradeDistributionView.swift:124` — grade distribution rendering is now one shared brand-colored component with histogram and compact-row styles plus localized accessibility summaries.
- `AustrianRocks/UI/Map/AreaView.swift:230` through `AustrianRocks/UI/Map/AreaView.swift:284` — area details now show grade levels and filterable/searchable problems inline, removing the extra drill-down page while keeping map navigation for problem rows.
- `AustrianRocks/Acknowledgements.json:48` through `AustrianRocks/Acknowledgements.json:73` and `AustrianRocks.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved:1` through `AustrianRocks.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved:22` — legal notices and SwiftPM pins match the resolved MapLibre Native iOS `6.27.0`/SQLite.swift dependency set, with no Mapbox SDK pins.
- Fresh final gate (run this session): `xcodebuild -list -project AustrianRocks.xcodeproj` lists only the `AustrianRocks` and `AustrianRocks dev` schemes; the Mapbox-removal `rg` command returned no active SDK/import/token references; `xcodebuild test -project AustrianRocks.xcodeproj -scheme AustrianRocks -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.3.1' && xcodebuild -project AustrianRocks.xcodeproj -scheme AustrianRocks -configuration Debug -destination 'generic/platform=iOS Simulator' build && xcodebuild -project AustrianRocks.xcodeproj -scheme 'AustrianRocks dev' -configuration Debug -destination 'generic/platform=iOS Simulator' build` exited 0 with **TEST SUCCEEDED** and **BUILD SUCCEEDED** for both app schemes.

### Blocker
- `AustrianRocks/UI/Map/MapFeatureCardModel.swift:55` and `AustrianRocks/UI/Map/MapFeatureCardModel.swift:135` parse the PMTiles `coverPhotoUrl`, but the new card/detail path never renders `card.coverPhotoURL`: `MapFeatureCardHeaderSection` only emits stats, show-on-map, histogram, warning, guidebook, and parking rows (`AustrianRocks/UI/Map/MapFeatureSheetView.swift:101` through `AustrianRocks/UI/Map/MapFeatureSheetView.swift:151`), the missing-SQLite fallback uses that same section (`AustrianRocks/UI/Map/MapFeatureSheetView.swift:161` through `AustrianRocks/UI/Map/MapFeatureSheetView.swift:164`), and region details fall back to SQLite-only `region.coverPhotoURL` (`AustrianRocks/UI/Discover/RegionDetailView.swift:39` through `AustrianRocks/UI/Discover/RegionDetailView.swift:42`). After deleting `MapFeatureCardView`, map cards no longer display tile-property cover photos for clusters/areas or for regions whose SQLite export lacks `cover_photo_url`, violating the required tile-property-first card content and drift handling. Fix: render `CoverPhotoView(url: card.coverPhotoURL)` (or otherwise prefer the map-card URL) in the map-presented detail/fallback header so the PMTiles `coverPhotoUrl` displays even when SQLite is absent or stale. status: open

### Major
- None.

### Minor
- None.

### Nit
- None.

### Verdict
Ready to release? **No** — one open blocker leaves a required PMTiles card field unrendered after the P7 card unification. Automated tests/builds and static Mapbox-removal gates pass, but the tile-property cover-photo regression must be fixed before finalizing.
