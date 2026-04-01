# iOS Migration Status Report

**Date:** December 12, 2025
**Project:** Boolder → Austrian.rocks iOS Migration

## Executive Summary

The iOS migration from Boolder to Austrian.rocks is **approximately 60% complete**. Core data models and infrastructure have been successfully migrated, but significant UI updates and feature implementation remain.

---

## ✅ COMPLETED ITEMS

### 1. Core Infrastructure ✓

-   [x] **BrandConfig.swift** created and fully configured (AustrianRocks/Config/BrandConfig.swift)
-   [x] **Database file** renamed to `austrian-rocks.db` (3.8MB)
-   [x] **SqliteStore.swift** updated to use `BrandConfig.Database.filename`
-   [x] **Info.plist** `CFBundleDisplayName` updated to "Austrian.rocks"
-   [x] **Dev-Info.plist** `CFBundleDisplayName` updated to "AustrianRocks dev"
-   [x] All references to `boolder.com` removed from codebase

### 2. Data Models ✓

-   [x] **Region.swift** - Fully implemented with all required properties and SQLite queries
-   [x] **Area.swift** - Updated with:
    -   `descriptionDe` and `warningDe` (replacing `descriptionFr` and `warningFr`)
    -   `clusterId` foreign key
    -   `localizedDescription` and `localizedWarning` computed properties
    -   `forBeginners` sorted by problem count (not circuits)
-   [x] **Problem.swift** - Updated with:
    -   `problemDescription` property added
    -   `videoLinks` property added
    -   All circuit-related properties removed (`circuitId`, `circuitColor`, `circuitNumber`)
    -   `zIndex` calculation simplified (no circuit bonus)
    -   `localizedName` uses "de" locale
-   [x] **Cluster.swift** - Enhanced with:
    -   `regionId` foreign key
    -   `slug` property
    -   `tags` array
    -   `published` boolean
    -   `region` computed property
-   [x] **Circuit.swift** - Successfully removed (doesn't exist in AustrianRocks)

### 3. Localization ✓

-   [x] **German localization** (de.lproj/) created with:
    -   `Localizable.strings` (8,650 bytes)
    -   `InfoPlist.strings` (476 bytes)
-   [x] **English localization** (en.lproj/) maintained
-   [x] **French localization** (fr.lproj/) removed
-   [x] **Extensions.swift** `NSLocale.websiteLocale` updated to return "de" (was "fr")

### 4. Mapbox Integration ✓

-   [x] **MapboxViewController.swift** updated to use:
    -   `BrandConfig.Mapbox.styleURL`
    -   `BrandConfig.Mapbox.problemsTilesetURL`
    -   `BrandConfig.Mapbox.problemsSourceLayer`
-   [x] **Map center** changed to Austria coordinates (47.7, 13.5)
-   [x] **Topo.swift** updated to use `BrandConfig.Domains.assets`

### 5. Code Structure ✓

-   [x] **Circuit-related Swift files** removed from codebase
-   [x] **AustrianRocks/** directory created with proper structure
-   [x] **Boolder/** directory marked for deletion (all files in git staging)

---

## ❌ NOT COMPLETED - CRITICAL ITEMS

### 1. Configuration & Authentication 🔴 BLOCKER

**File:** `AustrianRocks/Info.plist:30-31`

```xml
<key>MBXAccessToken</key>
<string></string>  <!-- ❌ EMPTY - NEEDS MAPBOX TOKEN -->
```

**Action Required:**

-   Obtain Mapbox access token from `dgtlntv` account
-   Update both `Info.plist` and `Dev-Info.plist`
-   **Priority:** CRITICAL - App won't display maps without this

**Reference:** Migration plan section 8.1, MIGRATION_SUMMARY.md line 499-500

---

### 2. Localization Cleanup 🔴 CRITICAL

#### Circuit References Still Present

**Files:**

-   `AustrianRocks/de.lproj/Localizable.strings`
-   `AustrianRocks/en.lproj/Localizable.strings`

**Circuit strings that should be removed:**

```
❌ "map.circuit_start"
❌ "filters.circuit"
❌ "area.circuit.beginner"
❌ "area.circuit.dangerous"
❌ "circuit.long_name.yellow" (and 11 other circuit color names)
❌ "circuit.short_name.yellow" (and 11 other circuit color names)
```

**Total:** ~30 circuit-related strings in each language file

**Action Required:**

1. Remove all circuit-related strings from both localization files
2. Ensure no UI code references these removed keys

**Reference:** Migration plan section 3, MIGRATION_SUMMARY.md section 1.3

---

### 3. Region UI Implementation 🔴 CRITICAL

#### Missing Views

The three-tier navigation hierarchy (Region → Cluster → Area) requires new UI components:

**Files to CREATE:**

1. ❌ `AustrianRocks/UI/Discover/RegionsListView.swift`

    - Browse all published regions
    - Show region name, cluster count, popular badge
    - Navigate to RegionDetailView

2. ❌ `AustrianRocks/UI/Discover/RegionDetailView.swift`

    - Region hero image/cover photo
    - Region description
    - List of clusters in region
    - Map view centered on region bounds
    - Popular areas within region

3. ❌ `AustrianRocks/UI/Discover/RegionCardView.swift`
    - Reusable region card component
    - Similar to existing AreaCardView
    - Shows region preview in scrollable lists

**Reference:** Migration plan section 6.2, MIGRATION_SUMMARY.md section 2.2

---

### 4. DiscoverView Updates 🔴 CRITICAL

**File:** `AustrianRocks/UI/Discover/DiscoverView.swift`

**Current State (INCORRECT):**

```swift
@State private var popularAreas = [Area]()  // ❌ Should be popularRegions
@State private var areas = [Area]()         // ❌ Should be regions

// Lines 167-176: Shows Areas instead of Regions
ForEach(popularAreas) { area in
    NavigationLink {
        AreaView(area: area, linkToMap: true)  // ❌ Should go to RegionDetailView
    } label: {
        AreaCardView(area: area, ...)          // ❌ Should use RegionCardView
    }
}
```

**Required Changes:**

1. Replace `popularAreas` with `popularRegions: [Region]`
2. Update "discover.popular" section to show regions (not areas)
3. Navigation should go: Region → Cluster → Area (not directly to Area)
4. Remove or repurpose "discover.top_areas.train" (Fontainebleau-specific)
5. Update "discover.all_areas" to "discover.all_regions"

**Reference:** Migration plan section 6.3, MIGRATION_SUMMARY.md section 7.1

---

### 5. Problem Details UI Updates 🟡 HIGH PRIORITY

**File:** `AustrianRocks/UI/Map/Problem details/ProblemDetailsView.swift`

**Missing UI for New Features:**

The Problem model has `problemDescription` and `videoLinks` fields, but the UI doesn't display them.

**Required Changes:**

```swift
// ❌ NOT IMPLEMENTED - Add after line 199:
if let description = problem.problemDescription {
    Text(description)
        .font(.body)
        .padding()
}

// ❌ NOT IMPLEMENTED - Add video links section:
if let videoLinks = problem.videoLinks, !videoLinks.isEmpty {
    VStack(alignment: .leading) {
        Text("Videos")
            .font(.headline)
        ForEach(videoLinks, id: \.self) { link in
            Link(destination: URL(string: link)!) {
                HStack {
                    Image(systemName: "play.circle")
                    Text("Watch video")
                }
            }
        }
    }
    .padding()
}
```

**Reference:** Migration plan section 9.4, MIGRATION_SUMMARY.md section 6.1

---

### 6. Filters Model Updates 🟡 HIGH PRIORITY

**File:** `AustrianRocks/Models/Filters.swift`

**Action Required:**

-   Remove `circuitId` property from Filters struct
-   Update FiltersView to remove circuit picker UI
-   Ensure circuit filter is not displayed anywhere

**Reference:** Migration plan section 9.5, MIGRATION_SUMMARY.md section 12.1

---

### 7. Asset Updates 🟡 HIGH PRIORITY

#### App Icons

**Location:** `AustrianRocks/Assets.xcassets/AppIcon.appiconset/`

**Current State:**

```
❌ Icon-App-60x60@2x - copie.png
❌ Icon-App-60x60@3x - copie.png
❌ Icon-App-76x76@1x - copie.png
❌ Icon-App-76x76@2x - copie.png
❌ Icon-App-83.5x83.5@2x - copie.png
❌ Icon-App-iTunes - copie.png
```

**Issues:**

-   Files named "- copie.png" suggest they're placeholders or copies
-   Likely still showing Boolder branding
-   Need proper Austrian.rocks branded icons

**Action Required:**

1. Design new Austrian.rocks app icons
2. Replace all icon files
3. Update both `AppIcon.appiconset/` and `AppIconDev.appiconset/`
4. Remove " - copie" suffix from filenames

**Reference:** Migration plan section 10.1

#### Brand Color

**Location:** `AustrianRocks/Assets.xcassets/AppGreen.colorset/`

**Current State:**

```
❌ Still named "AppGreen" (Boolder brand color)
```

**Action Required:**

1. Rename color asset from "AppGreen" to "AppBrandColor"
2. Update all code references:
    - Search: `Color("AppGreen")` or `.appGreen`
    - Replace with: `Color("AppBrandColor")` or `.appBrandColor`
3. Update color value to Austrian.rocks brand color

**Reference:** Migration plan section 10.3

#### Area Cover Images

**Location:** `AustrianRocks/Assets.xcassets/area-covers/`

**Current State:**

-   Still contains Fontainebleau area cover images
-   Need Austrian boulder area photos

**Action Required:**

-   Replace with Austrian area cover photos
-   Ensure image IDs match area IDs from database
-   Naming: `area-cover-{area_id}.jpg`

**Reference:** Migration plan section 10.2

---

### 8. UI View Updates 🟡 HIGH PRIORITY

#### AreaView Updates

**File:** `AustrianRocks/UI/Map/AreaView.swift`

**Required Changes:**

1. Add breadcrumb navigation showing: Region > Cluster > Area
2. Remove any remaining circuit display elements
3. Update description display to use `localizedDescription`

#### TopAreasTrain.swift

**File:** `AustrianRocks/UI/Discover/TopAreasTrain.swift`

**Issue:** Train access is Fontainebleau-specific (not applicable to Austria)

**Options:**

1. Remove entirely (recommended)
2. Repurpose for "Car access time" or other Austrian-relevant metric

**Reference:** Migration plan section 9.2.4

#### MapContainerView.swift

**File:** `AustrianRocks/UI/Map/MapContainerView.swift:138`

**Action Required:**

```swift
// TODO: remove after October 2024
```

-   Check if this TODO is still relevant (it's now December 2025)
-   Remove outdated migration code if applicable

---

### 9. Xcode Project Configuration 🟡 MEDIUM PRIORITY

#### Bundle Identifier

**Current:** Likely `com.boolder.app` or similar

**Action Required:**

-   Update to new identifier (e.g., `com.austrianrocks.app` or `rocks.austrian.app`)
-   Update in:
    -   Xcode project settings
    -   Info.plist
    -   Dev-Info.plist
    -   Provisioning profiles

**Reference:** Migration plan section 12.3

#### App Store ID

**File:** `AustrianRocks/Config/BrandConfig.swift:25`

```swift
static let appID = "TBD" // ❌ Needs actual App Store ID when published
```

**Action Required:**

-   Create new App Store listing (or update if modifying existing app)
-   Update `appID` when available

**Reference:** Migration plan section 12.1

---

### 10. Database & Content Updates 🟡 MEDIUM PRIORITY

#### Region Data Population

**Status:** Region model exists, but unclear if database has region data

**Action Required:**

1. Verify `austrian-rocks.db` contains:
    - `regions` table with Austrian regions
    - `clusters` table with `region_id` foreign keys
    - `areas` table with `cluster_id` foreign keys
2. Ensure published regions exist for testing
3. Test region loading and hierarchy navigation

**Reference:** MIGRATION_SUMMARY.md section 3.4
