---
id: "0001"
slug: attribution-acknowledgements
branch: incant/0001-attribution-acknowledgements
title: Attribution Acknowledgements
stage: spec
status: in-progress
created: 2026-05-30
commit: 13ac8d4d
updated: 2026-05-30
---

# Attribution Acknowledgements

## Goal
Add a production-visible, localized About / Acknowledgements screen that displays every Boolder and non-Apple third-party notice the app is legally required to show.

## Context & codebase fit
The app currently has a `DiscoverView` support area with production links such as rate/contribute, and a `SettingsView` that is only reachable under `#if DEVELOPMENT`. The acknowledgements entry should therefore be added to the production Discover support area rather than making the developer settings screen public.

The app localizes user-facing strings through `AustrianRocks/en.lproj/Localizable.strings` and `AustrianRocks/de.lproj/Localizable.strings`; the new navigation labels, section headers, and UI chrome must follow that pattern. The existing `LICENSE.md` contains the Boolder MIT license notice that must remain represented in the app. Swift Package dependencies are declared in `AustrianRocks.xcodeproj/project.pbxproj`, and resolved non-Apple package pins are listed in `AustrianRocks.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` (`mapbox-maps-ios`, Mapbox transitive packages, `turf-swift`, and `sqlite.swift` at the time of writing).

The user also captured a future Mapbox-to-MapLibre migration need in `.incant/inbox.md`: when the map SDK changes, the acknowledgement/license data must be updated from Mapbox to MapLibre.

## Requirements
1. Add a production-visible Discover support entry labelled as About / Acknowledgements, available in both English and German.
2. Add an acknowledgements screen reachable from that entry without using `#if DEVELOPMENT`-only navigation.
3. Store acknowledgement/license entries in a bundled JSON file that is separate from SwiftUI view logic.
4. Populate the JSON with the Boolder MIT notice from `LICENSE.md` and every notice/license entry required for the app's currently resolved non-Apple dependencies after auditing their license files or package metadata.
5. Do not display a dependency solely because it exists if its license does not require an in-app notice; document the audit result in the JSON or nearby source comment when an omission could otherwise look accidental.
6. Include Mapbox-related notices for the current implementation if legally required, and keep the data structure easy to replace with MapLibre notices during the future map SDK migration.
7. Localize all user-facing labels and explanatory text in English and German; license names, copyright notices, URLs, and legal text may remain in their original language.
8. Ensure the production app can load the bundled JSON and shows a clear failure fallback instead of crashing if the file is missing or malformed.
9. Keep existing Mapbox on-map attribution controls untouched; this item adds an in-app acknowledgements surface and does not weaken map/provider attribution.

## In scope / Out of scope
**In scope:**
- A production Discover support link to About / Acknowledgements.
- A localized SwiftUI screen for app/about text and required acknowledgements/licenses.
- A bundled JSON acknowledgements data source.
- A license/notice audit for Boolder and currently resolved non-Apple Swift Package dependencies.
- Build-project changes needed to include the JSON resource in both app targets.

**Out of scope:**
- Replacing Mapbox with MapLibre — reason: captured as a future inbox item and requires map implementation work beyond acknowledgements.
- Removing all Boolder/Fontainebleau leftovers from user-facing app copy — reason: tracked separately as backlog item `0002`.
- Rebranding repository documentation such as `README.md` — reason: not required for the in-app acknowledgement surface.
- Providing legal advice — reason: the implementation must follow license texts, but final legal interpretation remains with the app owner.
- Changing App Store privacy metadata — reason: tracked separately as backlog item `0004`.

## Approach
Add a new production route from the Discover support section to an About / Acknowledgements SwiftUI view. The view will load a bundled JSON acknowledgements file through a small decoding model, render localized app/about headings and grouped acknowledgement entries, and show legal text/links in a readable scrollable layout.

The acknowledgements JSON will be the local source of truth for legal notice data. During implementation, audit `LICENSE.md`, `Package.resolved`, and the corresponding dependency license files/package metadata to decide which entries are required. Rejected alternatives: hardcoding notices directly in the SwiftUI screen was rejected because future Mapbox-to-MapLibre attribution changes should be data-oriented; making the existing developer Settings screen public was rejected because it mixes production legal information with development-only actions.

## Considerations
### Config vs code
Acknowledgement entries are configuration/legal content, not UI behavior, so they belong in a dedicated bundled JSON file rather than being scattered through SwiftUI view code. Swift code should define only the decoding model and rendering rules. Defaults are the required notices for the current app state: Boolder MIT plus all legally required non-Apple dependency notices discovered during the audit.

### Security
The JSON is a local bundled resource and is not user-, network-, or secret-controlled input. Decoding failures must not crash the app; the screen should show a safe localized fallback. No credentials, Mapbox tokens, or other secrets may be added to the JSON, `.incant/`, or license text. The main failure blast radius is an incomplete or unavailable acknowledgements screen, contained by local decoding and fallback UI.

### Testability
Verification should include a build of the AustrianRocks app target and manual navigation through Discover → About / Acknowledgements in at least English and German locales. If a unit/UI test target is practical, add a focused decoder test for the bundled JSON; if the project still lacks test targets, make the JSON decoder small/pure enough to test later and rely on build plus manual verification for this item. Acceptance criteria below map to observable pass/fail checks.

### Code documentation
Document the JSON schema either in a concise file-level comment near the decoder model or in a short adjacent README/comment, especially required fields and how to update entries for future dependency changes such as Mapbox → MapLibre. Avoid noisy comments around ordinary SwiftUI layout code.

## Acceptance criteria
- [ ] Discover contains a production-visible About / Acknowledgements support entry in English and German.
- [ ] Tapping the entry opens an acknowledgements screen without enabling a development build flag.
- [ ] A bundled JSON file is the source of truth for acknowledgement/license entries and is included in both app targets that ship the app UI.
- [ ] The screen displays the Boolder MIT attribution notice required by `LICENSE.md`.
- [ ] The implementation audit covers all currently resolved non-Apple Swift Package dependencies and displays every notice/license entry legally required by those licenses.
- [ ] Mapbox-related legal notices remain accurate for the current Mapbox implementation, with an obvious data path for replacing them during the later MapLibre migration.
- [ ] English and German UI labels are localized; legal text/URLs remain accurate.
- [ ] Missing or malformed acknowledgement JSON results in a user-visible fallback, not a crash.
- [ ] The app target builds successfully after the resource and UI changes.

## Risks & open questions
- Exact legal notice requirements depend on the dependency license texts and any Mapbox-specific attribution terms; implementation must audit source licenses rather than assume all resolved packages need full text in-app.
- The project appears to have no dedicated test target, so automated coverage may be limited unless adding one is low-risk.
- Xcode project resource wiring can be error-prone; both production and dev targets must include the JSON if both can show the screen.
