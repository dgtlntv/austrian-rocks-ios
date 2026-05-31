---
id: "0002"
slug: remove-bleau-leftovers
stage: review
reviewed: 2026-05-31
commit: f76f0bbdc719553b71da725a0639a3a82af03ffc
---

# Remove Bleau Leftovers — review

### Strengths
- `README.md:1` and `README.md:3` now present the repository as Austrian.rocks, and the old Boolder/FONT/Bleau product copy, old URLs, and `hello@boolder.com` contact have been removed while preserving secret-safe Mapbox setup instructions at `README.md:19` and `README.md:31`.
- `AustrianRocks/en.lproj/Localizable.strings:127` replaces the Fontainebleau-specific grade warning with neutral area-variation copy, matching the phase goal without introducing a new branded reference.
- `AustrianRocks/UI/Discover/TopAreasDryFast.swift:61` cleanly removes the Bleau Météo useful-link row rather than substituting an unverified weather source, which follows the plan decision and avoids adding untrusted or speculative static links.
- Fresh phase-gate evidence was rerun during review: `rg -n "Boolder|Fontainebleau|Bleau|boolder|fontainebleau|bleau|hello@boolder.com" README.md AustrianRocks/en.lproj/Localizable.strings AustrianRocks/de.lproj/Localizable.strings AustrianRocks/UI/Discover/TopAreasDryFast.swift` produced no output (`exit=1`), so the P1 stale-reference cleanup gate passes.

### Blocker
- None.

### Major
- None.

### Minor
- None.

### Nit
- None.

### Verdict
Ready to release? **No** — phase 0002-P1 passes review with no open findings, but this work item is not release-complete until planned phases 0002-P2 and 0002-P3 are implemented and reviewed.
