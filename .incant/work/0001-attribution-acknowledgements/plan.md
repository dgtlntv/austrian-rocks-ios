---
id: "0001"
slug: attribution-acknowledgements
branch: incant/0001-attribution-acknowledgements
title: Attribution Acknowledgements
stage: implement
status: in-progress
created: 2026-05-30
commit: b3731aec
updated: 2026-05-31
---

# Attribution Acknowledgements — plan

## Status
- Phase: 0001-P2 (of 3) · stage: review
- Branch: incant/0001-attribution-acknowledgements
- Next: `/incant:review 0001` for the 0001-P2 phase gate; after review approval, resume 0001-P3.
- Blockers: none.
- Fresh verification (2026-05-31): `xcodebuild -project AustrianRocks.xcodeproj -scheme AustrianRocks -destination 'generic/platform=iOS Simulator' build && xcodebuild -project AustrianRocks.xcodeproj -scheme 'AustrianRocks dev' -destination 'generic/platform=iOS Simulator' build` → both app targets built successfully after adding the production route, localizations, view, and dev plist token placeholder (warnings only: missing local Mapbox token/run-script output dependency).
- Decisions:
  - The production entry lives in the existing Discover support section, not in the `#if DEVELOPMENT` settings section.
  - A bundled `Acknowledgements.json` is the legal-content source of truth; Swift owns decoding, fallback handling, and rendering only.
  - Mapbox on-map attribution controls remain untouched; the in-app surface adds notices and does not replace provider attribution.
  - Spec staleness check: `spec.md` was based on `13ac8d4d`; current HEAD is `b3731aec`, and the intervening non-spec code change only installed `.pi` incant assets, so the approved product/code requirements still hold.

## Files touched
- `AustrianRocks/Acknowledgements.json` (new) — bundled acknowledgement catalog containing schema version, audit metadata, omission notes, and legal notice entries.
- `AustrianRocks/Models/AcknowledgementCatalog.swift` (new) — decodable catalog models, file-level schema/update documentation, bundle loader, and non-crashing load error type.
- `AustrianRocks/UI/Discover/AcknowledgementsView.swift` (new) — localized SwiftUI About / Acknowledgements screen, loaded/error states, and notice rendering.
- `AustrianRocks/UI/Discover/DiscoverRouter.swift` (edit) — add the production acknowledgement route.
- `AustrianRocks/UI/Discover/DiscoverView.swift` (edit) — add the Discover support navigation link and route destination without changing development-only settings behavior.
- `AustrianRocks/en.lproj/Localizable.strings` (edit) — English About / Acknowledgements labels, explanatory copy, section titles, and fallback text.
- `AustrianRocks/de.lproj/Localizable.strings` (edit) — German About / Acknowledgements labels, explanatory copy, section titles, and fallback text.
- `AustrianRocks.xcodeproj/project.pbxproj` (edit) — add the new Swift files to both app source phases and the JSON resource to both app resource phases.
- `Dev-Info.plist` (edit) — restore the dev target `MBXAccessToken` placeholder value so the required dev build gate can process the plist.

## Phase 0001-P1 — acknowledgement data and loader
- [x] Read `LICENSE.md`, `AustrianRocks.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`, and the resolved package license files before editing: Mapbox Maps iOS `LICENSE.md`, Mapbox Common iOS `LICENSE.md`, Mapbox Core Maps iOS `LICENSE.md`, Turf Swift `LICENSE.md`, and SQLite.swift `LICENSE.txt` from Xcode's `SourcePackages/checkouts`.
- [x] Add `AustrianRocks/Acknowledgements.json` with this schema: top-level `schemaVersion` integer, `audit` object containing `packageResolvedOriginHash`, `auditedPackagePins`, `sourceFiles`, and `omissions`, and `sections` array; each section has `id`, `titleKey`, and `entries`; each entry has `id`, `name`, `version`, `licenseName`, `copyright`, `url`, and `notice`.
- [x] Populate `AustrianRocks/Acknowledgements.json` with the Boolder MIT notice from `LICENSE.md` and all required notice text discovered for the currently pinned non-Apple dependencies: `mapbox-maps-ios` 11.19.0, `mapbox-common-ios` 24.19.0, `mapbox-core-maps-ios` 11.19.0, `turf-swift` 4.0.0, and `sqlite.swift` 0.15.5.
- [x] Record any audited dependency or bundled Mapbox sub-notice that is intentionally omitted in the JSON `audit.omissions` array with the dependency name and a concrete reason derived from the audited license text or package relationship.
- [x] Add `AustrianRocks/Models/AcknowledgementCatalog.swift` defining `AcknowledgementCatalog`, `AcknowledgementAudit`, `AcknowledgementSection`, `AcknowledgementEntry`, `AcknowledgementOmission`, `AcknowledgementCatalog.LoadError`, and `AcknowledgementCatalog.load(from bundle: Bundle = .main, resourceName: String = "Acknowledgements") throws -> AcknowledgementCatalog`.
- [x] Include a file-level comment in `AcknowledgementCatalog.swift` documenting the JSON schema, the source files to re-audit after dependency changes, and the Mapbox-to-MapLibre update path.
- [x] Edit `AustrianRocks.xcodeproj/project.pbxproj` so `AcknowledgementCatalog.swift` is compiled by both `AustrianRocks` and `AustrianRocks dev`, and `Acknowledgements.json` is copied as a resource by both targets.
**Quality gate:** `python3 -m json.tool AustrianRocks/Acknowledgements.json >/tmp/acknowledgements-json.txt && xcodebuild -project AustrianRocks.xcodeproj -scheme AustrianRocks -destination 'generic/platform=iOS Simulator' build` → JSON parses successfully and the production app target builds.

## Phase 0001-P2 — production Discover route and localized screen
- [x] Read `AustrianRocks/UI/Discover/DiscoverRouter.swift`, `AustrianRocks/UI/Discover/DiscoverView.swift`, `AustrianRocks/en.lproj/Localizable.strings`, and `AustrianRocks/de.lproj/Localizable.strings` before editing.
- [x] Edit `DiscoverRoute` in `AustrianRocks/UI/Discover/DiscoverRouter.swift` to add `case acknowledgements`.
- [x] Add `AustrianRocks/UI/Discover/AcknowledgementsView.swift` rendering a `List` or scrollable `VStack` with localized title, short localized explanation, app/about section, third-party notices grouped by the JSON section `titleKey`, entry name/version/license/url metadata, and selectable legal notice text.
- [x] In `AcknowledgementsView`, load `AcknowledgementCatalog.load()` on appearance or initialization, show the decoded entries on success, and show a localized fallback message using the caught `LoadError` description on missing or malformed JSON without calling `fatalError`, force-unwrapping decoded data, or crashing.
- [x] Edit the Discover support section in `AustrianRocks/UI/Discover/DiscoverView.swift` to add a production-visible `NavigationLink(value: DiscoverRoute.acknowledgements)` with an info/book-style SF Symbol and localized label `discover.acknowledgements`.
- [x] Edit `destination(for:)` in `DiscoverView.swift` so `.acknowledgements` opens `AcknowledgementsView()`, leaving `.settings` reachable only from the existing `#if DEVELOPMENT` link.
- [x] Add English strings in `AustrianRocks/en.lproj/Localizable.strings` for `discover.acknowledgements`, `acknowledgements.title`, `acknowledgements.intro`, `acknowledgements.section.app`, `acknowledgements.section.third_party`, `acknowledgements.license`, `acknowledgements.version`, `acknowledgements.website`, and `acknowledgements.load_failed`.
- [x] Add German strings in `AustrianRocks/de.lproj/Localizable.strings` for the same keys with production-ready German UI copy; keep license names, copyright notices, URLs, and legal notice bodies unchanged in the JSON.
- [x] Edit `AustrianRocks.xcodeproj/project.pbxproj` so `AcknowledgementsView.swift` is compiled by both `AustrianRocks` and `AustrianRocks dev`.
**Quality gate:** `xcodebuild -project AustrianRocks.xcodeproj -scheme AustrianRocks -destination 'generic/platform=iOS Simulator' build && xcodebuild -project AustrianRocks.xcodeproj -scheme 'AustrianRocks dev' -destination 'generic/platform=iOS Simulator' build` → both app targets build with the new route, localizations, Swift files, and bundled JSON.

## Phase 0001-P3 — acceptance verification and fallback proof
- [ ] Read the final diff for `AustrianRocks/Acknowledgements.json`, `AcknowledgementCatalog.swift`, `AcknowledgementsView.swift`, `DiscoverRouter.swift`, `DiscoverView.swift`, both `Localizable.strings` files, and `project.pbxproj` before final edits.
- [ ] Verify the JSON audit covers every current non-Apple pin from `Package.resolved`: `mapbox-maps-ios`, `mapbox-common-ios`, `mapbox-core-maps-ios`, `turf-swift`, and `sqlite.swift`; add any missing required notice entry or omission note before continuing.
- [ ] Verify the Mapbox entries describe the current Mapbox implementation and that the schema/update comment names the future Mapbox-to-MapLibre replacement path.
- [ ] Temporarily rename the built resource reference in a local working edit or run the view with `AcknowledgementCatalog.load(resourceName: "MissingAcknowledgements")` during development to confirm the fallback UI path renders; revert the temporary edit before committing.
- [ ] Manually navigate in a simulator or preview through Discover → About / Acknowledgements in English and German locales and confirm the support entry is production-visible, opens without `#if DEVELOPMENT`, shows Boolder, shows all required dependency notices, and preserves existing Mapbox on-map attribution controls.
- [ ] Remove any temporary fallback-test edits and ensure no secrets, Mapbox tokens, or local checkout paths were added to committed JSON, Swift, or `.incant` files.
**Quality gate:** `python3 -m json.tool AustrianRocks/Acknowledgements.json >/tmp/acknowledgements-json.txt && xcodebuild -project AustrianRocks.xcodeproj -scheme AustrianRocks -destination 'generic/platform=iOS Simulator' build && xcodebuild -project AustrianRocks.xcodeproj -scheme 'AustrianRocks dev' -destination 'generic/platform=iOS Simulator' build` → JSON remains valid and both app targets build after fallback verification cleanup.

## Coverage self-review
- [x] Requirement 1 maps to 0001-P2 Discover support link and localized `discover.acknowledgements` strings.
- [x] Requirement 2 maps to 0001-P2 `.acknowledgements` route and `AcknowledgementsView()` outside `#if DEVELOPMENT`.
- [x] Requirement 3 maps to 0001-P1 `AustrianRocks/Acknowledgements.json` and `AcknowledgementCatalog`.
- [x] Requirement 4 maps to 0001-P1 Boolder MIT entry from `LICENSE.md` and 0001-P3 audit verification.
- [x] Requirement 5 maps to 0001-P1 `audit.omissions` and 0001-P3 dependency coverage verification.
- [x] Requirement 6 maps to 0001-P1 Mapbox notices, 0001-P1 schema/update documentation, and 0001-P3 Mapbox-to-MapLibre verification.
- [x] Requirement 7 maps to 0001-P2 English/German localization steps and JSON legal-text preservation.
- [x] Requirement 8 maps to 0001-P1 throwing loader and 0001-P2 fallback UI, with 0001-P3 fallback proof.
- [x] Requirement 9 maps to all phases preserving existing Mapbox controls and 0001-P3 manual verification.
- [x] Acceptance criteria map to the phase steps and final quality gate; phase completion alone is not accepted without 0001-P3 goal-level verification.
- [x] Symbol/signature consistency checked: route is `DiscoverRoute.acknowledgements`, screen is `AcknowledgementsView`, loader is `AcknowledgementCatalog.load(from:resourceName:)`, resource is `Acknowledgements.json`.
- [x] No placeholders remain in this plan.
