---
id: "0005"
slug: migrate-ios-from-mapbox-to-maplibre
stage: review
reviewed: 2026-06-11
commit: ecf56e1ac7f0eba70e47a9c8ec31cf95d240da4b
---

# Migrate iOS From Mapbox To MapLibre — review

### Strengths
- `AustrianRocks/Config/BrandConfig.swift:44` — the new `BrandConfig.MapTiles` surface centralizes the Rails manifest URL and cache keys while intentionally leaving `BrandConfig.Mapbox` untouched for the P1 build boundary.
- `AustrianRocks/UI/Map/MapTileManifestClient.swift:23` — manifest fetching is isolated behind an injectable async client, uses no-store/no-cache request headers, validates HTTP responses, and is covered by `MapTileManifestTests`.
- `AustrianRocks/UI/Map/MapFeatureCardModel.swift:64` — card parsing is tile-property-first, localizes `nameEn` only for English, omits absent optional rows, prefers region main-cluster bounds, and keeps SQLite detail availability optional rather than force-unwrapping.
- `AustrianRocks/UI/Map/MapFeatureBounds.swift:20` — bounds parsing rejects non-finite, out-of-range, and inverted coordinates before later camera-fit code can consume them.
- `AustrianRocks/UI/Map/MapTileManifest.swift:98` — the safe URL helper now requires `http`/`https` plus a non-empty host, so the shared manifest/cache/card URL validation no longer accepts hostless malformed URLs.
- `AustrianRocksTests/SafeURLTests.swift:10` and `AustrianRocksTests/MapTileManifestTests.swift:40` — the review-fix regression coverage directly exercises `https:foo`, `https:///path`, `http://`, and hostless manifest/style URLs.
- `AustrianRocksTests/` — P1 added focused pure-code XCTest coverage for manifest decoding/style choice, cache fallback, card parsing/localization/bounds/histograms, safe URLs, and missing-detail behavior. Fresh re-review gate evidence: `xcodebuild test -project AustrianRocks.xcodeproj -scheme AustrianRocks -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.3.1' -only-testing:AustrianRocksTests` → **TEST SUCCEEDED** (17 tests).

### Blocker
- None.

### Major
- `AustrianRocks/UI/Map/MapTileManifest.swift:98` and `AustrianRocksTests/SafeURLTests.swift:10` — addressed. The previous review found that hostless/malformed HTTP(S) URLs such as `https:foo`, `https:///path`, or `http://` passed validation. The shared validator now rejects URL values without a non-empty host, and regression tests cover both card-link and manifest decoding paths. status: addressed

### Minor
- None.

### Nit
- None.

### Verdict
Ready to release? **Yes** — no open blocker or major findings for the 0005-P1 phase gate. The safe-URL review finding is addressed, the fresh XCTest gate passes, and P1 is ready to advance to `/incant:implement 0005` for Phase 0005-P2.
