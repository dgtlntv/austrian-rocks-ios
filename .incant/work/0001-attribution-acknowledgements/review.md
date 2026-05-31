---
id: "0001"
slug: attribution-acknowledgements
stage: review
reviewed: 2026-05-31
commit: 777c42007d23a9aa714fb3054e171f2988d4cd46
---

# Attribution Acknowledgements — review
<!-- Single fresh-eyes pass against spec + plan + acceptance + active principles. -->
<!-- Each finding: file:line — what's wrong; why it matters; how to fix. status: open|addressed|wontfix (+ note). -->

### Strengths
- `AustrianRocks/Acknowledgements.json:1` — the legal-content catalog is valid bundled JSON with explicit schema, audit metadata, audited package pins, source files, omission notes, and separated app/third-party sections, matching the config-vs-code direction in the spec.
- `AustrianRocks/Acknowledgements.json:71` and `AustrianRocks/Acknowledgements.json:86` — the phase data includes the Boolder MIT notice and all currently pinned non-Apple Swift Package identities from `Package.resolved`: Mapbox Maps, Mapbox Common, Mapbox Core Maps, Turf Swift, and SQLite.swift.
- `AustrianRocks/Models/AcknowledgementCatalog.swift:1` — the loader keeps Swift responsible only for schema decoding/resource loading, documents the re-audit and Mapbox-to-MapLibre update path, and keeps the JSON as the source of truth for legal text.
- `AustrianRocks/Models/AcknowledgementCatalog.swift:23` — bundled resource loading handles missing, unreadable, and malformed JSON by throwing typed `LoadError`s instead of crashing, giving P2 a safe fallback path to render.
- `AustrianRocks.xcodeproj/project.pbxproj:701` and `AustrianRocks.xcodeproj/project.pbxproj:718` — `Acknowledgements.json` is wired into both app resource phases; `AcknowledgementCatalog.swift` is also present in both source phases at `AustrianRocks.xcodeproj/project.pbxproj:775` and `AustrianRocks.xcodeproj/project.pbxproj:872`.

### Blocker
- None.

### Major
- None.

### Minor
- None.

### Nit
- None.

### Verdict
Ready to release? **Yes** for the 0001-P1 phase gate — no open blocker or major findings in the acknowledgement data/loader phase. The full work item is not release-complete yet because planned P2/P3 UI, localization, fallback proof, and final acceptance verification remain unimplemented.
