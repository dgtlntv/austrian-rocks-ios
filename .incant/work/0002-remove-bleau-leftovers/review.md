---
id: "0002"
slug: remove-bleau-leftovers
stage: review
reviewed: 2026-05-31
commit: 538348fad28f2408c223c52b691eaa8f3a99820d
---

# Remove Bleau Leftovers — review

### Strengths
- `README.md:1` and `README.md:3` now present the repository as Austrian.rocks, and the old Boolder/FONT/Bleau product copy, old URLs, and `hello@boolder.com` contact have been removed while preserving secret-safe Mapbox setup instructions at `README.md:19` and `README.md:31`.
- `AustrianRocks/en.lproj/Localizable.strings:127` replaces the Fontainebleau-specific grade warning with neutral area-variation copy, matching the phase goal without introducing a new branded reference.
- `AustrianRocks/UI/Discover/TopAreasDryFast.swift:61` cleanly removes the Bleau Météo useful-link row rather than substituting an unverified weather source, which follows the plan decision and avoids adding untrusted or speculative static links.
- `AustrianRocks/UI/Map/MapboxViewController.swift:646` replaces the old Fontainebleau fallback with a clearly named `austriaFallbackBounds`, and `AustrianRocks/UI/Map/MapboxViewController.swift:647`-`648` use the exact Austria-wide bounds required by the spec.
- `AustrianRocks/UI/Map/MapboxViewController.swift:653` and `AustrianRocks/UI/Map/MapboxViewController.swift:663` consistently use the Austria bounds for both in-bounds and extend-to-current-location camera paths, so the fallback behaviour remains coherent.
- The stale Swift file header sweep preserves provenance while removing launch-facing app-name leftovers: for example, `AustrianRocks/Models/Boulder.swift:3` now says `Austrian.rocks` and `AustrianRocks/Models/Boulder.swift:5` keeps the original Boolder/Nicolas attribution as an explicit provenance line; the same pattern is applied across the planned map/search/misc files.
- Metadata and launch-facing project files were checked with `rg -ni "boolder|fontainebleau|bleau|nmondollot|hello@" AustrianRocks.xcodeproj/project.pbxproj AustrianRocks.xcodeproj/xcshareddata/xcschemes AustrianRocks/Assets.xcassets/AppIcon.appiconset/Contents.json AustrianRocks/Assets.xcassets/AppIconDev.appiconset/Contents.json AustrianRocks/Assets.xcassets/LaunchBackground.colorset/Contents.json AustrianRocks/Assets.xcassets/LaunchLogo.imageset/Contents.json AustrianRocks/Info.plist Dev-Info.plist`, which produced no output (`exit=1`).
- Fresh phase-gate evidence was rerun during review: `rg -n "fontainebleauBounds|Fontainebleau|fontainebleau|Bleau Météo|Bleau-Meteo|//  Boolder$" AustrianRocks AustrianRocks.xcodeproj/xcshareddata/xcschemes AustrianRocks.xcodeproj/project.pbxproj Dev-Info.plist` produced no output (`exit=1`), so the P2 stale-reference gate passes.

### Blocker
- None.

### Major
- None.

### Minor
- None.

### Nit
- None.

### Verdict
Ready to release? **No** — phases 0002-P1 and 0002-P2 pass review with no open findings, but this work item is not release-complete until planned phase 0002-P3 final classification and build verification are implemented and reviewed.
