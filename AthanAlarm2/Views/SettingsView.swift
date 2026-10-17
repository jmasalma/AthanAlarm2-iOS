import SwiftUI
#if canImport(AthanCore)
import AthanCore
#endif

public struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var audioService = AudioService.shared
    @ObservedObject var locationManager = LocationManager.shared

    @State private var showingCustomCityAlert: Bool = false
    @State private var customCityName: String = ""
    @State private var customCountry: String = ""
    @State private var customLat: String = ""
    @State private var customLon: String = ""

    public var body: some View {
        NavigationView {
            Form {
                // Location Section
                Section(header: Text("Location")) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(settings.selectedCity.name)
                                .font(.headline)
                            Text("\(settings.selectedCity.country) • Lat: \(String(format: "%.2f", settings.selectedCity.latitude)), Lon: \(String(format: "%.2f", settings.selectedCity.longitude))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Toggle("Use Device GPS Location", isOn: $settings.useGPSLocation)
                        .onChange(of: settings.useGPSLocation) { newValue in
                            if newValue {
                                locationManager.requestPermission()
                                locationManager.startUpdatingLocation()
                                if let loc = locationManager.userLocation {
                                    settings.selectedCity = City(
                                        name: "Current GPS Location",
                                        country: "Device Coordinates",
                                        latitude: loc.coordinate.latitude,
                                        longitude: loc.coordinate.longitude,
                                        timezone: Double(TimeZone.current.secondsFromGMT()) / 3600.0,
                                        timeZoneId: TimeZone.current.identifier
                                    )
                                }
                            }
                        }
                }

                // Calculation Method Section
                Section(header: Text("Calculation Method")) {
                    Picker("Method", selection: $settings.calculationMethod) {
                        ForEach(CalculationMethod.allCases) { method in
                            Text(method.title).tag(method)
                        }
                    }

                    Picker("Juristic (Asr)", selection: $settings.juristicMethod) {
                        ForEach(JuristicMethod.allCases, id: \.self) { juristic in
                            Text(juristic.title).tag(juristic)
                        }
                    }

                    Picker("High Latitude Rule", selection: $settings.highLatitudeRule) {
                        ForEach(HighLatitudeRule.allCases, id: \.self) { rule in
                            Text(rule.title).tag(rule)
                        }
                    }

                    Stepper("Dhuhr Precaution: +\(settings.dhuhrPrecautionMin) min", value: $settings.dhuhrPrecautionMin, in: 0...15)
                }

                // Minute Adjustments
                Section(header: Text("Minute Adjustments (Offsets)"), footer: Text("Add or subtract minutes for each prayer time.")) {
                    ForEach([PrayerType.fajr, .sunrise, .dhuhr, .asr, .maghrib, .isha], id: \.self) { prayer in
                        let currentOffset = settings.prayerOffsets[prayer] ?? 0
                        Stepper("\(prayer.englishName): \(currentOffset >= 0 ? "+\(currentOffset)" : "\(currentOffset)") min") {
                            settings.prayerOffsets[prayer] = currentOffset + 1
                        } onDecrement: {
                            settings.prayerOffsets[prayer] = currentOffset - 1
                        }
                    }
                }

                // General Preferences
                Section(header: Text("Display & Sound")) {
                    Toggle("24-Hour Time Format", isOn: $settings.use24HourTime)

                    Button(action: {
                        if audioService.isPlaying {
                            audioService.stop()
                        } else {
                            audioService.previewAthan()
                        }
                    }) {
                        HStack {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(Color(hex: "0E3A2F"))
                            Text("Test Full Athan Sound")
                            Spacer()
                            if audioService.isPlaying {
                                Text("Playing...").font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }

                    Button(action: {
                        audioService.previewChime()
                    }) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.orange)
                            Text("Test Gentle Chime")
                        }
                    }
                }

                // About
                Section(header: Text("About")) {
                    HStack {
                        Text("Application")
                        Spacer()
                        Text("AthanAlarm2 iOS").foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Calculation Engine")
                        Spacer()
                        Text("Jean Meeus Astronomical").foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0").foregroundColor(.secondary)
                    }

                    HStack {
                        Text("GitHub")
                        Spacer()
                        Link("jmasalma/AthanAlarm2-iOS", destination: URL(string: "https://github.com/jmasalma/AthanAlarm2-iOS")!)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
