# Map download button vanishes when zoomed in on Schleierwasserfall

> "Wenn man auf Schleierwasserfall zum Reinzoomen drückt, wird der Download-Button weiß und ma sieht ihn nimmer."

The floating download button on the **map view** disappears when zoomed in on Schleierwasserfall. (Not related to area cover photos — those don't render on the map.)

## Where it lives

- `AustrianRocks/UI/Map/MapContainerView.swift:224-252` builds the FAB stack. The download FAB and location FAB both apply `.foregroundColor(.primary)` (lines 235, 245) and `.adaptiveFabStyle()`.
- `AustrianRocks/UI/Misc/Extensions.swift:134-142` defines `adaptiveFabStyle()`:
  - iOS 26+: `glassEffect(.regular.interactive(), in: .circle)` — translucent, inherits color from what's behind it.
  - iOS < 26: `FabButton` style → solid `Color(.systemBackground)` circle with shadow (`Extensions.swift:127-130`).
- `AustrianRocks/UI/Map/Download/DownloadButtonView.swift:17-33` renders only the SF Symbol / progress view inside the button — no own background, no own tint.

## Why Schleierwasserfall specifically

Schleierwasserfall is an alpine area; its map tiles around the zoomed-in viewport are dominated by very bright snow/ice/light rock. With:

- `.foregroundColor(.primary)` in light mode = black (should still be visible) — so the bug is most likely happening in **dark mode**, where `.primary` resolves to white. White icon + glass-effect button + bright snowy tiles ≈ invisible.
- On iOS 26 the `glassEffect` is translucent so the bright tile shows through and washes out the icon.
- On iOS < 26 the `FabButton` background is `systemBackground`, which is black in dark mode → the icon should be readable. Confirm whether the bug reproduces on iOS < 26 to narrow this down.

## Steps

1. Reproduce on device/simulator: zoom to Schleierwasserfall in dark mode on iOS 26, then in light mode, then on an iOS < 26 simulator. Note exactly which combinations show the bug.
2. Decide on the fix approach:
   - **Tint the icon, not `.primary`.** Set the FAB symbol color to `appBrandColor` (`Extensions.swift:54-62` → `BrandConfig.Brand.color` = AppGreen) so it stays readable on any backdrop. Apply at `MapContainerView.swift:235` and the location button at line 245.
   - **Or strengthen the glass background.** For iOS 26 add a tinted glass variant (e.g. `glassEffect(.regular.tint(...).interactive(), in: .circle)`) so the button has its own contrast against bright tiles.
   - **Or add a subtle stroke / shadow** around the icon so it pops on any background (similar to the iOS < 26 `FabButton` shadow at `Extensions.swift:129`).
3. Apply the same treatment to:
   - The location FAB right below it (`MapContainerView.swift:238-250`) — same root cause.
   - The `DownloadButtonPlaceholderView` (`AustrianRocks/UI/Map/Download/DownloadButtonPlaceholderView.swift`).
4. Verify no regression on darker map regions (forests, lakes, urban tiles) and in both light and dark mode.

## Corrected root cause

The original analysis above is partly wrong. The real issue: the code set an
explicit `.foregroundColor(.primary)` on the FAB symbols, which **defeats iOS
26 Liquid Glass's automatic vibrancy** (the system normally adapts a glass
button's symbol color/brightness/saturation to whatever is behind it). Note
also that this auto-vibrancy only applies to *system* glass
(`.buttonStyle(.glass)` / toolbar items), **not** to a custom `Image` dropped
into a raw `.glassEffect()` — and a flat neutral tint used purely for contrast
is an Apple anti-pattern (tint is for semantic prominence only).

## Resolution

- `Extensions.swift` `adaptiveFabStyle()`: iOS 26 path switched from
  `glassEffect(.regular.interactive(), in: .circle)` to
  `.buttonStyle(.glass).buttonBorderShape(.circle)` so the system applies its
  own vibrancy. Mirrors the existing `adaptiveCircleButtonStyle()`.
- New `adaptiveFabForeground()` helper: no foreground color on iOS 26 (lets
  vibrancy pick it), `.foregroundColor(.primary)` on older iOS (solid opaque
  FAB backing there). Applied to the download FAB and location FAB in
  `MapContainerView.swift`.
- Search bar: same treatment — system `.buttonStyle(.glass)`, no hardcoded
  color on iOS 26, `.secondaryLabel` retained on older iOS.
- No decorative tint anywhere. If vibrancy ever proves insufficient over an
  extreme backdrop, the sanctioned escalation is `.glassProminent`, not a tint.

## Done when

- The map download FAB and location FAB are clearly visible at any zoom level
  over Schleierwasserfall in both light and dark mode, on iOS 26 and the
  lowest supported iOS version.
- No regression on other areas.
