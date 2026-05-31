---
id: "0001"
slug: attribution-acknowledgements
stage: archived
completed: 2026-05-31
commit: 4aa4c4fa488e448c23b3818f3b822a8a81700e21
---

# Attribution Acknowledgements — summary

## What was built
- Added a production-visible Discover support entry for About / Acknowledgements in English and German.
- Added `AcknowledgementsView` with compact grouped acknowledgement rows and per-entry detail screens exposing versions, licenses, URLs, copyright, and selectable legal notice text.
- Added bundled `AustrianRocks/Acknowledgements.json` as the legal-content source of truth, including Boolder MIT and audited currently resolved non-Apple Swift Package notices.
- Added `AcknowledgementCatalog` decoding/loading with typed errors and a localized non-crashing fallback for missing or malformed JSON.
- Wired the new Swift files and JSON resource into both `AustrianRocks` and `AustrianRocks dev` app targets while leaving existing Mapbox on-map attribution controls untouched.

## Deviations from spec
- No dedicated automated test target was added; the project does not currently have a practical test target for this slice, so verification used JSON validation, both app-target builds, and manual/user flow confirmation.
- The main acknowledgements screen uses compact rows with full legal text on detail screens rather than expanding every notice inline, to keep the production UI responsive while preserving access to required notices.

## Key decisions
- The route lives in the existing production Discover support section instead of exposing the development-only settings screen.
- Legal notice content is data-driven in JSON; Swift owns decoding, fallback handling, and rendering.
- Mapbox-to-MapLibre replacement is documented as a data update path in the catalog loader/schema comments.
- Audited omissions are recorded in JSON where absence could otherwise look accidental.

## Links
- Final implementation commit: `4aa4c4fa488e448c23b3818f3b822a8a81700e21` (`incant 0001-P3: verify acknowledgements acceptance`).
- Phase commits: `777c4200` (P1), `3a7a81bc` (P2), `4aa4c4fa` (P3).
- Review: `review.md` verdict is ready to release with no blocker or major findings.

## Sessions
- `019e7dac-68ac-7a71-a68f-2e549b0556db`
- `019e7dc6-6492-7bd3-a127-16abe7c118ff`
- `019e7dcb-4d45-7f9d-9056-635d698ea85c`
- `019e7dcd-33bd-7b31-9326-831997a0967d`
- `019e7dd1-e78f-7e16-b4ab-b5d1c13c642d`
- `019e7dd6-e3af-7acf-bbf1-39e95f4d339f`
- `019e7df2-7f53-752b-8dad-2f4bd811560a`
- `019e7df4-6f79-75c4-aa21-2cb20689b190`

## Follow-ups
- None spawned during finalization.
