# 🌴 nomadtrip

An offline-first, feature-packed travel companion app built with **Flutter**, designed specifically for a 20-day road trip across Florida (Miami, Orlando, Tampa, St. Augustine, and the Florida Keys).

Developed with production-level standards, clean architecture, and responsive UX for pre-trip preparation, on-the-road execution, and post-trip memories.

---

## 🚀 Key Features

### 🛫 Pre-Trip Planning
- **Interactive Day-by-Day Itinerary**: 20-day detailed breakdown with times, highlights, lodging, and transit notes.
- **Instant Search & Duplicate Prevention**: Fast search across all scheduled places with auto-detection to prevent accidental duplicate entries.
- **Media & Resource Bookmarks**: Attach Instagram Reels, TikTok tips, YouTube vlogs, and restaurant menus to any location.
- **Parking & Reservation Badges**: Clear badges indicating free vs. paid parking (with estimated costs in USD) and advance reservation requirements.

### 🚗 On-the-Road Assistant
- **"Today Mode" Dashboard**: Highlights the current day's schedule, lodging city, and next stop.
- **One-Tap Native Route Navigation**: Direct deep-linking to **Google Maps**, **Apple Maps**, or **Waze** with precise coordinates.
- **Proximity Radar & Interactive Map**:
  - OpenStreetMap-powered interactive map.
  - Distinct pins for visited vs. unvisited locations.
  - Proximity filter (*Near Me: < 5km, < 10km, or All*).
- **Visited Check-in**: Mark places as visited with a single tap.
- **Local Photo Finder**: Queries the device gallery for photos captured at the place's timestamp or coordinates.
- **Dynamic Reordering**: Move or postpone stops seamlessly if weather or fatigue changes the plan.

### 📸 Post-Trip Memories
- **Trip Timeline & Journal**: Converts the itinerary into a visual travel log with photos taken at each attraction.
- **Trip Analytics**: Statistics on total places visited, cities explored, and trip completion rate.

---

## 🛠️ Architecture & Tech Stack

- **Framework**: [Flutter 3.x](https://flutter.dev) (Dart 3 with strict null safety)
- **Architecture**: Clean Architecture + Feature-First (`features/itinerary`, `features/map`, `features/places`, `features/tips`)
- **State Management**: [Riverpod 2.x](https://riverpod.dev)
- **Local Database (Offline-First)**: SQLite via [Drift](https://drift.simonbinder.eu/) / `sqflite` with reactive streams
- **Maps**: [flutter_map](https://pub.dev/packages/flutter_map) (OpenStreetMap vector tiles) + [geolocator](https://pub.dev/packages/geolocator)
- **Navigation Deep-Linking**: [url_launcher](https://pub.dev/packages/url_launcher)
- **Gallery & Media**: [photo_manager](https://pub.dev/packages/photo_manager)

---

## 📁 Project Structure

```text
lib/
├── app.dart                       # App entry widget & theme setup
├── main.dart                      # Database & dependency initialization
├── core/
│   ├── database/                  # SQLite schema, migrations & seeders
│   ├── router/                    # go_router configuration with persistent tabs
│   ├── services/
│   │   ├── location_service.dart  # GPS coordinates & distance calculator
│   │   ├── navigation_launcher.dart # Deep link to Google Maps / Waze / Apple Maps
│   │   └── gallery_service.dart   # Photo matcher by date & geotag
│   └── theme/                     # Material 3 minimal theme
└── features/
    ├── itinerary/                 # Timeline cards, daily summaries, visited toggles
    ├── map/                       # Interactive map with radar & proximity chips
    ├── places/                    # CRUD, instant search, and duplicate checker
    └── tips/                      # Florida travel tips, toll passes, and reminders
```

---

## 🗺️ Itinerary Highlights (Nov 24 – Dec 13, 2026)

- **Miami & Boca Raton**: Arrival, Town Center Apple Store, coastal drive.
- **Orlando & Theme Parks**: Magic Kingdom, Mickey’s Very Merry Christmas Party, SeaWorld, Hollywood Studios, Universal Studios, Islands of Adventure, Epic Universe.
- **Events & Shopping**: Thanksgiving Dinner, Black Friday outlets (Orlando International Premium Outlets, The Florida Mall).
- **Day Trips**: Busch Gardens Tampa Bay + Celebration *Now Snowing*, historic Saint Augustine + Buc-ee's pitstop.
- **Disney Resorts Tour**: Disney Springs, Art of Animation Skyliner, Beaches & Cream (Kitchen Sink Sundae), BoardWalk, Fort Wilderness Campfire.
- **The Florida Keys**: Overseas Highway (US-1), Robert is Here, Key Largo, Seven Mile Bridge, Big Pine Key, Key West Mallory Square sunset, Duval Street, Southernmost Point Buoy.

---

## 📄 License

This project is licensed under the MIT License.
