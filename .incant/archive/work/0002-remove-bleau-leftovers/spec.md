---
id: "0002"
slug: remove-bleau-leftovers
branch: incant/0002-remove-bleau-leftovers
title: Remove Bleau Leftovers
stage: spec
status: in-progress
created: 2026-05-31
commit: 749c1f20
updated: 2026-05-31
---

# Remove Bleau Leftovers

## Goal
Remove or reclassify every non-attribution Boolder, Fontainebleau, Bleau, nmondollot, and old contact/link reference from Austrian.rocks app surfaces, repository docs, project metadata, and hardcoded geography before launch.

## Context & codebase fit
Austrian.rocks is already partly rebranded: `AustrianRocks/Config/BrandConfig.swift` centralizes the app name, domains, contact email, Mapbox IDs, and database filename; `AustrianRocks/Info.plist`, localized InfoPlist strings, many Swift file headers, and production bundle ID already use Austrian.rocks naming. A scout grep found remaining launch-blocking old references in several places:

- `README.md` still describes Boolder, Fontainebleau, old Boolder URLs, and `hello@boolder.com`.
- `AustrianRocks/en.lproj/Localizable.strings` contains a Fontainebleau-specific grade warning for intermediate areas.
- `AustrianRocks/UI/Discover/TopAreasDryFast.swift` links to and labels “Bleau Météo”.
- `AustrianRocks/UI/Map/MapboxViewController.swift` still uses `fontainebleauBounds` around Fontainebleau coordinates as the current-location fallback.
- Several Swift headers still contain `//  Boolder`; many also preserve original `Created by Nicolas Mondollot` / copyright lines.
- `AustrianRocks/Acknowledgements.json` intentionally lists Boolder as an attribution/license entry.
- App assets and project settings already include Austrian.rocks-facing assets and bundle IDs, but launch assets, app icons, dev bundle IDs, schemes, and generated/user-specific Xcode metadata need an explicit check and classification.

This item is a cleanup and verification pass. It should not change legal provenance that must remain visible in attribution/license contexts.

## Requirements
1. Rewrite `README.md` so it presents Austrian.rocks, contains no Boolder/Fontainebleau/Bleau-specific product copy, and contains no old Boolder URLs or old Boolder email addresses.
2. Remove old place/app references from localized strings in all languages: no user-visible localized value may mention Boolder, Fontainebleau, Bleau, old Boolder URLs, or old Boolder email addresses unless it is an intentional legal attribution string.
3. Remove old links/emails from user-facing UI and docs. The `TopAreasDryFast` useful link must no longer point to or label Bleau Météo; it must either use an Austria-appropriate resource or remove the link section if no suitable resource exists.
4. Replace Fontainebleau hardcoded geography in `MapboxViewController.centerOnCurrentLocation()` with fixed Austria-wide bounds: southwest latitude `46.372276`, southwest longitude `9.530748`, northeast latitude `49.020530`, northeast longitude `17.160776`. Variable names must describe Austria, not Fontainebleau.
5. Verify app icons, launch assets, asset names, bundle IDs, and shared schemes for launch-facing stale references. Replace stale non-attribution references; classify any intentional remnants.
6. Preserve original copyright, license, and required attribution references, including Boolder entries in `AustrianRocks/Acknowledgements.json`, unless a reference appears outside an attribution/license context.
7. Re-run `rg -n "boolder|fontainebleau|bleau|nmondollot|hello@" .` before completion and classify every remaining match as one of: `intentional attribution`, `copyright/license`, or `needs replacement`.
8. Broaden cleanup to other non-Austrian Fontainebleau/Bleau-related wording discovered during implementation; ordinary SwiftUI `.font(...)` APIs and generic font-family metadata are not in scope unless they contain old app/place branding.

## In scope / Out of scope
**In scope:**
- `README.md` launch-facing rewrite for Austrian.rocks.
- English and German localized strings and localized InfoPlist strings.
- Swift user-facing UI strings, labels, links, and relevant variable names tied to old geography.
- `MapboxViewController.centerOnCurrentLocation()` fallback bounds and naming.
- Xcode project metadata, shared schemes, bundle identifiers, app icon configuration, and launch asset references if they expose stale old app/place references.
- Swift file header first-line app-name comments that still say Boolder, when changing them does not disturb legal copyright lines.
- Final grep classification evidence for `boolder|fontainebleau|bleau|nmondollot|hello@`.

**Out of scope:**
- Removing required open-source attribution or license notices — reason: legal provenance must remain intact.
- Rewriting original `Created by` or copyright holder lines solely because they mention Nicolas Mondollot or Boolder — reason: the user explicitly asked to keep original copyright headers where legally required.
- Changing Mapbox styles, data tilesets, or the bundled SQLite dataset beyond stale reference cleanup — reason: this item is branding/geography cleanup, not data migration.
- Designing new app icons or launch artwork from scratch — reason: this item verifies and renames/repoints stale assets but does not create new brand art.
- App Store privacy/review metadata outside the repository — reason: tracked separately by backlog item `0004`.

## Approach
Perform a repository-wide cleanup driven by greps rather than a narrow hand-picked edit. First update product-facing text and code paths: rewrite the README, remove or replace Bleau/Fontainebleau localized copy and UI links, and swap the current-location fallback to fixed Austria bounds. Then inspect asset catalogs, launch assets, bundle IDs, and schemes for stale old branding, changing only non-attribution stale references. Finally run the required grep and classify remaining matches in the implementation notes or review evidence so intentional legal/provenance references are clearly separated from actionable leftovers.

Rejected alternatives: dynamic bounds from the bundled areas database were considered for the map fallback, but the approved direction is a fixed Austria-wide bounding box. A blanket deletion of all Boolder/Nicolas references was rejected because acknowledgements, license text, and copyright headers may be legally required.

## Considerations
### Config vs code
The approved Austria fallback bounds are configuration-like constants, but for this small existing Mapbox controller path they may remain as a single named constant or local `CoordinateBounds` in `MapboxViewController.swift`; duplicating them in scattered literals is not acceptable. Existing brand values should continue to come from `BrandConfig` where the app already provides a central source (`name`, domains, contact email, Mapbox config, database filename). README and localized copy are content files, not runtime configuration.

### Security
No secrets or credentials are introduced. README Mapbox setup must continue to instruct developers to store tokens outside the repository (`~/.mapbox` and `~/.netrc`) and must not include real tokens. Link cleanup should avoid adding untrusted dynamic URL construction; static public URLs are acceptable. The grep evidence and `.incant/` artifacts must not contain credentials.

### Testability
Verification is primarily static and build-oriented. The implementation plan should include fresh greps for old references, inspection/classification of remaining matches, and an Xcode build command if available for this project. The map bounds change is observable by reviewing the fixed coordinates and variable names; UI link/string cleanup is observable through localized-string grep results and code review. Manual verification may be needed for app icon and launch asset appearance because image contents are not reliably asserted by automated tests.

### Code documentation
This cleanup should not add noisy comments around obvious string or bounds replacements. If a named Austria fallback bounds constant is introduced, a concise comment may explain that it is a fixed country-wide fallback for users outside the active data area. Legal/copyright headers should remain tasteful and accurate; only stale non-legal app-name header comments should be normalized.

## Acceptance criteria
- [ ] `README.md` describes Austrian.rocks and contains no old Boolder product copy, Fontainebleau/Bleau product copy, old Boolder URLs, or `hello@boolder.com`.
- [ ] Localized strings in `AustrianRocks/en.lproj` and `AustrianRocks/de.lproj` contain no non-attribution Boolder, Fontainebleau, Bleau, old Boolder URL, or old Boolder email references.
- [ ] `TopAreasDryFast` no longer links to or labels Bleau Météo.
- [ ] `MapboxViewController.centerOnCurrentLocation()` uses Austria-wide fallback bounds `46.372276, 9.530748` to `49.020530, 17.160776`, and related identifiers no longer mention Fontainebleau.
- [ ] App icon configuration, launch assets, bundle IDs, and shared schemes have been checked; any stale non-attribution old app/place references found there are replaced.
- [ ] Required legal attribution/license/copyright references are preserved and explicitly classified rather than deleted.
- [ ] A fresh `rg -n "boolder|fontainebleau|bleau|nmondollot|hello@" .` has no `needs replacement` matches remaining.
- [ ] The project build or an agreed static verification gate runs successfully after cleanup.

## Risks & open questions
- The exact replacement for the Bleau Météo useful link is not predetermined; if no suitable Austria-wide drying/weather resource exists in the codebase, removing the link section is acceptable.
- Some Xcode `xcuserdata` files may be user-specific rather than launch-facing project metadata; implementation should avoid unnecessary churn while still classifying stale matches.
- Image contents for app icons and launch assets may require manual visual confirmation if filenames and catalog metadata are not enough.
