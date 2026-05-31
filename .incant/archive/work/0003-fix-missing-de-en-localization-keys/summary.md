---
id: "0003"
slug: fix-missing-de-en-localization-keys
stage: archived
completed: 2026-05-31
commit: 8cef335e19573a0c4f0e670d3b824d5366c6da68
---

# Fix Missing De En Localization Keys — summary

## What was built
- Restored English/German `Localizable.strings` key parity for shipped localization keys.
- Added missing German counterparts for existing English search, boulder, topo/start-group keys and added the missing `discover.top_areas.level.beginner.intro` key in both languages.
- Removed the unused German-only `problem.pagination` key after confirming the canonical shipped start-group pagination keys are present.
- Converted release-facing hardcoded SwiftUI copy in Discover region/cluster/area views, problem video copy, and area-download swipe delete copy to localization keys with English and German values.
- Preserved `InfoPlist.strings` privacy usage descriptions in both English and German.

## Deviations from spec
- None. The implementation stayed within the accepted `.strings`-based localization approach and did not add permanent audit tooling.

## Key decisions
- Kept brand names, third-party app names, URLs, symbols, dynamic area/problem/region/cluster names, development-only UI, test-only UI, and standard `OK` button copy as intentional literals.
- Used one-shot parity/source-inspection commands for verification rather than adding repository tooling.
- Used `NSLocalizedString` only where a resolved format string is needed for `String(format:)`; direct SwiftUI localized strings continue to use key literals.

## Links
- `6744350b` — `incant 0003: spec`
- `f4351d61` — `incant 0003: plan`
- `01e14529` — `incant 0003-P1: restore localization key parity`
- `8cef335e` — `incant 0003-P2: localize release-facing UI copy`

## Sessions
- `019e7e77-4f05-7bb0-aed0-addccb698b9b`
- `019e7e7e-114b-75ef-8113-1ab2b03313e2`
- `019e7e81-d1ea-75b0-b1e3-68d57ff56cac`
- `019e7e83-e8a0-7866-a2ed-1fc2d284afe5`
- `019e7e85-50f5-70e9-988e-ffc810063d38`
- `019e7e89-5c0e-79cc-82a4-43d48835a9df`

## Follow-ups
- None.
