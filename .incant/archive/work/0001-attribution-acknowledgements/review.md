---
id: "0001"
slug: attribution-acknowledgements
stage: review
reviewed: 2026-05-31
commit: 4aa4c4fa488e448c23b3818f3b822a8a81700e21
---

# Attribution Acknowledgements — review
<!-- Single fresh-eyes pass against spec + plan + acceptance + active principles. -->
<!-- Each finding: file:line — what's wrong; why it matters; how to fix. status: open|addressed|wontfix (+ note). -->

### Strengths
- `AustrianRocks/Acknowledgements.json:1` — the bundled catalog is valid JSON with schema metadata, dependency-audit metadata, audited pins, source-file references, omission rationale, and separated app/third-party sections, matching the spec's config-vs-code requirement.
- `AustrianRocks/Acknowledgements.json:71` and `AustrianRocks/Acknowledgements.json:86` — Boolder plus every currently resolved non-Apple Swift Package pin from `Package.resolved` is represented in the acknowledgements data: Mapbox Maps, Mapbox Common, Mapbox Core Maps, Turf Swift, and SQLite.swift.
- `AustrianRocks/Acknowledgements.json:46` — omissions that might otherwise look accidental are documented, including bundled Mapbox sub-notice duplication and Apple SDK/system-framework exclusions.
- `AustrianRocks/Models/AcknowledgementCatalog.swift:3` — the loader has concise schema/update documentation and names the future Mapbox-to-MapLibre data replacement path without requiring UI-code changes.
- `AustrianRocks/Models/AcknowledgementCatalog.swift:23` and `AustrianRocks/UI/Discover/AcknowledgementsView.swift:80` — missing, unreadable, and malformed bundled JSON errors are thrown/caught and rendered through a fallback state instead of crashing.
- `AustrianRocks/UI/Discover/DiscoverRouter.swift:17`, `AustrianRocks/UI/Discover/DiscoverView.swift:250`, and `AustrianRocks/UI/Discover/DiscoverView.swift:334` — the acknowledgements entry is production-visible in Discover and opens `AcknowledgementsView()` outside the existing development-only settings section.
- `AustrianRocks/UI/Discover/AcknowledgementsView.swift:31` and `AustrianRocks/UI/Discover/AcknowledgementsView.swift:97` — the UI keeps the main list compact while making full legal text, URL metadata, version/license/copyright, and selectable notice text available on per-entry detail screens.
- `AustrianRocks/en.lproj/Localizable.strings:72` and `AustrianRocks/de.lproj/Localizable.strings:70` — the navigation label and acknowledgements UI chrome are localized in English and German while legal notice text remains in the JSON.
- `AustrianRocks.xcodeproj/project.pbxproj:705`, `AustrianRocks.xcodeproj/project.pbxproj:722`, `AustrianRocks.xcodeproj/project.pbxproj:779`, and `AustrianRocks.xcodeproj/project.pbxproj:877` — the JSON resource and both new Swift files are wired into both shipping app targets.
- Fresh review gate passed: `python3 -m json.tool AustrianRocks/Acknowledgements.json >/tmp/acknowledgements-json-review.txt && xcodebuild -project AustrianRocks.xcodeproj -scheme AustrianRocks -destination 'generic/platform=iOS Simulator' build && xcodebuild -project AustrianRocks.xcodeproj -scheme 'AustrianRocks dev' -destination 'generic/platform=iOS Simulator' build` succeeded; warnings were limited to the existing run-script output dependency and local Mapbox-token notice.

### Blocker
- None.

### Major
- None.

### Minor
- None.

### Nit
- None.

### Verdict
Ready to release? **Yes** — no open blocker or major findings. The implementation satisfies the spec acceptance criteria for a production Discover acknowledgement route, bundled JSON source of truth, audited notices, localized UI, non-crashing fallback, and successful app-target builds.
