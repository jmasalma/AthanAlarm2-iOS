# AthanAlarm2-iOS

Native iOS companion app for **[AthanAlarm2](https://github.com/jmasalma/AthanAlarm2)** built with **SwiftUI**, **WidgetKit**, and **CoreLocation**.

Provides 100% offline astronomical prayer time calculations, full Athan and chime notifications, interactive Qibla compass with real-time magnetic heading, monthly timetable calendars, and Home Screen widgets.

---

## Features

- **Astronomical Offline Calculation**: Full offline implementation of the Jean Meeus solar position algorithm (matching the Android `AthanAlarm2` engine) with no external network requests needed.
- **11 Calculation Methods**:
  - Islamic Society of North America (ISNA)
  - Muslim World League (MWL)
  - Egyptian General Authority of Survey
  - Umm Al-Qura University, Makkah
  - University of Islamic Sciences, Karachi
  - Institute of Geophysics, Tehran
  - Gulf Region / UAE
  - Kuwait
  - Qatar
  - Diyanet İşleri Başkanlığı (Turkey)
  - Union of Islamic Organisations of France
- **Juristic Asr Methods**: Standard (Shafi'i, Maliki, Hanbali - shadow factor 1.0) and Hanafi (shadow factor 2.0).
- **High Latitude Rules**: Middle of the Night, One-Seventh of the Night, Angle-Based, or None.
- **Real-Time Qibla Compass**:
  - Great-circle bearing and geodesic distance to the Holy Kaaba in Makkah (21.422487° N, 39.826206° E)
  - Live magnetic compass rose rotating with device heading
  - Golden Kaaba needle alignment indicator with haptic vibration when directly facing the Qibla (±3°)
- **Prayer Alarms & Notifications**:
  - Per-prayer mode toggles: **Full Athan**, **Gentle Chime**, **Notification Only**, or **Muted**
  - Foreground banner & sound presentation via `UserNotifications`
  - Audio preview synthesizer for Athan and Chime tones
- **Prayer Timetable Calendar**:
  - Monthly prayer schedule table with Fajr, Sunrise, Dhuhr, Asr, Maghrib, and Isha
  - Date navigation and Gregorian/Hijri date conversion (Umm Al-Qura calendar)
- **Home Screen & Lock Screen Widgets**:
  - Powered by **WidgetKit** with small and medium family layouts showing upcoming prayer and countdown minutes
- **Flexible Location Support**:
  - Auto GPS location with `CoreLocation`
  - Over 18 predefined global cities (Waterloo, Toronto, New York, London, Paris, Makkah, Madinah, Cairo, Istanbul, Dubai, etc.)
  - Custom coordinates, elevation, and timezone adjustment

---

## Project Structure

```
├── AthanAlarm2.xcodeproj/     # Pre-configured Xcode project & shared schemes
├── Sources/
│   └── AthanCore/            # Core Swift calculation engine
│       ├── PrayerCalculationEngine.swift  # Astronomical Meeus engine
│       ├── PrayerModels.swift             # Models, methods, cities, enums
│       └── QiblaCalculator.swift          # Spherical trigonometry bearing & distance
├── AthanAlarm2/              # SwiftUI Native iOS Application
│   ├── AthanAlarm2App.swift  # App entry point & notification delegate
│   ├── Info.plist            # App configuration & permissions
│   ├── Models/
│   │   └── AppSettings.swift # Persistent settings & user preferences
│   ├── ViewModels/
│   │   └── PrayerDashboardViewModel.swift # Reactive timer & prayer state
│   ├── Services/
│   │   ├── AudioService.swift         # Athan & chime audio playback
│   │   ├── HijriDateHelper.swift      # Islamic calendar formatting
│   │   ├── LocationManager.swift      # CoreLocation GPS & compass heading
│   │   └── NotificationService.swift  # Local alarm scheduling
│   ├── Views/
│   │   ├── ContentView.swift          # TabView navigation shell
│   │   ├── PrayerDashboardView.swift  # Main prayer schedule & countdown
│   │   ├── QiblaCompassView.swift     # Interactive Qibla compass
│   │   ├── MonthlyCalendarView.swift  # Monthly timetable view
│   │   ├── SettingsView.swift         # Calculation & location options
│   │   └── Components/
│   │       └── PrayerRowCard.swift    # Individual prayer row component
│   └── Assets.xcassets/      # AppIcon asset catalog (1024x1024 universal)
├── AthanAlarmWidgets/        # WidgetKit Extension
│   ├── PrayerWidget.swift    # Small & Medium Home Screen widgets
│   └── Info.plist            # Extension metadata
├── Tests/
│   └── AthanCoreTests/       # XCTest unit tests for prayer & Qibla math
├── Package.swift             # Swift Package Manager manifest
└── .github/workflows/
    └── ios.yml               # Automated CI/CD workflow to build & release AthanAlarm2.ipa
```

---

## Building and Running

### 1. Opening in Xcode (macOS)

1. Clone the repository:
   ```bash
   git clone https://github.com/jmasalma/AthanAlarm2-iOS.git
   cd AthanAlarm2-iOS
   ```
2. Open `AthanAlarm2.xcodeproj` in Xcode 15 or 16:
   ```bash
   open AthanAlarm2.xcodeproj
   ```
3. Select your connected iPhone, iPad, or an iOS Simulator and click **Run** (Cmd + R).

### 2. Automated Builds via GitHub Actions

The repository includes a GitHub Actions workflow (`.github/workflows/ios.yml`) that automatically builds and packages **`AthanAlarm2.ipa`** for sideloading.

To trigger a release:
1. Push a git tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
2. Or go to **Actions** > **iOS CI & Release** > **Run workflow** in GitHub.
3. Download the generated `AthanAlarm2.ipa` from the GitHub Release page.

### 3. Sideloading the IPA onto iOS Devices

Install the downloaded `AthanAlarm2.ipa` using any of:
- **AltStore / SideStore**: Open AltStore > My Apps > "+" > Select `AthanAlarm2.ipa`.
- **TrollStore**: Tap the IPA in Files > Open in TrollStore (no expiry, permanent signing).
- **Sideloadly**: Connect via USB/Wi-Fi on macOS or Windows and drag the IPA.

---

## License

MIT License. Designed as the native iOS companion to [AthanAlarm2](https://github.com/jmasalma/AthanAlarm2).
