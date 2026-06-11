---
id: "0005"
slug: migrate-ios-from-mapbox-to-maplibre
stage: review
reviewed: 2026-06-11
commit: e2768e021984482589096bafa09d1408474f6ac6
---

# Migrate iOS From Mapbox To MapLibre — review

### Strengths
- `AustrianRocks/Config/BrandConfig.swift:44` — the new `BrandConfig.MapTiles` surface centralizes the Rails manifest URL and cache keys while intentionally leaving `BrandConfig.Mapbox` untouched for the P1 build boundary.
- `AustrianRocks/UI/Map/MapTileManifestClient.swift:23` — manifest fetching is isolated behind an injectable async client, uses no-store/no-cache request headers, validates HTTP responses, and is covered by `MapTileManifestTests`.
- `AustrianRocks/UI/Map/MapFeatureCardModel.swift:64` — card parsing is tile-property-first, localizes `nameEn` only for English, omits absent optional rows, prefers region main-cluster bounds, and keeps SQLite detail availability optional rather than force-unwrapping.
- `AustrianRocks/UI/Map/MapFeatureBounds.swift:20` — bounds parsing rejects non-finite, out-of-range, and inverted coordinates before later camera-fit code can consume them.
- `AustrianRocksTests/` — P1 added focused pure-code XCTest coverage for manifest decoding/style choice, cache fallback, card parsing/localization/bounds/histograms, safe URLs, and missing-detail behavior. Fresh gate evidence: `xcodebuild test -project AustrianRocks.xcodeproj -scheme AustrianRocks -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.3.1' -only-testing:AustrianRocksTests` → **TEST SUCCEEDED** (16 tests).

### Blocker
- None.

### Major
- `AustrianRocks/UI/Map/MapTileManifest.swift:91` and `AustrianRocks/UI/Map/MapFeatureCardModel.swift:11` — URL validation currently accepts any `URL` whose scheme is `http` or `https`, including malformed/unusable absolute URLs with no host such as `https:foo`, `https:///path`, or `http://`. That violates the spec's trust-boundary requirement that invalid user-opened card links be omitted and the P1 plan's safe URL validation promise; it could surface broken guidebook/parking/directions actions or cache unusable manifest/style URLs from malformed data. Fix by requiring a non-empty host (and ideally absolute URL semantics) in the shared validator, then add tests for hostless HTTP(S) values in `SafeURLTests`/manifest tests. status: open

### Minor
- None.

### Nit
- None.

### Verdict
Ready to release? **No** — one open major in the P1 URL-validation seam. The phase otherwise aligns well with the plan and its fresh XCTest gate passes, but the safe-URL contract should be tightened before advancing the migration.
