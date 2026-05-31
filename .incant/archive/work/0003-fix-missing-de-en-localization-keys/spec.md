---
id: "0003"
slug: fix-missing-de-en-localization-keys
branch: incant/0003-fix-missing-de-en-localization-keys
title: Fix Missing De En Localization Keys
stage: spec
status: in-progress
created: 2026-05-31
commit: 3285ee60
updated: 2026-05-31
---

# Fix Missing De En Localization Keys

## Goal
Ensure every shipped, user-visible SwiftUI localization key used by the app resolves to intentional English and German text, with the English and German `Localizable.strings` files containing the same key set.

## Context & codebase fit
The app localizes UI copy through `AustrianRocks/en.lproj/Localizable.strings` and `AustrianRocks/de.lproj/Localizable.strings`, with SwiftUI views commonly passing localization keys directly to `Text`, `Label`, `Picker`, and navigation title APIs. Model display names also use `NSLocalizedString`, for example in `AustrianRocks/Models/GradeRange.swift` and `AustrianRocks/Models/Steepness.swift`.

Initial scouting found the two `Localizable.strings` files out of sync: English-only keys include `boulder.info_basic`, `boulder.info_basic_singular`, `problem.startgroup.pagination`, `problem.startgroup.variants.singular`, `problem.startgroup.variants.plural`, `search.popular_areas`, and `search.popular_problems`; German-only keys include `problem.pagination`. Swift references also include `discover.top_areas.level.beginner.intro`, which is missing from both languages. Several release-reachable SwiftUI strings are still hardcoded in English, such as region/cluster labels in `DiscoverView.swift`, `ClusterDetailView.swift`, `RegionDetailView.swift`, `RegionsListView.swift`, problem video copy, and download delete copy. Development-only settings/debug/test UI exists under development paths or `#if DEVELOPMENT` entry points and is not part of the released localization surface for this item.

## Requirements
1. `AustrianRocks/en.lproj/Localizable.strings` and `AustrianRocks/de.lproj/Localizable.strings` must contain identical key sets after the change.
2. Every localization key referenced by shipped Swift code through direct SwiftUI localization initializers or `NSLocalizedString` must exist in both English and German `Localizable.strings`.
3. Release-reachable, user-visible hardcoded English SwiftUI strings discovered during this work must be converted to localization keys with English and German values.
4. Development-only, debug-only, test, brand names, third-party app names, symbols, data-driven names, URLs, and non-human diagnostic strings must not be forced into localization for this item.
5. Existing `InfoPlist.strings` localization must remain intact and must not lose any English or German privacy usage descriptions.
6. The implementation must not add a permanent localization audit script or new repository tooling.

## In scope / Out of scope
**In scope:**
- Add missing English and German `Localizable.strings` entries for keys already referenced by shipped Swift code.
- Resolve English/German `Localizable.strings` parity, including replacing or preserving obsolete keys only when doing so keeps shipped references correct.
- Convert release-reachable hardcoded English UI copy to localization keys where the text is visible to normal users.
- Preserve intentional literals such as `Apple Maps`, `Google Maps`, `Waze`, punctuation bullets, dynamic area/problem names, URLs, and numeric formatting where localization is not appropriate.
- Verify the app still builds after localization changes.

**Out of scope:**
- Localizing development-only `SettingsView` and debug/test views — reason: the accepted scope excludes dev-only/debug UI from this item.
- Adding a reusable localization audit script/check — reason: the user explicitly declined new tooling for this item.
- Rewriting localization architecture, moving to String Catalogs, or changing bundle lookup behavior — reason: the current `.strings` pattern is already established and this item is a focused fix.
- Changing non-localization UX, navigation, data models, Mapbox setup, or app metadata — reason: unrelated to missing DE/EN localization keys.

## Approach
Keep the existing `.strings`-based localization approach. Audit Swift source for direct localized-key use and obvious release-reachable hardcoded UI literals, then update affected Swift files to reference stable dot-separated keys. Add matching English and German values to `Localizable.strings`, preserving existing sections and formatting. Where a key already exists in one language, add the missing counterpart rather than renaming unless the shipped Swift reference requires a canonical replacement.

Rejected alternatives: do not add String Catalogs because that would be a broader migration; do not add a permanent audit script because the user declined repository tooling; do not localize all debug/dev copy because it is outside the accepted release-facing scope.

## Considerations
### Config vs code
The localized copy is configuration-like resource data and belongs in `AustrianRocks/en.lproj/Localizable.strings` and `AustrianRocks/de.lproj/Localizable.strings`, not embedded as English literals in Swift. Swift code should consume localization keys through SwiftUI localization APIs or `NSLocalizedString`. Defaults are the English strings already present or the current hardcoded English copy when introducing a new key; German strings should be natural German equivalents consistent with nearby existing translations.

### Security
This item changes static UI resources and SwiftUI string references only. It introduces no network calls, user input handling, authentication, file path handling, or secrets. Existing Mapbox token guidance and secret files must not be changed, and no credentials or private values should be written into `.incant/` artifacts.

### Testability
There is no test target in the repository, so verification is build plus deterministic file/source inspection. The plan should include an ad hoc key-parity/source-reference check command run from the repo root and an Xcode build command such as `xcodebuild -project AustrianRocks.xcodeproj -scheme AustrianRocks -configuration Debug -sdk iphonesimulator build`. Acceptance maps to pass/fail checks: matching EN/DE key sets, no shipped Swift localization references missing in either language, release-reachable hardcoded UI copy addressed or explicitly justified, and build success.

### Code documentation
This item is expected to touch localization resources and straightforward SwiftUI string references only. No new modules, public APIs, or non-obvious behavior should be introduced, so inline documentation is not required; avoid noisy comments that merely restate localization key names.

## Acceptance criteria
- [ ] English and German `Localizable.strings` contain exactly the same keys.
- [ ] Every shipped Swift localization key reference discovered by audit exists in both English and German.
- [ ] Release-reachable hardcoded English UI strings found during the audit are either converted to localization keys or documented in the implementation notes as intentional literals.
- [ ] `InfoPlist.strings` privacy usage descriptions remain present in both English and German.
- [ ] The app builds successfully with the existing Xcode project and AustrianRocks scheme.
- [ ] No permanent localization audit script or new tooling is added.

## Risks & open questions
- Some Swift string literals are intentional non-localized values, dynamic data, or development-only UI; the implementation must classify them carefully to avoid over-localizing.
- German wording for newly added copy should be concise and consistent with existing Austrian.rocks terminology.
