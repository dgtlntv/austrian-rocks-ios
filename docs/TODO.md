- Wenn man auf schelierwasserfall zum reinzoomen drückt wird der download button weiß und ma sieht ihn nimmer
- ich muss in den daten die problem punkte weiter in the fells reinziehn damit die problems list net leer is und dann den geo rake laufen lassen
- die ia is a bissl falsch ma klickt auf malattal und kommt direkt zum download
- die breadcrumbs irgendow sind ein bissl weird

## Branding: area cover photos

The Fontainebleau-era covers under `AustrianRocks/Assets.xcassets/area-covers/` have been removed. `AreaCardView.swift:31` still loads `Image("area-cover-\(area.id)")`, so until new covers are added every area card renders an empty background. To finish the job:

- Take/source one landscape photo per Austrian area listed in `austrian-rocks.db` (`SELECT id, name FROM areas`). Currently 7 areas: 1 Air, 2 La Balance, 3 Meilenstein, 4 Helicopter, 5 Wrestling, 6 Bachlblock, 7 Milchstraße. Re-run the query before shooting — the list grows as data is imported.
- Add each photo as `AustrianRocks/Assets.xcassets/area-covers/area-cover-{id}.imageset/`, using the same `Contents.json` shape the deleted imagesets had (single 1x universal slot is fine, or 1x/2x/3x if available).
- Filename inside the imageset must match the asset name (`area-cover-{id}.jpg` or `.png`). The image lookup is by asset name, not folder name.
- Photos should be landscape, ~1600px wide minimum, no text overlays — `AreaCardView` lays text + a dark gradient on top.
- Re-add the `area-covers` group to the asset catalog when the first imageset is added (Xcode will recreate the parent `Contents.json`).

## Mapbox dark style

`BrandConfig.Mapbox.darkStyleID` (`AustrianRocks/Config/BrandConfig.swift:42`) currently aliases `styleID`, so dark mode shows the light map. Pick one of:

- **Fastest:** duplicate `mapbox/dark-v11` in the `dgtlntv` Studio account, add the `problems_8-85f5eq` source layer with the same paint as the light style's problem layer, publish, paste the new style ID into `darkStyleID`. This is what Boolder effectively did.
- **Programmatic recolor:** export the light style JSON via the Styles API, run a script that inverts/darkens paint properties by layer type while skipping `problems_*` layers, upload as a new style, then re-run the script when the light style changes to keep them in sync.
- **If the style is Mapbox Standard-based:** swap `lightPreset` between `day`/`night` at runtime via `setStyleImportConfigProperty` instead of maintaining two style IDs. Check Studio first to see if the light style exposes presets.

Reference (Boolder's dark style, on a different account so not directly usable): `mapbox://styles/nmondollot/cmkea670800a701sdc5n67k3q`. Code that consumes `darkStyleID` is already in place — `MapboxViewController` reloads the style on `traitCollectionDidChange`, so just updating the constant ships dark mode.