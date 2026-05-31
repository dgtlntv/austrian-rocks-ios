---
id: "0003"
slug: fix-missing-de-en-localization-keys
stage: review
reviewed: 2026-05-31
commit: 01e14529bdcd38254f00745260e1064b2ea1f888
---

# Fix Missing De En Localization Keys — review
<!-- Single fresh-eyes pass against spec + plan + acceptance + active principles. -->
<!-- Each finding: file:line — what's wrong; why it matters; how to fix. status: open|addressed|wontfix (+ note). -->

### Strengths
- `AustrianRocks/de.lproj/Localizable.strings:53` and `AustrianRocks/de.lproj/Localizable.strings:54` — the German file now has the missing search section counterparts for the existing English popular-area/problem keys, directly satisfying the P1 parity requirement for those shipped search headers.
- `AustrianRocks/en.lproj/Localizable.strings:63` and `AustrianRocks/de.lproj/Localizable.strings:63` — `discover.top_areas.level.beginner.intro` is present in both languages with intentional localized copy, so the existing SwiftUI reference in `TopAreasBeginnerView` will resolve instead of falling back to the raw key.
- `AustrianRocks/de.lproj/Localizable.strings:163` through `AustrianRocks/de.lproj/Localizable.strings:165` and `AustrianRocks/de.lproj/Localizable.strings:188` through `AustrianRocks/de.lproj/Localizable.strings:189` — the topo/start-group and boulder-count keys now mirror the existing English key set without adding new code paths or tooling.
- `.incant/work/0003-fix-missing-de-en-localization-keys/plan.md:20` and fresh review evidence — the P1 gate is recorded, and I re-ran the same parity check during review; it printed `OK: 155 shared Localizable.strings keys` and exited 0.

### Blocker
- None.

### Major
- None.

### Minor
- None.

### Nit
- None.

### Verdict
Ready to release? **Yes for phase 0003-P1** — the implemented P1 localization-resource diff matches the approved plan, the EN/DE `Localizable.strings` key sets are equal, and the obsolete German-only `problem.pagination` key is no longer present. Continue with 0003-P2 before final item release/finalization.
