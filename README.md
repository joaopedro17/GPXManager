
# GPXManager

A SwiftUI app for iOS that lets you manage GPS coordinates and export GPX files for location simulation in Xcode. Built for QA engineers and developers who need to test location-based features on real devices.

---

## Requirements

- Xcode 16 or later
- iOS 18 deployment target
- A physical iPhone (location simulation does not work on the Simulator for all scenarios)

---

## Installation

1. Create a new Xcode project using the **App** template
2. Set the minimum deployment target to **iOS 18**
3. Delete the default `ContentView.swift` that Xcode generates
4. Drag all `.swift` files from this folder into the project navigator — tick **Copy items if needed**
5. In `Assets.xcassets`, replace the `AppIcon` slot with `GPXManager_AppIcon_1024.png`
6. Build and run on your device (`⌘R`)

> On first launch, iOS may ask you to trust the developer profile. Go to **Settings → General → VPN & Device Management** and trust your Apple ID.

---

## Features

- Add coordinates manually by name and lat/lng, or search by address using MapKit
- Organise coordinates into named groups
- Reorder coordinates within a group via drag handles (tap the Reorder button first)
- Move a coordinate to another group by dragging it onto the group header, or via the swipe action
- Rename a group inline by tapping the pencil icon in the section header
- Select individual coordinates or entire groups for export
- Export as **Waypoints** (static pins) or **Route** (animated path Xcode walks through)
- Import existing `.gpx` files — waypoints, tracks, and route points are all supported
- Coordinates persist locally between sessions

---

## How to add coordinates

**Manually:**
1. Tap **+** in the top-right corner
2. Enter a name, latitude, and longitude
3. Assign a group or create a new one

**By address search:**
1. Tap **+** and start typing in the search field
2. Select a result — the name, lat, and lng fill in automatically

**Tip:** In Google Maps, long-press any point on the map to reveal its coordinates. Copy them directly into the lat/lng fields.

---

## Exporting a GPX file

1. Tap the circle next to each coordinate you want to include (or use the **Select** button on a group header to select all in that group)
2. The list order is the export order — reorder before exporting if needed
3. At the bottom, choose **Waypoints** or **Route** from the picker
4. Tap **Export GPX (n)**
5. Save to **iCloud Drive** so it's accessible from your Mac without a cable

### Waypoints vs Route

| Mode | GPX element | Xcode behaviour |
|---|---|---|
| Waypoints | `<wpt>` | Static pins — Xcode jumps between them |
| Route | `<trk>` | Animated path — Xcode moves smoothly along the route |

For most UI testing scenarios **Route** is more realistic. Use **Waypoints** when you need to test specific named locations independently.

---

## Using the GPX file in Xcode

1. Drag the `.gpx` file into your Xcode project navigator — tick **Copy items if needed**
2. Go to **Product → Scheme → Edit Scheme** (`⌘<`)
3. Select **Run → Options → Core Location**
4. Set **Default Location** to your GPX file
5. Build and run (`⌘R`) — Xcode will simulate your device moving through the coordinates

> To swap routes without rebuilding, replace the `.gpx` file contents and restart the app. Xcode picks up the file change immediately.

---

## Distributing the app (without an App Store account)

### Run on your own device
Connect your iPhone and hit **Run** in Xcode. The build is valid for **7 days**, after which you need to re-run from Xcode.

### Share with teammates via AltStore
1. Install **AltServer** on your Mac from [altstore.io](https://altstore.io) — it sits in the menu bar
2. Install **AltStore** on each target iPhone via AltServer over USB
3. In Xcode: **Product → Archive → Distribute App → Direct Distribution → Export** to get a `.ipa` file
4. Send the `.ipa` to teammates — they open it with AltStore to install
5. AltServer re-signs the app every 7 days automatically over WiFi

---

## File format reference

Exported filenames follow this pattern:

```
waypoints_<timestamp>.gpx   ← Waypoints export
route_<timestamp>.gpx       ← Route export
```

Coordinate names with XML special characters (`<`, `>`, `&`, `"`, `'`) are automatically escaped in the output.

---

## Data storage

All coordinates are stored in `UserDefaults` on-device. There is no iCloud sync — if you delete the app, your coordinates are lost. Export a GPX backup before uninstalling.

---

## Project structure

| File | Purpose |
|---|---|
| `GPXManagerApp.swift` | App entry point, shows `SplashView` on launch |
| `SplashView.swift` | Animated splash screen |
| `ContentView.swift` | Main list view with groups, selection, export controls |
| `CoordinateStore.swift` | Data model, persistence, and all mutation logic |
| `CoordinateRow.swift` | Individual row component |
| `AddCoordinateView.swift` | Add coordinate form with MapKit address search |
| `EditCoordinateView.swift` | Edit an existing coordinate |
| `GPXGenerator.swift` | Builds the GPX XML from selected coordinates |
| `GPXImporter.swift` | Parses imported GPX files |
| `HelpView.swift` | In-app guide |
