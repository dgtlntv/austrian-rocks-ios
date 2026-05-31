---
id: "0003"
slug: fix-missing-de-en-localization-keys
stage: review
reviewed: 2026-05-31
commit: 8cef335e19573a0c4f0e670d3b824d5366c6da68
---

# Fix Missing De En Localization Keys — review
<!-- Single fresh-eyes pass against spec + plan + acceptance + active principles. -->
<!-- Each finding: file:line — what's wrong; why it matters; how to fix. status: open|addressed|wontfix (+ note). -->

### Strengths
- `AustrianRocks/en.lproj/Localizable.strings:59` through `AustrianRocks/en.lproj/Localizable.strings:67` and `AustrianRocks/de.lproj/Localizable.strings:59` through `AustrianRocks/de.lproj/Localizable.strings:67` — the P2 release-facing Discover region/cluster keys are present in both languages with matching key sets, keeping user-visible copy in resource configuration instead of hardcoded Swift literals.
- `AustrianRocks/UI/Discover/DiscoverView.swift:165`, `AustrianRocks/UI/Discover/RegionsListView.swift:56`, `AustrianRocks/UI/Discover/RegionDetailView.swift:65`, and `AustrianRocks/UI/Discover/ClusterDetailView.swift:24` — the planned Discover labels and navigation title now use localization keys while preserving dynamic region/cluster/area names as intentional data-driven literals.
- `AustrianRocks/UI/Map/Problem details/ProblemDetailsView.swift:113`, `AustrianRocks/UI/Map/Problem details/ProblemDetailsView.swift:125`, and `AustrianRocks/UI/Map/Download/AreaDownloadRowView.swift:71` — the planned video and swipe-action copy was converted without changing surrounding behavior or introducing new tooling.
- `AustrianRocks/en.lproj/Localizable.strings:127`, `AustrianRocks/de.lproj/Localizable.strings:127`, `AustrianRocks/en.lproj/Localizable.strings:181` through `AustrianRocks/en.lproj/Localizable.strings:182`, and `AustrianRocks/de.lproj/Localizable.strings:181` through `AustrianRocks/de.lproj/Localizable.strings:182` — the new download/video keys have intentional English and German values.
- Fresh review gates passed: the parity/InfoPlist check printed `OK: 167 shared Localizable.strings keys and InfoPlist privacy keys present`; the hardcoded-literal inspection only found documented intentional literals (`OK`, Apple Maps/Google Maps/Waze, and DEVELOPMENT-only Dev/Settings); and `xcodebuild -project AustrianRocks.xcodeproj -scheme AustrianRocks -configuration Debug -sdk iphonesimulator build` ended with `** BUILD SUCCEEDED **` with only the pre-existing Mapbox access-token warning.
- Commit history follows incant conventions for this item: `incant 0003: spec`, `incant 0003: plan`, `incant 0003-P1: restore localization key parity`, and `incant 0003-P2: localize release-facing UI copy`.

### Blocker
- None.

### Major
- None.

### Minor
- None.

### Nit
- None.

### Verdict
Ready to release? **Yes** — the item satisfies the approved spec and both planned phases: EN/DE `Localizable.strings` key sets match, shipped localization references and planned release-facing hardcoded strings are covered, InfoPlist privacy keys remain present, no permanent audit tooling was added, and the app builds successfully.
