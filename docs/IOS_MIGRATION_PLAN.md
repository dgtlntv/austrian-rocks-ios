# iOS Migration Plan: Boolder → Austrian.rocks

## Overview

This document provides a comprehensive migration plan for transitioning the iOS
app from Boolder (Fontainebleau) to Austrian.rocks. This migration involves
significant architectural changes, complete removal of features (circuits),
addition of new features (regions), and extensive rebranding.

**Original App:** Boolder (Fontainebleau bouldering guide) **Target App:**
Austrian.rocks (Austrian bouldering guide)

## 2. Configuration & Branding

### 2.1 Create Brand Configuration System

**Priority:** CRITICAL - Do this FIRST before any other changes

Create a centralized configuration file similar to Rails `config/brand.rb`:

**File to create:** `Boolder/Config/BrandConfig.swift`

This configuration should include:

```swift
struct BrandConfig {
    static let name = "Austrian.rocks"
    static let slug = "austrian-rocks"

    struct Domains {
        static let main = "austrian.rocks"
        static let www = "www.austrian.rocks"
        static let assets = "assets.austrian.rocks"
    }

    struct Contact {
        static let email = "hello@austrian.rocks"
    }

    struct AppStore {
        static let appID = "TBD" // New App Store ID
    }

    struct Mapbox {
        static let account = "dgtlntv"
        static let styleID = "cmi0wnif6004t01r0araj0ts0"
        static let problemsTilesetID = "74oi43iu"
        static let problemsSourceLayer = "problems-8pdvh4"
    }

    struct Database {
        static let filename = "austrian-rocks"
    }
}
```

**Benefits:**

-   Single source of truth for all brand references
-   Easy to update URLs and identifiers
-   Prevents hardcoded values throughout codebase
-   Makes future rebranding trivial

### 2.2 Update Info.plist

**File:** `Boolder/Info.plist`

Changes needed:

```xml
<!-- BEFORE -->
<key>CFBundleDisplayName</key>
<string>Boolder</string>

<!-- AFTER -->
<key>CFBundleDisplayName</key>
<string>Austrian.rocks</string>
```

Also update:

-   [ ] `CFBundleIdentifier` → `com.austrian.rocks` (or your preferred
        identifier)
-   [ ] `MBXAccessToken` → Add Mapbox token for `dgtlntv` account
-   [ ] Update camera/location usage descriptions if they mention Fontainebleau

### 2.3 Replace Hard-coded URLs

**Current hard-coded URLs to replace:**

| File                       | Line         | Current URL                  | Replacement                  |
| -------------------------- | ------------ | ---------------------------- | ---------------------------- |
| `Topo.swift`               | 34           | `https://assets.boolder.com` | `BrandConfig.Domains.assets` |
| `ProblemDetailsView.swift` | 286          | `https://www.boolder.com`    | `BrandConfig.Domains.www`    |
| `ContributeView.swift`     | 85, 89       | `https://www.boolder.com`    | `BrandConfig.Domains.www`    |
| `DiscoverView.swift`       | 54, 326, 328 | `https://www.boolder.com`    | `BrandConfig.Domains.www`    |

**Search pattern to find all:**

```bash
grep -r "boolder\.com\|boolder\.rocks" --include="*.swift"
```

### 2.4 Update App Scheme Names

**Files to update:**

-   `Boolder.xcodeproj/xcshareddata/xcschemes/Boolder.xcscheme`
-   `Boolder.xcodeproj/xcshareddata/xcschemes/Boolder dev.xcscheme`

Consider renaming to:

-   `AustrianRocks.xcscheme`
-   `AustrianRocks dev.xcscheme`

---

## 3. Localization Changes

### 3.1 Remove French Localization

**Priority:** HIGH

**Files to delete:**

-   [ ] `Boolder/fr.lproj/Localizable.strings` (204 lines)
-   [ ] `Boolder/fr.lproj/InfoPlist.strings`
-   [ ] Remove `fr.lproj` directory entirely

**Code changes:**

1. **Update locale logic in `Extensions.swift`**

    **File:** `Boolder/UI/Misc/Extensions.swift:59-69`

    ```swift
    // BEFORE
    extension NSLocale {
        static var websiteLocale: String {
            if let lang = NSLocale.current.language.languageCode?.identifier {
                if (lang == "en") {
                    return "en"
                }
            }
            return "fr"  // ← DEFAULT TO FRENCH
        }
    }

    // AFTER
    extension NSLocale {
        static var websiteLocale: String {
            if let lang = NSLocale.current.language.languageCode?.identifier {
                if (lang == "en") {
                    return "en"
                }
            }
            return "de"  // ← DEFAULT TO GERMAN
        }
    }
    ```

2. **Update Problem.swift localizedName**

    **File:** `Boolder/Models/Problem.swift:44-51`

    ```swift
    // BEFORE
    var localizedName: String {
        if NSLocale.websiteLocale == "fr" {
            return name ?? ""
        } else {
            return nameEn ?? ""
        }
    }

    // AFTER
    var localizedName: String {
        if NSLocale.websiteLocale == "de" {
            return name ?? ""
        } else {
            return nameEn ?? ""
        }
    }
    ```

### 3.2 Add German Localization

**Priority:** CRITICAL

**Directory to create:** `Boolder/de.lproj/`

**Files to create:**

1. [ ] `Boolder/de.lproj/Localizable.strings`
2. [ ] `Boolder/de.lproj/InfoPlist.strings`

**Source for translations:** Use the German translations from the Rails
migration summary (lines 72-82 in `MIGRATION_SUMMARY.md`).

**Key translations:**

| English                     | German                 | Notes                                         |
| --------------------------- | ---------------------- | --------------------------------------------- |
| Problems                    | Routen                 | Conceptual change from "problems" to "routes" |
| Popular areas               | Beliebte Regionen      | Now "regions" not "areas"                     |
| Beginner friendly           | Anfängerfreundlich     |                                               |
| Family friendly             | Familienfreundlich     |                                               |
| Dries fast                  | Trocknet schnell       |                                               |
| Bouldering in Fontainebleau | Bouldern in Österreich | Homepage title                                |

**Complete German localization file structure:**

Create `de.lproj/Localizable.strings` with ~200 key-value pairs. Reference the
English file for structure, but translate using German from migration summary.

**Important:** Remove ALL circuit-related strings from German localization (they
won't exist in Austrian.rocks).

### 3.3 Update Xcode Project Localizations

1. [ ] Open Xcode → Project Settings → Info → Localizations
2. [ ] Remove French localization
3. [ ] Add German localization
4. [ ] Set default language to German (de) with English (en) as fallback

---

## 4. Data Model Changes

### 4.1 Area Model Changes

**File:** `Boolder/Models/Area.swift`

**Current properties to change:**

```swift
// REMOVE these properties:
let descriptionFr: String?      // Line 20
let warningFr: String?          // Line 22

// ADD these properties:
let descriptionDe: String?      // German description
let warningDe: String?          // German warning
```

**SQLite Expression updates:**

```swift
// In extension Area (lines 105-129)

// REMOVE:
static let descriptionFr = Expression<String?>("description_fr")
static let warningFr = Expression<String?>("warning_fr")

// ADD:
static let descriptionDe = Expression<String?>("description_de")
static let warningDe = Expression<String?>("warning_de")
```

**Update Area.load() method:**

```swift
// In static func load(id: Int) -> Area? (line 131)

return Area(
    id: id,
    name: a[name],
    nameSearchable: a[nameSearchable],
    priority: a[priority],
    descriptionDe: a[descriptionDe],  // ← Changed
    descriptionEn: a[descriptionEn],
    warningDe: a[warningDe],          // ← Changed
    warningEn: a[warningEn],
    // ... rest of properties
)
```

**Computed properties for localized access:**

```swift
// ADD to Area struct:
var localizedDescription: String? {
    if NSLocale.websiteLocale == "de" {
        return descriptionDe
    }
    return descriptionEn
}

var localizedWarning: String? {
    if NSLocale.websiteLocale == "de" {
        return warningDe
    }
    return warningEn
}
```

### 4.2 Problem Model Changes

**File:** `Boolder/Models/Problem.swift`

**Properties to REMOVE:**

```swift
// Lines 25-27
let circuitId: Int?
let circuitColor: Circuit.CircuitColor?
let circuitNumber: String

// Line 28
let bleauInfoId: String?
```

**Properties to ADD:**

```swift
let description: String?        // Problem description
let videoLinks: [String]?       // Array of video URLs
```

**Methods to REMOVE:**

All circuit-related methods:

-   [ ] `circuitUIColor` (line 36)
-   [ ] `circuitUIColorForPhotoOverlay` (line 40)
-   [ ] `circuitNumberComparableValue` (line 53)
-   [ ] `next` (line 282) - navigates to next problem in circuit
-   [ ] `previous` (line 299) - navigates to previous problem in circuit
-   [ ] `zIndex` calculation that includes circuit bonus (line 90)

**SQLite Expression updates:**

```swift
// REMOVE:
static let circuitNumber = Expression<String?>("circuit_number")
static let circuitColor = Expression<String?>("circuit_color")
static let circuitId = Expression<Int?>("circuit_id")
static let bleauInfoId = Expression<String?>("bleau_info_id")

// ADD:
static let description = Expression<String?>("description")
static let videoLinks = Expression<String?>("video_links")  // May need custom serialization
```

**Update Problem.load() method:**

```swift
return Problem(
    id: id,
    name: p[name],
    nameEn: p[nameEn],
    nameSearchable: p[nameSearchable],
    grade: Grade(p[grade]),
    coordinate: CLLocationCoordinate2D(latitude: p[latitude], longitude: p[longitude]),
    steepness: Steepness(rawValue: p[steepness]) ?? .other,
    sitStart: p[sitStart] == 1,
    areaId: p[areaId],
    description: p[description],        // ← NEW
    videoLinks: p[videoLinks],          // ← NEW (handle JSON array)
    featured: p[featured] == 1,
    popularity: p[popularity],
    parentId: p[parentId]
)
```

**Update zIndex calculation:**

```swift
// BEFORE (line 90-94)
var zIndex: Double {
    let bonusCircuit = circuitId != nil ? 1000.0 : 0.0
    let tiebreaker = Double(id) / 100
    return Double(popularity ?? 0) + bonusCircuit + tiebreaker
}

// AFTER
var zIndex: Double {
    let tiebreaker = Double(id) / 100
    return Double(popularity ?? 0) + tiebreaker
}
```

### 4.3 Cluster Model Enhancements

**File:** `Boolder/Models/Cluster.swift`

**Properties to ADD:**

```swift
let regionId: Int?              // Foreign key to Region
let slug: String                // URL-friendly identifier
let tags: [String]              // Array of tags
let published: Bool             // Publication status
```

**SQLite Expression updates:**

```swift
static let regionId = Expression<Int?>("region_id")
static let slug = Expression<String>("slug")
static let tags = Expression<String?>("tags")  // Comma-separated
static let published = Expression<Bool>("published")
```

**Computed properties:**

```swift
var region: Region? {
    guard let regionId = regionId else { return nil }
    return Region.load(id: regionId)
}

var popular: Bool {
    tags.contains("popular")
}
```

---

## 5. Circuit Removal

### 5.1 Delete Circuit Model

**Priority:** CRITICAL

**File to DELETE:**

-   [ ] `Boolder/Models/Circuit.swift` (239 lines) - Complete removal

This file contains:

-   `Circuit` struct with 11 `CircuitColor` enum cases
-   Color mappings for UI
-   Localized circuit names (short/long)
-   SQLite loading logic
-   Problems-in-circuit queries

### 5.2 Delete Circuit UI Components

**Files to DELETE:**

1. [ ] `Boolder/UI/Map/CircuitPickerView.swift` - Circuit selection UI
2. [ ] `Boolder/UI/Map/CircuitView.swift` - Circuit display view

**Impact:** These views allow users to:

-   Browse circuits in an area
-   Filter problems by circuit color
-   Navigate circuit problems in order
-   See circuit metadata (grade, beginner-friendly status)

### 5.3 Remove Circuit References from Area

**File:** `Boolder/Models/Area.swift`

**Code to REMOVE:**

```swift
// Line 42-47 - Remove beginner area sorting by circuits
static var forBeginners : [Area] {
    all
        .filter{$0.beginnerFriendly}
        .sorted {
            $0.circuits.filter{$0.beginnerFriendly}.count > $1.circuits.filter{$0.beginnerFriendly}.count
        }
}

// Replace with simple problem count sorting:
static var forBeginners : [Area] {
    all
        .filter{$0.beginnerFriendly}
        .sorted { $0.problemsCount > $1.problemsCount }
}

// Line 208-227 - Remove circuits property entirely
var circuits: [Circuit] {
    // ... 20 lines of circuit query logic
}
```

### 5.4 Update UI Views

**Files requiring circuit removal:**

1. **AreaView.swift**

    - [ ] Remove circuit list/grid display
    - [ ] Remove circuit filtering options
    - [ ] Update toolbar to remove circuit picker button

2. **FiltersView.swift**

    - [ ] Remove "Circuit" filter option (currently line ~27)
    - [ ] Update filter state management

3. **AreaProblemsView.swift**

    - [ ] Remove circuit-based problem grouping
    - [ ] Remove circuit color indicators
    - [ ] Update problem sorting (no longer by circuit number)

4. **ProblemDetailsView.swift**

    - [ ] Remove circuit color display
    - [ ] Remove circuit number badge
    - [ ] Remove "next/previous in circuit" navigation buttons
    - [ ] Remove circuit name in problem header

5. **MapboxView.swift / MapboxViewController.swift**
    - [ ] Remove circuit layer rendering
    - [ ] Remove circuit color-based problem styling
    - [ ] Update problem marker colors (uniform gray #878A8D)

### 5.5 Search and Replace Tasks

Run these searches to find all circuit references:

```bash
# Find all circuit references
grep -r "circuit" --include="*.swift" -i

# Find Circuit.CircuitColor usage
grep -r "CircuitColor" --include="*.swift"

# Find circuit filter usage
grep -r "\.circuit" --include="*.swift"
```

**Common patterns to remove:**

-   `problem.circuitId`
-   `problem.circuitColor`
-   `problem.circuitNumber`
-   `area.circuits`
-   `Circuit.load()`
-   Circuit-related @State variables
-   Circuit filtering logic

### 5.6 Database Query Updates

**Areas table queries:**

-   Remove circuit JOIN queries
-   Update problem counts (no longer need "problems per circuit")

**Problems table queries:**

-   Remove `circuit_id` filters
-   Remove circuit-based sorting
-   Update grouping logic

---

## 6. Region Implementation

### 6.1 Create Region Model

**Priority:** HIGH

**File to CREATE:** `Boolder/Models/Region.swift`

**Model structure:**

```swift
//
//  Region.swift
//  Austrian.rocks
//
//  Copyright © 2024 Austrian.rocks. All rights reserved.
//

import UIKit
import SQLite
import CoreLocation

struct Region: Identifiable, Hashable {
    let id: Int
    let name: String
    let slug: String
    let mainClusterId: Int?
    let centerLat: Double
    let centerLon: Double
    let southWestLat: Double
    let southWestLon: Double
    let northEastLat: Double
    let northEastLon: Double
    let tags: [String]
    let published: Bool

    var popular: Bool {
        tags.contains("popular")
    }

    var center: CLLocation {
        CLLocation(latitude: centerLat, longitude: centerLon)
    }

    var mainCluster: Cluster? {
        guard let mainClusterId = mainClusterId else { return nil }
        return Cluster.load(id: mainClusterId)
    }
}

// MARK: SQLite
extension Region {
    static let id = Expression<Int>("id")
    static let name = Expression<String>("name")
    static let slug = Expression<String>("slug")
    static let mainClusterId = Expression<Int?>("main_cluster_id")
    static let centerLat = Expression<Double>("center_lat")
    static let centerLon = Expression<Double>("center_lon")
    static let southWestLat = Expression<Double>("south_west_lat")
    static let southWestLon = Expression<Double>("south_west_lon")
    static let northEastLat = Expression<Double>("north_east_lat")
    static let northEastLon = Expression<Double>("north_east_lon")
    static let tags = Expression<String?>("tags")
    static let published = Expression<Bool>("published")

    static func load(id: Int) -> Region? {
        let query = Table("regions").filter(self.id == id)

        do {
            if let r = try SqliteStore.shared.db.pluck(query) {
                let allowedTags = ["popular"]
                let tags = r[tags]?.components(separatedBy: ",").filter{allowedTags.contains($0)}

                return Region(
                    id: id,
                    name: r[name],
                    slug: r[slug],
                    mainClusterId: r[mainClusterId],
                    centerLat: r[centerLat],
                    centerLon: r[centerLon],
                    southWestLat: r[southWestLat],
                    southWestLon: r[southWestLon],
                    northEastLat: r[northEastLat],
                    northEastLon: r[northEastLon],
                    tags: tags ?? [],
                    published: r[published]
                )
            }

            return nil
        } catch {
            print(error)
            return nil
        }
    }

    static var all: [Region] {
        let query = Table("regions")
            .filter(published == true)
            .order(name.asc)

        do {
            return try SqliteStore.shared.db.prepare(query).map { region in
                Region.load(id: region[id])
            }.compactMap{$0}
        } catch {
            print(error)
            return []
        }
    }

    var clusters: [Cluster] {
        let clusters = Table("clusters")
            .filter(Cluster.regionId == id)
            .filter(Cluster.published == true)
            .order(Cluster.name.asc)

        do {
            return try SqliteStore.shared.db.prepare(clusters).map { cluster in
                Cluster.load(id: cluster[Cluster.id])
            }.compactMap{$0}
        } catch {
            print(error)
            return []
        }
    }
}
```

### 6.2 Create Region UI Views

**Files to CREATE:**

1. **RegionsListView.swift** - Browse all regions

    ```swift
    // List view showing all published regions
    // - Region name
    // - Number of clusters
    // - Popular badge if tagged
    // - Navigation to RegionDetailView
    ```

2. **RegionDetailView.swift** - Region details

    ```swift
    // Shows region information:
    // - Hero image/cover photo
    // - Region description
    // - List of clusters in region
    // - Map view centered on region bounds
    // - Popular areas within region
    ```

3. **RegionCardView.swift** - Reusable region card component
    ```swift
    // Similar to existing AreaCardView
    // Shows region preview in scrollable lists
    ```

### 6.3 Update Navigation Hierarchy

**Current hierarchy:**

```
Discover → Areas → Problems
Map → Areas → Problems
```

**New hierarchy:**

```
Discover → Regions → Clusters → Areas → Problems
Map → Regions → Clusters → Areas → Problems
```

**Update DiscoverView.swift:**

```swift
// BEFORE (line 151-185)
// Shows "Popular Areas"

// AFTER
// Show "Popular Regions" (Beliebte Regionen)
@State private var popularRegions = [Region]()

VStack(alignment: .leading) {
    Text("discover.popular")  // Update translation to "Beliebte Regionen"
        .font(.title2).bold()
        .padding(.top, 16)
        .padding(.bottom, 8)
        .padding(.horizontal)

    ScrollView(.horizontal, showsIndicators: false) {
        HStack(alignment: .top, spacing: 0) {
            ForEach(popularRegions) { region in
                NavigationLink {
                    RegionDetailView(region: region)
                } label: {
                    RegionCardView(region: region, width: cardWidth, height: cardHeight)
                        .padding(.leading, 8)
                }
            }
        }
    }
}

// In .task modifier:
popularRegions = Region.all.filter{$0.popular}
```

---

## 7. Database Migration

### 7.1 Database File Changes

**File:** `Boolder/Stores/SqliteStore.swift`

**Current code (line 18):**

```swift
let databaseURL = Bundle.main.url(forResource: "boolder", withExtension: "db")!
```

**Updated code:**

```swift
let databaseURL = Bundle.main.url(forResource: BrandConfig.Database.filename, withExtension: "db")!
```

Or directly:

```swift
let databaseURL = Bundle.main.url(forResource: "austrian-rocks", withExtension: "db")!
```

### 7.2 Database Schema Expectations

The SQLite database exported from Rails will have these changes:

**New Tables:**

-   [ ] `regions` - New table with all region data

**Modified Tables:**

**areas:**

```sql
-- REMOVED columns:
-- bleau_area_id
-- description_fr
-- warning_fr

-- ADDED columns:
-- description_de TEXT
-- warning_de TEXT
-- cluster_id INTEGER (some rows may have NULL)
```

**problems:**

```sql
-- REMOVED columns:
-- circuit_id
-- circuit_number
-- circuit_letter
-- bleau_info_id

-- ADDED columns:
-- description TEXT
-- video_links TEXT (JSON array as string)
```

**clusters:**

```sql
-- ADDED columns:
-- region_id INTEGER
-- slug TEXT
-- tags TEXT (comma-separated)
-- published BOOLEAN
```

**boulders:**

```sql
-- ADDED columns:
-- name TEXT (optional boulder name)
```

**Deleted Tables:**

-   [ ] `circuits` - Completely removed
-   [ ] `bleau_areas` - Removed (Bleau.info integration)
-   [ ] `bleau_problems` - Removed (Bleau.info integration)

### 7.3 Database Download/Sync

**Current process:**

1. App bundles `boolder.db` for offline use
2. Downloads area-specific topos on demand
3. Stores in app's Documents directory

**Updates needed:**

1. **Update bundled database:**

    - [ ] Replace `boolder.db` with new `austrian-rocks.db` from Rails export
    - [ ] Update Xcode project to include new database file
    - [ ] Remove old `boolder.db` from bundle

2. **Update download paths:**

    - [ ] Asset URLs: `assets.boolder.com` → `assets.austrian.rocks`
    - [ ] Topo image paths remain same structure:
          `/topos/area-{id}/topo-{id}.jpg`

3. **DownloadCenter updates:**

    **File:** `Boolder/Stores/Download/DownloadCenter.swift`

    Update asset base URL to use `BrandConfig.Domains.assets`

---

## 8. Mapbox Integration

### 8.1 Update Mapbox Configuration

**File:** `Info.plist`

**Current (line 30-31):**

```xml
<key>MBXAccessToken</key>
<string></string>  <!-- Currently empty -->
```

**Update:**

```xml
<key>MBXAccessToken</key>
<string>[GET TOKEN FROM dgtlntv MAPBOX ACCOUNT]</string>
```

**Action required:** Obtain Mapbox access token from `dgtlntv` account.

### 8.2 Update Map Style and Tilesets

**Files to update:**

-   `Boolder/UI/Map/MapboxView.swift`
-   `Boolder/UI/Map/MapboxViewController.swift`

**Style URL update:**

```swift
// BEFORE
let styleURL = URL(string: "mapbox://styles/nmondollot/cl95n147u003k15qry7pvfmq2")

// AFTER
let styleURL = URL(string: "mapbox://styles/\(BrandConfig.Mapbox.account)/\(BrandConfig.Mapbox.styleID)")
```

**Tileset updates:**

```swift
// Problems tileset
// BEFORE
source.url = "mapbox://nmondollot.4xsv235p"
layer.sourceLayer = "problems-ayes3a"

// AFTER
source.url = "mapbox://\(BrandConfig.Mapbox.account).\(BrandConfig.Mapbox.problemsTilesetID)"
layer.sourceLayer = BrandConfig.Mapbox.problemsSourceLayer
```

**Quick reference:** | Resource | Boolder | Austrian.rocks |
|----------|---------|----------------| | Account | `nmondollot` | `dgtlntv` | |
Style ID | `cl95n147u003k15qry7pvfmq2` | `cmi0wnif6004t01r0araj0ts0` | |
Problems Tileset | `4xsv235p` | `74oi43iu` | | Source Layer | `problems-ayes3a`
| `problems-8pdvh4` |

### 8.3 Update Map Bounds

**Default map view center:**

```swift
// BEFORE - Fontainebleau, France
let bounds = [
    [2.4806787, 48.2868427],      // Southwest
    [2.7698927, 48.473906]         // Northeast
]

// AFTER - Austria
let bounds = [
    [9.430320338084726, 46.28576190178245],      // Southwest
    [17.230613306834925, 49.18126637161225]      // Northeast
]
```

### 8.4 Remove Circuit Map Layers

**In MapboxViewController:**

Remove all code related to:

-   [ ] Circuit color rendering
-   [ ] Circuit number text layers
-   [ ] Circuit boundary polygons
-   [ ] Circuit-based problem coloring

**Update problem styling:**

```swift
// BEFORE - Circuit-based colors
let circuitColor = problem.circuitColor?.uicolor ?? .gray

// AFTER - Uniform color
let problemColor = UIColor(red: 135/255, green: 138/255, blue: 141/255, alpha: 1.0)  // #878A8D
```

### 8.5 Add Region Map Layers

**New layer to add:**

```swift
// Add region boundary layer
// Similar to existing area/cluster layers
// Shows region outlines on map
// Clickable to navigate to region detail
```

---

## 9. UI Updates

### 9.1 Update DiscoverView

**File:** `Boolder/UI/Discover/DiscoverView.swift`

**Changes:**

1. **Update beginner's guide URL (line 54):**

    ```swift
    // BEFORE
    SafariWebView(url: URL(string: "https://www.boolder.com/\(NSLocale.websiteLocale)/articles/beginners-guide")!)

    // AFTER
    SafariWebView(url: URL(string: "https://\(BrandConfig.Domains.www)/\(NSLocale.websiteLocale)/articles/beginners-guide")!)
    ```

2. **Remove "Train + bike" section (lines 109-130)**

    - This is Fontainebleau-specific (train access to forest)
    - Not applicable to Austrian boulder areas
    - Complete removal of this quick filter

3. **Update "Popular" section (lines 151-185):**

    - Change from `popularAreas` to `popularRegions`
    - Update card view to `RegionCardView`
    - Update navigation to `RegionDetailView`

4. **Update "All areas" section (lines 187-233):**

    - Rename to "All regions" (Alle Regionen)
    - Show regions instead of areas
    - Navigation: Region → Cluster → Area hierarchy

5. **Update contribute URLs (lines 325-329):**

    ```swift
    var contributeURL: URL {
        if NSLocale.websiteLocale == "en" {
            return URL(string: "https://\(BrandConfig.Domains.www)/en/contribute")!
        }
        return URL(string: "https://\(BrandConfig.Domains.www)/de/contribute")!  // Changed from /fr/
    }
    ```

6. **Update App Store ID (line 246):**

    ```swift
    // BEFORE
    let appID = "1506614493"  // Boolder App Store ID

    // AFTER
    let appID = BrandConfig.AppStore.appID  // New Austrian.rocks ID
    ```

### 9.2 Update TopAreasView Files

**Files to update:**

1. **TopAreasBeginnerView.swift**

    - [ ] Update title: "Débutant" → "Anfängerfreundlich"
    - [ ] Remove circuit-based beginner filtering
    - [ ] Sort by problem count instead

2. **TopAreasDryFast.swift**

    - [ ] Update translations
    - [ ] Keep functionality (still relevant for Austria)

3. **TopAreasLevelView.swift**

    - [ ] Update grade descriptions (remove Fontainebleau-specific grading info)
    - [ ] Update warning text (line 122 in French file mentions "Fontainebleau")

4. **TopAreasTrain.swift**
    - [ ] **Consider removing entirely** - Train access is
          Fontainebleau-specific
    - [ ] Alternative: Repurpose for "Car access time" or remove

### 9.3 Update AreaView

**File:** `Boolder/UI/Map/AreaView.swift`

**Changes:**

1. **Remove circuit display sections:**

    - [ ] Circuit grid/list view
    - [ ] Circuit picker button
    - [ ] "Beginner-friendly circuit" badge
    - [ ] "Dangerous circuit" warning

2. **Add cluster context:**

    ```swift
    // Add breadcrumb navigation
    // Region > Cluster > Area
    HStack {
        if let cluster = area.cluster, let region = cluster.region {
            Text(region.name)
            Image(systemName: "chevron.right")
            Text(cluster.name)
            Image(systemName: "chevron.right")
        }
        Text(area.name)
    }
    .font(.caption)
    .foregroundColor(.secondary)
    ```

3. **Update description display:**
    ```swift
    // Use localizedDescription instead of descriptionFr/descriptionEn
    if let description = area.localizedDescription {
        Text(description)
    }
    ```

### 9.4 Update ProblemDetailsView

**File:** `Boolder/UI/Map/Problem details/ProblemDetailsView.swift`

**Changes:**

1. **Remove circuit UI elements:**

    - [ ] Circuit color indicator badge
    - [ ] Circuit number badge (e.g., "Yellow 12")
    - [ ] "Next in circuit" / "Previous in circuit" buttons
    - [ ] Circuit name in header

2. **Add new fields:**

    ```swift
    // Add problem description if available
    if let description = problem.description {
        Text(description)
            .font(.body)
            .padding()
    }

    // Add video links if available
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

3. **Update share URL (line 286):**

    ```swift
    // BEFORE
    URL(string: "https://www.boolder.com/\(NSLocale.websiteLocale)/p/\(String(problem.id))")!

    // AFTER
    URL(string: "https://\(BrandConfig.Domains.www)/\(NSLocale.websiteLocale)/p/\(String(problem.id))")!
    ```

4. **Update variant display:**
    - Remove circuit color indicators from variants
    - Update problem circle view to not use circuit colors

### 9.5 Update FiltersView

**File:** `Boolder/UI/Map/FiltersView.swift`

**Changes:**

1. **Remove circuit filter:**

    - [ ] Remove "Circuit" picker/selector
    - [ ] Remove circuit color filter options
    - [ ] Update Filters model to remove circuitId property

2. **Update filter state management:**
    ```swift
    // In Filters model
    struct Filters {
        var gradeRange: GradeRange
        var popular: Bool
        var favorite: Bool
        var ticked: Bool
        // REMOVED: var circuitId: Int?
    }
    ```

### 9.6 Update ContributeView

**File:** `Boolder/UI/ContributeView.swift`

**Changes:**

1. **Update URLs (lines 85, 89):**

    ```swift
    // Contribute URL
    URL(string: "https://\(BrandConfig.Domains.www)/\(NSLocale.websiteLocale)/contribute?dismiss_banner=true")!

    // About URL
    URL(string: "https://\(BrandConfig.Domains.www)/\(NSLocale.websiteLocale)/about")!
    ```

2. **Update title:**

    ```swift
    // BEFORE
    "contribute.title" = "Contribute to Boolder"

    // AFTER
    "contribute.title" = "Contribute to Austrian.rocks"
    ```

### 9.7 Update TopoView

**File:** `Boolder/UI/Map/Problem details/Topo/TopoView.swift`

**Changes:**

1. **Remove circuit color overlays:**

    - Problem lines should no longer be colored by circuit
    - Use uniform color or grade-based colors

2. **Update asset URLs in Topo.swift (line 34):**

    ```swift
    // BEFORE
    URL(string: "https://assets.boolder.com/proxy/topos/\(id)")!

    // AFTER
    URL(string: "https://\(BrandConfig.Domains.assets)/proxy/topos/\(id)")!
    ```

### 9.8 Update AreaProblemsView

**File:** `Boolder/UI/Map/AreaProblemsView.swift`

**Changes:**

1. **Remove circuit grouping:**

    - Problems should no longer be grouped by circuit
    - Consider grouping by: grade, steepness, or area section

2. **Remove circuit color indicators:**

    - Update problem list items to remove circuit color dots/badges

3. **Update sorting:**
    - Remove circuit number sorting
    - Default to: grade (high to low), then popularity

---

## 10. Asset Updates

### 10.1 App Icons

**Location:** `Boolder/Assets.xcassets/AppIcon.appiconset/`

**Files to replace:**

-   [ ] All icon sizes (60x60@2x, 60x60@3x, 76x76, 83.5x83.5, 1024x1024)
-   [ ] Development icon set: `AppIconDev.appiconset/`

**Design requirements:**

-   New brand identity for Austrian.rocks
-   Should NOT use Boolder's green branding
-   Should reflect Austrian mountain/boulder aesthetic
-   All required iOS sizes (see Contents.json for specs)

### 10.2 Area Cover Images

**Location:** `Boolder/Assets.xcassets/area-covers/`

**Current:** 48 Fontainebleau-specific area cover images

**Action:**

-   [ ] Replace with Austrian boulder area photos
-   [ ] Ensure image IDs match area IDs from database
-   [ ] Naming convention: `area-cover-{area_id}.jpg`
-   [ ] Recommended size: 800x450px (16:9 aspect ratio)

### 10.3 Color Assets

**Location:** `Boolder/Assets.xcassets/AppGreen.colorset/`

**Current:** "AppGreen" color (Boolder brand color)

**Action:**

-   [ ] Update brand color to Austrian.rocks brand color
-   [ ] Update color name from "AppGreen" to "AppBrandColor"
-   [ ] Update all references in code from `Color("AppGreen")` to
        `Color("AppBrandColor")`

### 10.4 Launch Screen

**Location:** `Info.plist` → UILaunchScreen

**Current (line 55-59):**

```xml
<key>UILaunchScreen</key>
<dict>
    <key>UIColorName</key>
    <string>white</string>
</dict>
```

**Consider:**

-   Add Austrian.rocks logo to launch screen
-   Update background color to match new branding
-   Create LaunchScreen.storyboard if needed

---

## 11. Testing Checklist

### 11.1 Data Layer Testing

-   [ ] Database loads successfully (`austrian-rocks.db`)
-   [ ] Region model loads all regions
-   [ ] Cluster model includes regionId and new fields
-   [ ] Area model uses German descriptions (`description_de`, `warning_de`)
-   [ ] Problem model has description and videoLinks fields
-   [ ] No crashes when accessing removed circuit properties
-   [ ] No crashes when accessing removed French properties
-   [ ] Topo images download from new asset server

### 11.2 Localization Testing

-   [ ] German localization files load correctly
-   [ ] English localization files load correctly
-   [ ] No French strings appear anywhere in app
-   [ ] Default locale is German (de)
-   [ ] All UI strings have translations
-   [ ] No missing localization keys (check console logs)
-   [ ] `NSLocale.websiteLocale` returns "de" or "en" (never "fr")

### 11.3 UI Testing

**Navigation:**

-   [ ] Discover tab shows regions (not areas)
-   [ ] Tapping region navigates to RegionDetailView
-   [ ] Tapping cluster navigates to cluster view
-   [ ] Tapping area navigates to AreaView
-   [ ] Tapping problem navigates to ProblemDetailsView
-   [ ] Back navigation works through entire hierarchy

**Map:**

-   [ ] Map centers on Austria (not Fontainebleau)
-   [ ] Region boundaries display correctly
-   [ ] Cluster boundaries display correctly
-   [ ] Area boundaries display correctly
-   [ ] Problems display with correct markers
-   [ ] Problem markers are uniform color (#878A8D), not circuit colors
-   [ ] Tapping problem opens ProblemDetailsView
-   [ ] No circuit layers visible

**Filters:**

-   [ ] Grade range filter works
-   [ ] Popular filter works
-   [ ] Favorites filter works
-   [ ] Ticked filter works
-   [ ] No circuit filter option exists
-   [ ] Filters persist correctly

**Problem Details:**

-   [ ] Problem info displays correctly (name, grade, steepness)
-   [ ] No circuit color badge
-   [ ] No circuit number badge
-   [ ] No "next/previous in circuit" buttons
-   [ ] Topo image loads from `assets.austrian.rocks`
-   [ ] Problem description shows if available
-   [ ] Video links show if available
-   [ ] Share button generates correct Austrian.rocks URL
-   [ ] Favorite/tick functionality works

**Areas:**

-   [ ] Area description shows (German or English)
-   [ ] Area warnings show (German or English)
-   [ ] No circuit list/grid
-   [ ] Popular problems show correctly
-   [ ] Problem count is accurate
-   [ ] Levels chart displays

**Download:**

-   [ ] Cluster download works
-   [ ] Area download works
-   [ ] Topo images download correctly
-   [ ] Download progress shows
-   [ ] Downloaded content persists offline
-   [ ] Delete download works

### 11.4 URL Testing

Test all external URLs open correctly:

-   [ ] Beginner's guide:
        `https://www.austrian.rocks/{locale}/articles/beginners-guide`
-   [ ] Contribute page: `https://www.austrian.rocks/{locale}/contribute`
-   [ ] About page: `https://www.austrian.rocks/{locale}/about`
-   [ ] Problem share: `https://www.austrian.rocks/{locale}/p/{id}`
-   [ ] Topo images: `https://assets.austrian.rocks/proxy/topos/{id}`

### 11.5 Mapbox Testing

-   [ ] Map tiles load from new Mapbox style
-   [ ] Problems tileset loads correctly
-   [ ] Source layer name is correct (`problems-8pdvh4`)
-   [ ] No missing tiles or rendering errors
-   [ ] Map performance is acceptable
-   [ ] Attribution displays Mapbox logo

### 11.6 Upgrade Testing

**Critical:** Test upgrade from Boolder to Austrian.rocks

-   [ ] Install Boolder from App Store
-   [ ] Add some favorites and ticks
-   [ ] Install Austrian.rocks build over it
-   [ ] App launches without crash
-   [ ] Old database is handled gracefully
-   [ ] User is notified about data reset (if applicable)
-   [ ] User can download new Austrian data

### 11.7 Edge Cases

-   [ ] App works with no Internet connection (offline mode)
-   [ ] App handles missing topo images gracefully
-   [ ] App handles areas with no problems
-   [ ] App handles problems without topos
-   [ ] App handles regions with no clusters
-   [ ] Empty search results display correctly
-   [ ] Very long area/problem names don't break layout

---

## 12. App Store Preparation

### 12.1 New App Store Listing

**Decision required:** Will this be:

-   **Option A:** A completely new app (new App Store listing)
-   **Option B:** An update to existing Boolder app

**Recommendation:** New app (Option A) because:

-   Different geographic region (Austria vs France)
-   Different branding
-   Different target audience
-   Allows Boolder to remain available for Fontainebleau users

### 12.2 App Metadata

If creating new app:

**App Name:**

-   Primary: "Austrian.rocks"
-   Subtitle: "Bouldering in Austria" / "Bouldern in Österreich"

**Keywords:**

-   bouldering, klettern, Austria, Österreich, topo, outdoor, climbing

**Categories:**

-   Primary: Sports
-   Secondary: Travel

**Description:** To write in both English and German. Key points:

-   Comprehensive guide to Austrian bouldering
-   Offline maps and topos
-   Grade-based filtering
-   Tick list and favorites
-   Free and open-source

**Screenshots:**

-   [ ] Create new screenshots showing:
    -   Region browsing
    -   Cluster selection
    -   Area details
    -   Problem details with Austrian locations
    -   Map view of Austria
    -   Filters in action
-   [ ] Both iPhone and iPad sizes
-   [ ] In English and German

**App Preview Video:**

-   [ ] Consider creating short preview video
-   [ ] Show app navigation and key features
-   [ ] Feature Austrian locations

### 12.3 Bundle Identifier

**Current:** Likely `com.boolder.app` or similar

**New:** Choose new identifier, e.g.:

-   `com.austrianrocks.app`
-   `rocks.austrian.app`
-   `com.austrianrocks.ios`

**Update in:**

-   [ ] Xcode project settings → Bundle Identifier
-   [ ] Provisioning profiles
-   [ ] App Store Connect

### 12.4 Version Numbering

**Recommendation:**

-   Start at version 1.0.0 (if new app)
-   Or continue from Boolder version (if update)

**Update:**

-   [ ] `CFBundleShortVersionString` in Info.plist (Marketing version)
-   [ ] `CFBundleVersion` in Info.plist (Build number)

### 12.5 Certificates & Provisioning

-   [ ] Create new App ID in Apple Developer account
-   [ ] Create distribution certificate
-   [ ] Create App Store provisioning profile
-   [ ] Update Xcode project to use new provisioning

### 12.6 TestFlight

Before public release:

-   [ ] Upload beta build to TestFlight
-   [ ] Invite internal testers
-   [ ] Test on multiple devices (iPhone, iPad)
-   [ ] Test on different iOS versions
-   [ ] Collect feedback
-   [ ] Fix critical bugs
-   [ ] Upload final build

### 12.7 App Privacy

**App Store requires privacy details:**

**Data Collected:**

-   Location (When In Use) - For map display
-   Crash Data - For debugging (if using crash reporting)

**Data Not Linked to User:**

-   All data is local (favorites, ticks stored on-device only)
-   No user accounts
-   No analytics (unless you add them)

**Privacy Policy:**

-   [ ] Create privacy policy page on austrian.rocks website
-   [ ] Link from app (Settings or About screen)

### 12.8 Copyright & Legal

Update copyright notices:

```swift
// BEFORE
// Copyright © 2020 Nicolas Mondollot. All rights reserved.

// AFTER
// Copyright © 2024 Austrian.rocks. All rights reserved.
```

Search and replace in all files:

```bash
find . -name "*.swift" -exec sed -i '' 's/Nicolas Mondollot/Austrian.rocks/g' {} +
```

**Also update:**

-   [ ] About screen
-   [ ] Settings screen
-   [ ] Any legal/attribution text
