import SwiftUI
#if canImport(AthanCore)
import AthanCore
#endif

public struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var audioService = AudioService.shared
    @ObservedObject var locationManager = LocationManager.shared

    @State private var easterEggTapCount: Int = 0
    @State private var lastEasterEggTapTimestamp: Double = 0
    @State private var showEasterEggDialog: Bool = false
    @State private var easterEggToastMessage: String? = nil

    @State private var showPrivacyDialog: Bool = false
    @State private var showBatteryGuideDialog: Bool = false

    private let preAlertOptions = [5, 10, 15, 20, 25, 30]
    private let hijriOffsetOptions = [-2, -1, 0, 1, 2]

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

                // Hijri Moon Sighting Adjustment
                Section(header: Text("Hijri Calendar Moon Adjustment"), footer: Text("Adjust Islamic calendar date by -2 to +2 days based on local moon sighting.")) {
                    Picker("Moon Offset", selection: $settings.hijriDayOffset) {
                        ForEach(hijriOffsetOptions, id: \.self) { offset in
                            Text(offset == 0 ? "Standard (0 days)" : String(format: "%+d days", offset)).tag(offset)
                        }
                    }
                }

                // Pre-Prayer Countdown Reminder (Matching Android)
                Section(header: Text("Pre-Prayer Alert Notifications"), footer: Text("Receive a countdown reminder notice prior to the start of each obligatory prayer.")) {
                    Toggle("Enable Pre-Prayer Reminder", isOn: $settings.prePrayerReminderEnabled)

                    if settings.prePrayerReminderEnabled {
                        Picker("Reminder Timing", selection: $settings.prePrayerReminderMinutes) {
                            ForEach(preAlertOptions, id: \.self) { min in
                                Text("\(min) minutes before\(min == 20 ? " (Default)" : "")").tag(min)
                            }
                        }

                        Picker("Reminder Sound", selection: $settings.prePrayerReminderSound) {
                            Text("Gentle Chime").tag("chime")
                            Text("System Sound").tag("system_notification")
                            Text("Silent Notification").tag("silent")
                        }
                    }
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

                // Sound & Playback
                Section(header: Text("Sound & Audio Preferences")) {
                    Picker("Default Athan Sound", selection: $settings.athanSound) {
                        Text("General Full Athan (Makkah)").tag("athan_general")
                        Text("Fajr Athan (with As-Salatu Khayrun Minan-Nawm)").tag("athan_fajr")
                        Text("Gentle Chime").tag("athan_chime")
                    }

                    Button(action: {
                        if audioService.isPlaying {
                            audioService.stop()
                        } else {
                            audioService.playSoundNamed(settings.athanSound)
                        }
                    }) {
                        HStack {
                            Image(systemName: audioService.isPlaying ? "stop.fill" : "speaker.wave.2.fill")
                                .foregroundColor(Color(hex: "0E3A2F"))
                            Text(audioService.isPlaying ? "Stop Audio Preview" : "Preview Selected Athan Audio")
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

                    Toggle("24-Hour Time Format", isOn: $settings.use24HourTime)
                }

                // Wireless Audio & Casting (AirPlay / HomePod / Bluetooth / Smart Speakers)
                Section(header: Text("Wireless Audio & Casting (AirPlay & Speakers)"), footer: Text("Broadcast Athan and notifications directly to Apple TV, HomePod, Bluetooth, or AirPlay-compatible smart speakers.")) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AirPlay & Wireless Speakers")
                                .font(.headline)
                            Text("Tap to route Athan audio to nearby speaker groups or HomePods")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        AirPlayButton()
                            .frame(width: 44, height: 44)
                    }
                    .padding(.vertical, 4)
                }

                // Guides & Privacy
                Section(header: Text("Support & Privacy")) {
                    Button(action: { showBatteryGuideDialog = true }) {
                        HStack {
                            Image(systemName: "battery.100.bolt")
                                .foregroundColor(Color(hex: "0E3A2F"))
                            Text("Background Notification & Battery Guide")
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
                        }
                    }

                    Button(action: { showPrivacyDialog = true }) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(Color(hex: "0E3A2F"))
                            Text("Privacy Policy (100% Offline)")
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
                        }
                    }
                }

                // About & Easter Egg row
                Section(header: Text("About")) {
                    Button(action: {
                        handleVersionTap()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Athan Alarm v1.0.0")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("100% Free & Open Source • No Ads • No Tracking")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if let toast = easterEggToastMessage {
                                Text(toast)
                                    .font(.caption2)
                                    .foregroundColor(Color(hex: "0E3A2F"))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(hex: "E6C280").opacity(0.3))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    HStack {
                        Text("Calculation Engine")
                        Spacer()
                        Text("Jean Meeus Astronomical + JITL").foregroundColor(.secondary)
                    }

                    HStack {
                        Text("GitHub Repository")
                        Spacer()
                        Link("jmasalma/AthanAlarm2-iOS", destination: URL(string: "https://github.com/jmasalma/AthanAlarm2-iOS")!)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showEasterEggDialog) {
                EasterEggView()
            }
            .sheet(isPresented: $showPrivacyDialog) {
                PrivacyPolicySheet()
            }
            .sheet(isPresented: $showBatteryGuideDialog) {
                BatteryGuideSheet()
            }
        }
    }

    private func handleVersionTap() {
        let now = Date().timeIntervalSince1970
        if now - lastEasterEggTapTimestamp > 2.5 {
            easterEggTapCount = 1
        } else {
            easterEggTapCount += 1
        }
        lastEasterEggTapTimestamp = now

        if easterEggTapCount >= 7 {
            easterEggTapCount = 0
            easterEggToastMessage = nil
            showEasterEggDialog = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else if easterEggTapCount >= 4 {
            let remaining = 7 - easterEggTapCount
            easterEggToastMessage = "\(remaining) taps to surprise!"
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

public struct EasterEggView: View {
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image("lr_easter_egg")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.65))
                            .clipShape(Circle())
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }
}

public struct PrivacyPolicySheet: View {
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("100% On-Device & Offline Privacy")
                        .font(.headline)
                        .foregroundColor(Color(hex: "0E3A2F"))

                    Text("Athan Alarm is engineered as a zero-data-collection, offline-first application. We do not require registration, we do not operate tracking servers, and we never collect, store, or sell your personal information.")
                        .font(.body)
                        .foregroundColor(.secondary)

                    Divider()

                    Text("Location & Permissions")
                        .font(.headline)
                        .foregroundColor(Color(hex: "0E3A2F"))

                    Text("• Location: Used exclusively on-device to calculate astronomical prayer times and Qibla direction. Your coordinates never leave your device.\n• Notifications: Used strictly to sound timely Athan and pre-prayer alerts.\n• No Third-Party Trackers or Ads: No analytics tracking SDKs or ad networks are included.")
                        .font(.body)
                        .foregroundColor(.secondary)

                    Divider()

                    Link("Open Full Privacy Policy Webpage", destination: URL(string: "https://masalma.com/AthanAlarmPrivacy.html")!)
                        .font(.headline)
                        .foregroundColor(Color(hex: "0E3A2F"))
                }
                .padding()
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

public struct BatteryGuideSheet: View {
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Reliable iOS Athan Notifications")
                        .font(.headline)
                        .foregroundColor(Color(hex: "0E3A2F"))

                    Text("To ensure full Athan calls play reliably at the exact second prayer time arrives on iOS:")
                        .font(.body)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "bell.badge.fill").foregroundColor(Color(hex: "0E3A2F"))
                            Text("1. Keep Notifications Enabled under Settings > AthanAlarm2.")
                        }
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "speaker.wave.3.fill").foregroundColor(Color(hex: "0E3A2F"))
                            Text("2. Enable Sound and Banners for Time-Sensitive alerts.")
                        }
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "moon.fill").foregroundColor(Color(hex: "0E3A2F"))
                            Text("3. Add AthanAlarm2 to Focus Mode / Do Not Disturb allowed apps if you wish to hear Fajr.")
                        }
                    }
                    .font(.subheadline)
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Notification Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
