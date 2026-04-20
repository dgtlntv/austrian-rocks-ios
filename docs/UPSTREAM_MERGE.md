# Merging upstream Boolder changes

This fork tracks [boolder-org/boolder-ios](https://github.com/boolder-org/boolder-ios). It was forked and rebranded (Boolder → Austrian Rocks) in commit `e9088a71`, which renamed 281 files and dropped several Fontainebleau-specific features. Pulling in upstream changes is a deliberate process because of those divergences.

This document is the playbook. Read it before starting a merge.

## TL;DR

```bash
# 1. Make sure upstream is configured and up to date
git remote -v                # should show `upstream` → boolder-org/boolder-ios
git fetch upstream

# 2. Work on a throwaway branch so main-of-the-moment stays clean
git checkout -b upstream-merge-$(date +%Y%m%d)

# 3. Merge with aggressive rename detection (directory rename helps a lot)
git merge upstream/main -X find-renames=40

# 4. Resolve conflicts (see sections below)
# 5. Strip circuit references from any new upstream files
# 6. Update pbxproj if new files were added
# 7. Build in Xcode — xcodebuild is not available (CLT only)
# 8. Once it builds, merge the throwaway branch back into your working branch
```

## Why this is harder than a normal merge

The rebrand commit renamed every `Boolder/…` path to `AustrianRocks/…`. Git's rename detection handles most of it — 261 of the 281 renamed files are pure path changes — but upstream keeps adding files under `Boolder/…`, which git then can't auto-place. Plus the fork stripped features that upstream is still actively developing (see below), so you get semantic conflicts on top of the path conflicts.

## Divergences from upstream

These are the deliberate fork customizations you will see conflicts around. When resolving, preserve these; take upstream for everything else.

| Area | Fork behavior | Why |
| --- | --- | --- |
| Branding | `BrandConfig.swift` centralises app name, domains, Mapbox style, DB filename, App Store ID | So upstream changes to these values don't need to be merged |
| Mapbox style | `BrandConfig.Mapbox.styleURL` / `darkStyleURL` | Austrian Rocks has its own Mapbox style. `darkStyleID` currently aliases `styleID` — replace with a real dark style when available. |
| Database | `austrian-rocks.db` (not `boolder.db`) | Different boulder dataset. Upstream changes to `boolder.db` are irrelevant. |
| Data model | `Region → Cluster → Area → Problem` | Austrian Rocks has multiple regions. Boolder is single-region (Fontainebleau). Upstream lists `Area.popularAreas`; fork lists `Region.all.filter{$0.popular}` at the top level. |
| Localization | German + English only. French (`fr.lproj`) removed. | App audience is Austrian. |
| Warnings | `warningDe` / `warningEn` instead of `warningFr` / `warningEn` | Matches dropped localization. |
| Problem model | `grade` is `Grade?` (Optional); `name` / `nameEn` also Optional; new `videoLinks` field; `Problem.empty` placeholder | Austrian Rocks data is not as complete as Fontainebleau |
| **Circuits** | **Entirely removed.** No `circuitId`, `circuitNumber`, `circuitColor` on `Problem`. No `Circuit` model. | Fontainebleau-specific concept |
| Dropped files | `ContributeView`, `FiltersView`, `SearchView`, `CircuitPickerView`, `CircuitView`, `Boolder` entitlements, `boolder.db`, `fr.lproj/*` | Either replaced upstream (Contribute/Filters/Search) or circuit-specific |

## Circuit stripping

This is the single biggest source of post-merge work. Upstream is actively building out circuit features. Each merge will pull in new code that references:

- `problem.circuitId`, `problem.circuitNumber`, `problem.circuitColor`, `problem.circuitUIColor`, `problem.circuitUIColorForPhotoOverlay`
- `Circuit`, `Circuit.load(id:)`, `Circuit.CircuitColor.*`
- `MapState.selectedCircuit`, `selectCircuit`, `unselectCircuit`, `selectAndCenterOnCircuit`, `goToNext/PreviousCircuitProblem`, `canGoTo*CircuitProblem`, `centerOnCircuit`, `displayCircuitStartButton`, `presentCircuitPicker`
- `area.circuits`
- Mapbox layers `"circuits"`, `"circuit-problems"`, `"circuit-problems-texts"`
- Feature-specific files: `CircuitPickerView`, `CircuitView`, `CircuitFilterList`, `circuit-problems*` pbxproj entries

**Workflow for each new merge:**

```bash
# After resolving merge conflicts, find remaining circuit references
grep -rn "circuit\|Circuit" AustrianRocks --include="*.swift" | grep -v CircleView
```

`CircleView.swift` still has a `CircuitNumberView` comment and `CircuitNumberView_Previews` struct — those are harmless references to the old struct name and can be left alone.

Everywhere else, strip. For UI bits where upstream uses `problem.circuitUIColorForPhotoOverlay` as a label color, substitute `UIColor.white`. For nav methods like `goToNextCircuitProblem`, remove the call sites (they're usually in FAB button stacks).

## Optional-grade adjustments

Upstream treats `Problem.grade` as non-optional. Fork makes it `Grade?`. Every upstream change that does `problem.grade.string` or `$0.grade < $1.grade` needs `?.string ?? ""` / `($0.grade ?? Grade.min) < ($1.grade ?? Grade.min)` respectively.

```bash
# Find them
grep -rn "\.grade\.string\|\.grade\.min\|\.grade <\|\.grade >" AustrianRocks --include="*.swift"
```

## Conflict type cheat sheet

After `git merge upstream/main -X find-renames=40` you'll see:

| Status | Meaning | What to do |
| --- | --- | --- |
| `UU` | Both sides modified | Open the file, resolve conflict markers manually. Usually keep fork customizations (branding, region model, dropped-feature flows) and accept upstream for the new logic around them. |
| `UA` | Upstream added a file git placed under `AustrianRocks/…` via directory rename | `git add` the file. Then audit it for circuit refs. |
| `AA` | Both sides added | Rare — inspect both. |
| `UD` | Upstream deleted, we kept (fork has a file at the renamed path) | Usually `git rm` — upstream deleted as part of a refactor (e.g. `SearchView` → `SearchSheetView`). Only keep if the fork actually relies on it. |
| `DU` | We deleted (in rename), upstream modified at old path | `git rm Boolder/…` — we intentionally dropped these files (circuits, French loc, boolder.db). |
| `M` | Auto-merged cleanly | Commit. |

## pbxproj (Xcode project file)

The project file is a minefield. Strategy used in the last merge:

1. Python one-liner to take the union of both sides of every conflict block (both sets of file references stay):

   ```python
   import re
   path = "AustrianRocks.xcodeproj/project.pbxproj"
   content = open(path).read()
   pattern = re.compile(
       r'^<<<<<<< HEAD:[^\n]*\n(.*?)^=======\n(.*?)^>>>>>>> upstream/main:[^\n]*\n',
       re.DOTALL | re.MULTILINE
   )
   open(path, 'w').write(pattern.sub(lambda m: m.group(1) + m.group(2), content))
   ```

2. Then strip lines referencing files that no longer exist on disk:

   ```python
   import sys
   forbidden = ["boolder.db", "CircuitPickerView", "CircuitView.swift"]
   path = "AustrianRocks.xcodeproj/project.pbxproj"
   lines = [l for l in open(path) if not any(f in l for f in forbidden)]
   open(path, 'w').writelines(lines)
   ```

3. Validate: `plutil -lint AustrianRocks.xcodeproj/project.pbxproj`

4. If Xcode still complains when you open the project, the fallback is manual: delete broken file refs in Xcode's UI, then re-add any actual upstream-added files by dragging them into the Xcode navigator.

## Files that routinely conflict

Based on the last merge (389 upstream commits), these are the hottest spots. Re-check each time:

- `AustrianRocks.xcodeproj/project.pbxproj` — every new upstream file adds entries here
- `AustrianRocks/Models/Problem.swift` — circuit fields, grade optionality, videoLinks, localizedName locale
- `AustrianRocks/UI/Map/MapState.swift` — selection model, circuit state, new presentation flags
- `AustrianRocks/UI/Map/MapboxViewController.swift` — Mapbox layers, style URIs, circuit layer wiring
- `AustrianRocks/UI/Map/MapContainerView.swift` — FAB buttons, above-sheet nav, circuit start button
- `AustrianRocks/UI/Map/AreaToolbarView.swift` — toolbar layout, area name label, filter pills
- `AustrianRocks/UI/Discover/DiscoverView.swift` — region-vs-area split
- `AustrianRocks/UI/Map/Problem details/ProblemDetailsView.swift` — has been restructured around `TopoCarouselView`; fork had custom `infos`/`descriptionAndVideos`/`actionButtons` helpers
- `AustrianRocks/en.lproj/Localizable.strings` — new upstream keys need German translation (copy English, then translate as they come up)

## Features to re-add after future merges

These were intentional fork additions that may need reapplying when upstream refactors the surrounding code:

- **Video links on problem details.** `Problem.videoLinks: [String]?` is populated from SQLite JSON. The old fork had a `descriptionAndVideos` view in `ProblemDetailsView` that rendered them. Upstream's newer `ProblemInfoView` / `ProblemActionButtonsView` don't include description or videos — if you want them back, add an inline block under `ProblemInfoView` in `ProblemDetailsView`.
- **Dark mode map style.** Currently `BrandConfig.Mapbox.darkStyleID == styleID`. When an Austrian Rocks dark style is created, set `darkStyleID` separately.

## Sanity checklist before merging the branch back

Run these greps — they should all return 0 results (except where noted):

```bash
# No unresolved conflict markers
grep -rn "<<<<<<<\|=======\|>>>>>>>" AustrianRocks AustrianRocks.xcodeproj || echo OK

# No circuit refs outside CircleView comments
grep -rn "circuit\|Circuit" AustrianRocks --include="*.swift" | grep -v "CircleView"

# No non-optional grade access
grep -rn "\.grade\.string\|\.grade\.min\|\.grade <\|\.grade >" AustrianRocks --include="*.swift"

# No references to deleted files
grep -rn "ContributeView\|CircuitPickerView\|CircuitView\.swift\|boolder\.db" AustrianRocks --include="*.swift"

# pbxproj is a valid plist
plutil -lint AustrianRocks.xcodeproj/project.pbxproj
```

Then open Xcode, build, run. `xcodebuild` isn't available in this repo's dev environment (only Command Line Tools are installed).

## History

- **2025-12-13 (`e9088a71`):** Initial Boolder → Austrian Rocks migration. Files renamed, circuits removed, French dropped, Austrian data/branding added.
- **First upstream merge (`4df73378` + `eb7d477e`, 2026-04-20):** Pulled ~389 upstream commits. Conflict resolution captured in this doc. Circuit stripping done in a follow-up commit.
