---
id: "0002"
slug: remove-bleau-leftovers
branch: incant/0002-remove-bleau-leftovers
title: Remove Bleau Leftovers
stage: implement
status: in-progress
created: 2026-05-31
commit: c6de6dd4
updated: 2026-05-31
---

# Remove Bleau Leftovers — plan

## Status
- Phase: 0002-P1 (of 3) · stage: review
- Branch: incant/0002-remove-bleau-leftovers
- Next: run `/incant:review 0002` for the 0002-P1 phase gate.
- Blockers: none
- Evidence:
  - 2026-05-31 0002-P1 quality gate passed: `rg -n "Boolder|Fontainebleau|Bleau|boolder|fontainebleau|bleau|hello@boolder.com" README.md AustrianRocks/en.lproj/Localizable.strings AustrianRocks/de.lproj/Localizable.strings AustrianRocks/UI/Discover/TopAreasDryFast.swift` produced no output (exit 1 from no matches).
- Decisions:
  - The spec's `commit: 749c1f20` is behind current `HEAD` (`c6de6dd4`) because the approved spec was committed on this branch; affected files were re-read/grepped while planning and the spec still holds.
  - For Swift headers with stale `//  Boolder` app-name lines, update the app name to `//  Austrian.rocks` and clarify provenance with `//  Originally created for Boolder by Nicolas Mondollot.` while preserving copyright lines and license/acknowledgement references.
  - If no Austria-appropriate drying/weather link is already available during implementation, remove the dry-fast useful-link row instead of inventing an unverified replacement.

## Files touched
- `README.md` (edit) — rewrite launch-facing project documentation for Austrian.rocks while keeping Mapbox token setup secret-safe.
- `AustrianRocks/en.lproj/Localizable.strings` (edit) — replace the Fontainebleau-specific intermediate-grade warning with neutral Austrian.rocks copy.
- `AustrianRocks/de.lproj/Localizable.strings` (inspect/edit if needed) — verify German localized values stay free of stale Boolder/Fontainebleau/Bleau references and mirror any key removal needed by the dry-fast link change.
- `AustrianRocks/UI/Discover/TopAreasDryFast.swift` (edit) — remove the Bleau Météo link row or replace it with a verified Austria-appropriate static public resource.
- `AustrianRocks/UI/Map/MapboxViewController.swift` (edit) — replace Fontainebleau fallback bounds and identifiers with the approved Austria-wide bounds.
- `AustrianRocks/Models/Boulder.swift` (edit) — update the stale `//  Boolder` app header to `//  Austrian.rocks` and replace the created-by line with `//  Originally created for Boolder by Nicolas Mondollot.`; preserve copyright lines.
- `AustrianRocks/UI/Map/Problem details/BoulderProblemsListView.swift` (edit) — update stale app header and clarify original Boolder provenance; preserve copyright lines.
- `AustrianRocks/UI/Map/Problem details/ProblemInfoView.swift` (edit) — update stale app header and clarify original Boolder provenance; preserve copyright lines.
- `AustrianRocks/UI/Map/Problem details/ProblemSaveManager.swift` (edit) — update stale app header and clarify original Boolder provenance; preserve copyright lines.
- `AustrianRocks/UI/Map/Problem details/Topo/GradeLabelView.swift` (edit) — update stale app header and clarify original Boolder provenance; preserve copyright lines.
- `AustrianRocks/UI/Map/Problem details/Topo/ProblemNameLabelView.swift` (edit) — update stale app header and clarify original Boolder provenance; preserve copyright lines.
- `AustrianRocks/UI/Map/Problem details/Topo/StartGroupMenuView.swift` (edit) — update stale app header and clarify original Boolder provenance; preserve copyright lines.
- `AustrianRocks/UI/Map/Problem details/Topo/TappableLineView.swift` (edit) — update stale app header and clarify original Boolder provenance; preserve copyright lines.
- `AustrianRocks/UI/Map/Problem details/Topo/TopoCarouselView.swift` (edit) — update stale app header and clarify original Boolder provenance; preserve copyright lines.
- `AustrianRocks/UI/Map/Problem details/Topo/TopoImageCache.swift` (edit) — update stale app header and clarify original Boolder provenance; preserve copyright lines.
- `AustrianRocks/UI/Map/Problem details/Topo/TopoLoopScrollView.swift` (edit) — update stale app header and clarify original Boolder provenance; preserve copyright lines.
- `AustrianRocks/UI/Map/Problem details/Topo/TopoPageView.swift` (edit) — update stale app header and clarify original Boolder provenance; preserve copyright lines.
- `AustrianRocks/UI/Map/Search/SearchSheetView.swift` (edit) — update stale app header and clarify original Boolder provenance; preserve copyright lines.
- `AustrianRocks/UI/Misc/BottomSheetView.swift` (edit) — update stale app header and clarify original Boolder provenance; preserve copyright lines.
- `AustrianRocks/UI/Misc/SegmentType.swift` (edit) — update both stale app headers and clarify original Boolder provenance for each header block; preserve copyright lines.
- `AustrianRocks.xcodeproj/project.pbxproj` (inspect/edit if needed) — verify bundle IDs, app icon asset names, launch asset names, and organization metadata; edit only stale non-attribution launch-facing references.
- `AustrianRocks.xcodeproj/xcshareddata/xcschemes/AustrianRocks.xcscheme` (inspect/edit if needed) — verify shared production scheme contains no stale old app/place reference.
- `AustrianRocks.xcodeproj/xcshareddata/xcschemes/AustrianRocks dev.xcscheme` (inspect/edit if needed) — verify shared development scheme contains no stale old app/place reference.
- `AustrianRocks/Assets.xcassets/AppIcon.appiconset/Contents.json` (inspect/edit if needed) — verify app icon catalog metadata has no stale old app/place reference.
- `AustrianRocks/Assets.xcassets/AppIconDev.appiconset/Contents.json` (inspect/edit if needed) — verify dev app icon catalog metadata has no stale old app/place reference.
- `AustrianRocks/Assets.xcassets/LaunchBackground.colorset/Contents.json` (inspect/edit if needed) — verify launch background metadata has no stale old app/place reference.
- `AustrianRocks/Assets.xcassets/LaunchLogo.imageset/Contents.json` (inspect/edit if needed) — verify launch logo metadata has no stale old app/place reference.
- `AustrianRocks/Info.plist` (inspect/edit if needed) — verify launch-facing plist values contain no stale old app/place reference.
- `Dev-Info.plist` (inspect/edit if needed) — verify dev plist values contain no stale old app/place reference.

## Phase 0002-P1 — product-facing copy and dry-fast link cleanup
- [x] Read `README.md`, `AustrianRocks/en.lproj/Localizable.strings`, `AustrianRocks/de.lproj/Localizable.strings`, and `AustrianRocks/UI/Discover/TopAreasDryFast.swift` before editing.
- [x] Rewrite `README.md` with title `# Austrian.rocks iOS`, an Austrian.rocks app description, the existing Mapbox setup instructions using `YOUR_PUBLIC_MAPBOX_ACCESS_TOKEN` and `YOUR_SECRET_MAPBOX_ACCESS_TOKEN`, and contribution guidance that points to repository issues/pull requests without old Boolder URLs or `hello@boolder.com`.
- [x] In `AustrianRocks/en.lproj/Localizable.strings`, replace `top_areas.level.intermediate.warning` with neutral copy equivalent to the existing German value, e.g. `Careful: grades may vary by area.`
- [x] In `AustrianRocks/de.lproj/Localizable.strings`, confirm no stale localized value needs replacement; if the dry-fast useful-link key becomes unused because the link row is removed, leave the key unless a compiler warning or code search proves removing it is safe in both languages.
- [x] In `AustrianRocks/UI/Discover/TopAreasDryFast.swift`, remove the `HStack` containing `top_areas.dry_fast.useful_link`, `https://www.facebook.com/people/Bleau-Meteo/100055389702633/`, and `Text("Bleau Météo")` unless a verified Austria-appropriate static public drying/weather URL is available in the repository during implementation.
- [x] Run `rg -n "Boolder|Fontainebleau|Bleau|boolder|fontainebleau|bleau|hello@boolder.com" README.md AustrianRocks/en.lproj/Localizable.strings AustrianRocks/de.lproj/Localizable.strings AustrianRocks/UI/Discover/TopAreasDryFast.swift` and confirm it prints no stale product-copy or Bleau Météo matches.
**Quality gate:** `rg -n "Boolder|Fontainebleau|Bleau|boolder|fontainebleau|bleau|hello@boolder.com" README.md AustrianRocks/en.lproj/Localizable.strings AustrianRocks/de.lproj/Localizable.strings AustrianRocks/UI/Discover/TopAreasDryFast.swift` → no output.

## Phase 0002-P2 — map fallback geography and launch-facing metadata/header sweep
- [ ] Read `AustrianRocks/UI/Map/MapboxViewController.swift` before editing `centerOnCurrentLocation()`.
- [ ] Replace `fontainebleauBounds` in `centerOnCurrentLocation()` with a single named Austria fallback bounds value using southwest latitude `46.372276`, southwest longitude `9.530748`, northeast latitude `49.020530`, and northeast longitude `17.160776`; use identifiers such as `austriaBounds`/`austriaFallbackBounds`, not Fontainebleau names.
- [ ] Read each Swift file listed in Files touched with a stale `//  Boolder` app header, then update the header to use `//  Austrian.rocks` and replace the `Created by Nicolas Mondollot ...` line with `//  Originally created for Boolder by Nicolas Mondollot.`; keep copyright lines unchanged.
- [ ] Read `AustrianRocks.xcodeproj/project.pbxproj`, both shared scheme files under `AustrianRocks.xcodeproj/xcshareddata/xcschemes/`, `AustrianRocks/Info.plist`, `Dev-Info.plist`, and the four listed asset-catalog `Contents.json` files; verify app icon names, launch asset names, bundle IDs, and scheme buildable names contain no stale Boolder/Fontainebleau/Bleau references.
- [ ] If the metadata/asset inspection finds a stale non-attribution old app/place reference, replace it with the existing AustrianRocks/Austrian.rocks naming used elsewhere in that same file; do not churn `xcuserdata` files.
- [ ] Run `rg -n "fontainebleauBounds|Fontainebleau|fontainebleau|Bleau Météo|Bleau-Meteo|//  Boolder$" AustrianRocks AustrianRocks.xcodeproj/xcshareddata/xcschemes AustrianRocks.xcodeproj/project.pbxproj Dev-Info.plist` and confirm no stale non-attribution matches remain.
**Quality gate:** `rg -n "fontainebleauBounds|Fontainebleau|fontainebleau|Bleau Météo|Bleau-Meteo|//  Boolder$" AustrianRocks AustrianRocks.xcodeproj/xcshareddata/xcschemes AustrianRocks.xcodeproj/project.pbxproj Dev-Info.plist` → no output.

## Phase 0002-P3 — final classification and build verification
- [ ] Read `AustrianRocks/Acknowledgements.json`, `LICENSE.md`, `AustrianRocks/Config/BrandConfig.swift`, and any files still reported by the required grep before classifying remaining matches.
- [ ] Run `rg -n "boolder|fontainebleau|bleau|nmondollot|hello@" .` and classify every remaining match in the implementation notes as `intentional attribution`, `copyright/license`, `current Austrian.rocks contact`, or `needs replacement`; fix every `needs replacement` match before continuing. The `current Austrian.rocks contact` bucket is allowed only for `hello@austrian.rocks`, because it is not an old Boolder contact.
- [ ] Run supplemental case-insensitive evidence with `rg -ni "boolder|fontainebleau|bleau|nmondollot|nicolas mondollot|hello@" . --glob '!**/xcuserdata/**'` to prove capitalized launch-facing leftovers and preserved legal/copyright lines are classified.
- [ ] Confirm the expected preserved references are limited to legal/provenance files such as `AustrianRocks/Acknowledgements.json`, `LICENSE.md`, and original created-by/copyright headers, plus the current `AustrianRocks/Config/BrandConfig.swift` contact if it still matches `hello@`.
- [ ] Build the app for the simulator with `xcodebuild -project AustrianRocks.xcodeproj -scheme AustrianRocks -destination 'generic/platform=iOS Simulator' build`.
- [ ] Update `.incant/work/0002-remove-bleau-leftovers/plan.md` checkboxes/status with the grep and build evidence collected during implementation.
**Quality gate:** `xcodebuild -project AustrianRocks.xcodeproj -scheme AustrianRocks -destination 'generic/platform=iOS Simulator' build` → exits 0 with `** BUILD SUCCEEDED **`; `rg -n "boolder|fontainebleau|bleau|nmondollot|hello@" .` → no `needs replacement` matches remain after classification.

## Coverage self-review
- [x] Requirement 1 maps to Phase 0002-P1 README rewrite and P1 grep gate.
- [x] Requirement 2 maps to Phase 0002-P1 localized string edits/inspection and P1 grep gate.
- [x] Requirement 3 maps to Phase 0002-P1 `TopAreasDryFast.swift` link removal/replacement and P1 grep gate.
- [x] Requirement 4 maps to Phase 0002-P2 Austria fallback bounds edit and P2 grep gate.
- [x] Requirement 5 maps to Phase 0002-P2 project, scheme, plist, and asset-catalog inspection/edit steps.
- [x] Requirement 6 maps to Phase 0002-P2 header provenance rule and Phase 0002-P3 legal/provenance classification.
- [x] Requirement 7 maps to Phase 0002-P3 required grep classification and fix loop.
- [x] Requirement 8 maps to Phase 0002-P3 supplemental case-insensitive grep and fix loop.
- [x] Acceptance criteria are covered by the three phase gates plus the final simulator build.
- [x] No deferred or undefined content remains in this plan; all commands and paths are concrete.
