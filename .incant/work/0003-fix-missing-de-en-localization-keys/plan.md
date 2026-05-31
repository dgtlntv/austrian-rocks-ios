---
id: "0003"
slug: fix-missing-de-en-localization-keys
branch: incant/0003-fix-missing-de-en-localization-keys
title: Fix Missing De En Localization Keys
stage: plan
status: in-progress
created: 2026-05-31
commit: 6744350b
updated: 2026-05-31
---

# Fix Missing De En Localization Keys — plan

## Status
- Phase: 0003-P1 (of 2) · stage: review
- Branch: incant/0003-fix-missing-de-en-localization-keys
- Next: run `/incant:review 0003` for the 0003-P1 phase gate.
- Blockers: none
- Evidence: 2026-05-31 P1 gate passed — ad hoc key-parity check printed `OK: 155 shared Localizable.strings keys` and exited 0.
- Decisions:
  - The spec frontmatter `commit: 3285ee60` is behind current `HEAD` (`6744350b`) because the approved spec was committed on this branch; `git diff --stat 3285ee60..HEAD -- . ':!.incant'` produced no code/resource diff, and the affected Swift/localization files were re-read while planning, so the spec still holds.
  - Use the existing `.strings` localization pattern; do not add String Catalogs, permanent audit scripts, or new repository tooling.
  - Keep brand names, third-party app names, URLs, symbols, data-driven area/problem/region/cluster names, numeric strings, punctuation bullets, debug-only UI, and test-only UI as intentional literals unless a release-facing hardcoded English label is listed below.

## Files touched
- `AustrianRocks/en.lproj/Localizable.strings` (edit) — add every missing English key and every new English value introduced by hardcoded release-facing UI conversions.
- `AustrianRocks/de.lproj/Localizable.strings` (edit) — add every missing German key and every new German value introduced by hardcoded release-facing UI conversions; remove or replace obsolete `problem.pagination` only if parity/audit proves it is unused after the canonical keys are present.
- `AustrianRocks/UI/Discover/TopAreasBeginnerView.swift` (edit) — keep using `discover.top_areas.level.beginner.intro` after adding the missing localized values.
- `AustrianRocks/UI/Discover/DiscoverView.swift` (edit) — localize release-facing “All Regions” and region cluster-count copy while leaving the `#if DEVELOPMENT` “Dev”/“Settings” labels out of scope.
- `AustrianRocks/UI/Discover/RegionsListView.swift` (edit) — localize release-facing “Regions” and region cluster-count copy.
- `AustrianRocks/UI/Discover/RegionDetailView.swift` (edit) — localize release-facing “Clusters”, “No clusters available”, and cluster area-count copy.
- `AustrianRocks/UI/Discover/ClusterDetailView.swift` (edit) — localize release-facing “Areas”, “No areas available”, and area problem-count copy.
- `AustrianRocks/UI/Map/Problem details/ProblemDetailsView.swift` (edit) — localize release-facing video section title and watch-video button copy.
- `AustrianRocks/UI/Map/Download/AreaDownloadRowView.swift` (edit) — localize the release-facing swipe action label “Delete”.
- `AustrianRocks/en.lproj/InfoPlist.strings` (inspect) — verify English privacy usage descriptions remain present and unchanged.
- `AustrianRocks/de.lproj/InfoPlist.strings` (inspect) — verify German privacy usage descriptions remain present and unchanged.
- `.incant/work/0003-fix-missing-de-en-localization-keys/plan.md` (edit during implementation) — keep phase status, evidence, and intentional-literal implementation notes current.

## Phase 0003-P1 — existing localization key parity
- [x] Read `AustrianRocks/en.lproj/Localizable.strings`, `AustrianRocks/de.lproj/Localizable.strings`, `AustrianRocks/UI/Discover/TopAreasBeginnerView.swift`, `AustrianRocks/UI/Map/Search/SearchSheetView.swift`, `AustrianRocks/UI/Map/Problem details/Topo/TopoCarouselView.swift`, `AustrianRocks/UI/Map/Problem details/Topo/StartGroupMenuView.swift`, and `AustrianRocks/UI/Map/Problem details/ProblemActionButtonsView.swift` before editing resources.
- [x] In `AustrianRocks/de.lproj/Localizable.strings`, add the missing counterparts for existing English keys: `search.popular_areas = "Beliebte Gebiete"`, `search.popular_problems = "Beliebte Boulder"`, `boulder.info_basic = "%d Boulder"`, `boulder.info_basic_singular = "%d Boulder"`, `problem.startgroup.pagination = "%d/%d"`, `problem.startgroup.variants.singular = "%d Variante"`, and `problem.startgroup.variants.plural = "%d Varianten"`.
- [x] In both `AustrianRocks/en.lproj/Localizable.strings` and `AustrianRocks/de.lproj/Localizable.strings`, add the missing shipped key `discover.top_areas.level.beginner.intro`; use English copy `These areas are a good starting point if you are new to bouldering or want easier problems.` and German copy `Diese Gebiete sind ein guter Einstieg, wenn du neu beim Bouldern bist oder leichtere Boulder suchst.`
- [x] Resolve the German-only `problem.pagination` parity mismatch by either deleting it from `AustrianRocks/de.lproj/Localizable.strings` if `rg -n 'problem\.pagination' AustrianRocks --glob '*.swift'` confirms it is unused, or adding the same key to English only if implementation discovers a shipped reference that needs it.
- [x] Run the ad hoc key-parity check from the repo root and fix every reported `EN-only` or `DE-only` key before checking off the phase:
  ```bash
  python3 - <<'PY'
  import re
  from pathlib import Path
  def keys(path):
      return set(re.findall(r'^\s*"([^"]+)"\s*=', Path(path).read_text(encoding='utf-8'), re.M))
  en = keys('AustrianRocks/en.lproj/Localizable.strings')
  de = keys('AustrianRocks/de.lproj/Localizable.strings')
  if en != de:
      print('EN-only:', '\n'.join(sorted(en - de)))
      print('DE-only:', '\n'.join(sorted(de - en)))
      raise SystemExit(1)
  print(f'OK: {len(en)} shared Localizable.strings keys')
  PY
  ```
**Quality gate:** `python3 - <<'PY'
import re
from pathlib import Path
def keys(path):
    return set(re.findall(r'^\s*"([^"]+)"\s*=', Path(path).read_text(encoding='utf-8'), re.M))
en = keys('AustrianRocks/en.lproj/Localizable.strings')
de = keys('AustrianRocks/de.lproj/Localizable.strings')
if en != de:
    print('EN-only:', '\n'.join(sorted(en - de)))
    print('DE-only:', '\n'.join(sorted(de - en)))
    raise SystemExit(1)
print(f'OK: {len(en)} shared Localizable.strings keys')
PY` → prints `OK: ... shared Localizable.strings keys` and exits 0.

## Phase 0003-P2 — release-facing hardcoded UI conversion and final verification
- [ ] Read `AustrianRocks/UI/Discover/DiscoverView.swift`, `AustrianRocks/UI/Discover/RegionsListView.swift`, `AustrianRocks/UI/Discover/RegionDetailView.swift`, `AustrianRocks/UI/Discover/ClusterDetailView.swift`, `AustrianRocks/UI/Map/Problem details/ProblemDetailsView.swift`, `AustrianRocks/UI/Map/Download/AreaDownloadRowView.swift`, `AustrianRocks/en.lproj/Localizable.strings`, and `AustrianRocks/de.lproj/Localizable.strings` before editing Swift or resources.
- [ ] In `AustrianRocks/en.lproj/Localizable.strings` and `AustrianRocks/de.lproj/Localizable.strings`, add the new release-facing keys used by this phase: `discover.regions.all` (`All Regions` / `Alle Regionen`), `discover.regions.title` (`Regions` / `Regionen`), `discover.regions.clusters` (`%d clusters` / `%d Cluster`), `discover.region.clusters` (`Clusters` / `Cluster`), `discover.region.no_clusters` (`No clusters available` / `Keine Cluster verfügbar`), `discover.cluster.areas` (`Areas` / `Gebiete`), `discover.cluster.no_areas` (`No areas available` / `Keine Gebiete verfügbar`), `discover.cluster.areas_count` (`%d areas` / `%d Gebiete`), `discover.cluster.problems_count` (`%d problems` / `%d Boulder`), `problem.videos.title` (`Videos` / `Videos`), `problem.videos.watch` (`Watch video` / `Video ansehen`), and `download.area.delete` (`Delete` / `Löschen`).
- [ ] In `AustrianRocks/UI/Discover/DiscoverView.swift`, replace `Text("All Regions")` with `Text("discover.regions.all")`, replace `Text("\(region.clusters.count) clusters")` with `Text(String(format: NSLocalizedString("discover.regions.clusters", comment: ""), region.clusters.count))`, and leave the `#if DEVELOPMENT` literals `Dev` and `Settings` unchanged as explicitly out of scope.
- [ ] In `AustrianRocks/UI/Discover/RegionsListView.swift`, replace `Text("\(region.clusters.count) clusters")` with `Text(String(format: NSLocalizedString("discover.regions.clusters", comment: ""), region.clusters.count))`, and replace `.navigationTitle("Regions")` with `.navigationTitle("discover.regions.title")`.
- [ ] In `AustrianRocks/UI/Discover/RegionDetailView.swift`, replace `Section(header: Text("Clusters").font(.title2).fontWeight(.bold))` with `Section(header: Text("discover.region.clusters").font(.title2).fontWeight(.bold))`, replace `Text("No clusters available")` with `Text("discover.region.no_clusters")`, and replace `Text("\(cluster.areas.count) areas")` with `Text(String(format: NSLocalizedString("discover.cluster.areas_count", comment: ""), cluster.areas.count))`.
- [ ] In `AustrianRocks/UI/Discover/ClusterDetailView.swift`, replace `Section(header: Text("Areas"))` with `Section(header: Text("discover.cluster.areas"))`, replace `Text("No areas available")` with `Text("discover.cluster.no_areas")`, and replace `Text("\(area.problemsCount) problems")` with `Text(String(format: NSLocalizedString("discover.cluster.problems_count", comment: ""), area.problemsCount))`.
- [ ] In `AustrianRocks/UI/Map/Problem details/ProblemDetailsView.swift`, replace `Text("Videos")` with `Text("problem.videos.title")` and replace `Text("Watch video")` with `Text("problem.videos.watch")`.
- [ ] In `AustrianRocks/UI/Map/Download/AreaDownloadRowView.swift`, replace `Label("Delete", systemImage: "trash.fill")` with `Label("download.area.delete", systemImage: "trash.fill")`.
- [ ] Inspect release-facing SwiftUI literals with `rg -n 'Text\("[A-Z][A-Za-z ]*"\)|Label\("[A-Z][A-Za-z ]*"|navigationTitle\("[A-Z][A-Za-z ]*"' AustrianRocks --glob '*.swift' --glob '!**/SettingsView.swift' --glob '!**/Test*.swift'`; convert any remaining release-facing hardcoded English UI copy discovered by the command, and document intentional literals in this plan's Status decisions/evidence before checking off the phase.
- [ ] Verify `AustrianRocks/en.lproj/InfoPlist.strings` still contains `NSLocationWhenInUseUsageDescription`, `LocationAccuracyAuthorizationDescription`, and `NSCameraUsageDescription`, and verify the same three keys remain in `AustrianRocks/de.lproj/InfoPlist.strings`.
- [ ] Run the final ad hoc key-parity check from Phase 0003-P1 and the final Xcode build command; fix failures before checking off the phase.
**Quality gate:** `python3 - <<'PY'
import re
from pathlib import Path
def keys(path):
    return set(re.findall(r'^\s*"([^"]+)"\s*=', Path(path).read_text(encoding='utf-8'), re.M))
en = keys('AustrianRocks/en.lproj/Localizable.strings')
de = keys('AustrianRocks/de.lproj/Localizable.strings')
required_info = {'NSLocationWhenInUseUsageDescription', 'LocationAccuracyAuthorizationDescription', 'NSCameraUsageDescription'}
if en != de:
    print('EN-only:', '\n'.join(sorted(en - de)))
    print('DE-only:', '\n'.join(sorted(de - en)))
    raise SystemExit(1)
for path in ['AustrianRocks/en.lproj/InfoPlist.strings', 'AustrianRocks/de.lproj/InfoPlist.strings']:
    text = Path(path).read_text(encoding='utf-8')
    missing = [key for key in required_info if key not in text]
    if missing:
        print(f'{path} missing: {missing}')
        raise SystemExit(1)
print(f'OK: {len(en)} shared Localizable.strings keys and InfoPlist privacy keys present')
PY
xcodebuild -project AustrianRocks.xcodeproj -scheme AustrianRocks -configuration Debug -sdk iphonesimulator build` → script prints `OK: ... shared Localizable.strings keys and InfoPlist privacy keys present`, `xcodebuild` exits 0, and the build log ends with `** BUILD SUCCEEDED **`.

## Coverage self-review
- [x] Requirement 1 maps to 0003-P1 key-parity edits and both phase quality gates.
- [x] Requirement 2 maps to 0003-P1's shipped key additions and 0003-P2's final parity/source inspection.
- [x] Requirement 3 maps to 0003-P2's explicit hardcoded release-facing UI conversions and intentional-literal notes.
- [x] Requirement 4 maps to Status decisions and the 0003-P2 inspection exclusions/intentional-literal documentation.
- [x] Requirement 5 maps to 0003-P2 InfoPlist privacy-key inspection in the final quality gate.
- [x] Requirement 6 maps to Status decisions and the use of ad hoc one-shot commands only.
- [x] Symbol/signature consistency checked: new Swift references use `NSLocalizedString(..., comment: "")` only where `String(format:)` needs resolved format strings; direct `Text("key")`, `Label("key", systemImage:)`, and `.navigationTitle("key")` continue using SwiftUI localization.
- [x] No placeholders remain in this plan.
