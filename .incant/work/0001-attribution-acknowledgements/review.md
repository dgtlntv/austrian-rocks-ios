---
id: "0001"
slug: attribution-acknowledgements
stage: review
reviewed: 2026-05-31
commit: 3a7a81bc0993c13f81b12bc40fff9cdb8c3606fd
---

# Attribution Acknowledgements — review
<!-- Single fresh-eyes pass against spec + plan + acceptance + active principles. -->
<!-- Each finding: file:line — what's wrong; why it matters; how to fix. status: open|addressed|wontfix (+ note). -->

### Strengths
- `AustrianRocks/Acknowledgements.json:1` — the legal-content catalog remains valid bundled JSON with explicit schema, audit metadata, audited package pins, source files, omission notes, and separated app/third-party sections, matching the config-vs-code direction in the spec.
- `AustrianRocks/Acknowledgements.json:71` and `AustrianRocks/Acknowledgements.json:86` — the catalog includes the Boolder MIT notice and all currently pinned non-Apple Swift Package identities from `Package.resolved`: Mapbox Maps, Mapbox Common, Mapbox Core Maps, Turf Swift, and SQLite.swift.
- `AustrianRocks/Models/AcknowledgementCatalog.swift:1` — the loader keeps Swift responsible only for schema decoding/resource loading, documents the re-audit and Mapbox-to-MapLibre update path, and keeps the JSON as the source of truth for legal text.
- `AustrianRocks/Models/AcknowledgementCatalog.swift:23` — bundled resource loading handles missing, unreadable, and malformed JSON by throwing typed `LoadError`s instead of crashing, giving the screen a safe fallback path to render.
- `AustrianRocks/UI/Discover/DiscoverRouter.swift:17`, `AustrianRocks/UI/Discover/DiscoverView.swift:250`, and `AustrianRocks/UI/Discover/DiscoverView.swift:334` — the acknowledgements route is added to the production Discover support section and resolves to `AcknowledgementsView()` outside the existing `#if DEVELOPMENT` settings block.
- `AustrianRocks/UI/Discover/AcknowledgementsView.swift:31` — the new screen renders localized intro/section chrome from the catalog, shows entry name/version/license/link/copyright/notice text, and keeps legal notice text selectable.
- `AustrianRocks/UI/Discover/AcknowledgementsView.swift:92` and `AustrianRocks/UI/Discover/AcknowledgementsView.swift:101` — load failures are caught and rendered through a localized `ContentUnavailableView` instead of force-unwrapping, `fatalError`, or crashing.
- `AustrianRocks/en.lproj/Localizable.strings:72` and `AustrianRocks/de.lproj/Localizable.strings:70` — the production navigation label plus English/German acknowledgements UI copy are localized while legal notice bodies remain in JSON.
- `AustrianRocks.xcodeproj/project.pbxproj:705`, `AustrianRocks.xcodeproj/project.pbxproj:722`, `AustrianRocks.xcodeproj/project.pbxproj:779`, `AustrianRocks.xcodeproj/project.pbxproj:780`, `AustrianRocks.xcodeproj/project.pbxproj:877`, and `AustrianRocks.xcodeproj/project.pbxproj:878` — the JSON resource and both Swift files are wired into both app targets.
- Fresh review gate passed: `python3 -m json.tool AustrianRocks/Acknowledgements.json >/tmp/acknowledgements-json-review.txt && xcodebuild -project AustrianRocks.xcodeproj -scheme AustrianRocks -destination 'generic/platform=iOS Simulator' build && xcodebuild -project AustrianRocks.xcodeproj -scheme 'AustrianRocks dev' -destination 'generic/platform=iOS Simulator' build` succeeded (warnings only: existing run-script output dependency and missing local Mapbox token notice).

### Blocker
- None.

### Major
- None.

### Minor
- None.

### Nit
- None.

### Verdict
Ready to release? **Yes** for the 0001-P2 phase gate — no open blocker or major findings in the production Discover route, localized screen, fallback rendering, or target resource/source wiring. The full work item is not release-complete yet because planned 0001-P3 acceptance verification, fallback proof, simulator locale navigation, and cleanup checks remain open.
