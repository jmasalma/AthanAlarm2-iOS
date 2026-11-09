import Foundation
import Combine
#if canImport(AthanCore)
import AthanCore
#endif

public class AppSettings: ObservableObject {
    public static let shared = AppSettings()

    @Published public var selectedCity: City {
        didSet { saveCity() }
    }

    @Published public var calculationMethod: CalculationMethod {
        didSet { UserDefaults.standard.set(calculationMethod.rawValue, forKey: "calc_method") }
    }

    @Published public var juristicMethod: JuristicMethod {
        didSet { UserDefaults.standard.set(juristicMethod.rawValue, forKey: "juristic_method") }
    }

    @Published public var highLatitudeRule: HighLatitudeRule {
        didSet { UserDefaults.standard.set(highLatitudeRule.rawValue, forKey: "high_lat_rule") }
    }

    @Published public var dhuhrPrecautionMin: Int {
        didSet { UserDefaults.standard.set(dhuhrPrecautionMin, forKey: "dhuhr_precaution") }
    }

    @Published public var use24HourTime: Bool {
        didSet { UserDefaults.standard.set(use24HourTime, forKey: "use_24_hour") }
    }

    @Published public var useGPSLocation: Bool {
        didSet { UserDefaults.standard.set(useGPSLocation, forKey: "use_gps") }
    }

    @Published public var prayerOffsets: [PrayerType: Int] {
        didSet { saveOffsets() }
    }

    @Published public var alarmModes: [PrayerType: AlarmMode] {
        didSet { saveAlarmModes() }
    }

    // New features matching Android AthanAlarm2
    @Published public var athanSound: String {
        didSet { UserDefaults.standard.set(athanSound, forKey: "athan_sound") }
    }

    @Published public var prePrayerReminderEnabled: Bool {
        didSet { UserDefaults.standard.set(prePrayerReminderEnabled, forKey: "pre_reminder_enabled") }
    }

    @Published public var prePrayerReminderMinutes: Int {
        didSet { UserDefaults.standard.set(prePrayerReminderMinutes, forKey: "pre_reminder_minutes") }
    }

    @Published public var prePrayerReminderSound: String {
        didSet { UserDefaults.standard.set(prePrayerReminderSound, forKey: "pre_reminder_sound") }
    }

    @Published public var hijriDayOffset: Int {
        didSet { UserDefaults.standard.set(hijriDayOffset, forKey: "hijri_day_offset") }
    }

    public static let predefinedCities: [City] = City.cities

    private init() {
        let defaults = UserDefaults.standard

        // Method
        if let methodRaw = defaults.string(forKey: "calc_method"),
           let method = CalculationMethod(rawValue: methodRaw) {
            self.calculationMethod = method
        } else {
            self.calculationMethod = .isna
        }

        // Juristic
        if let juristicRaw = defaults.string(forKey: "juristic_method"),
           let juristic = JuristicMethod(rawValue: juristicRaw) {
            self.juristicMethod = juristic
        } else {
            self.juristicMethod = .standard
        }

        // High Latitude
        if let highLatRaw = defaults.string(forKey: "high_lat_rule"),
           let rule = HighLatitudeRule(rawValue: highLatRaw) {
            self.highLatitudeRule = rule
        } else {
            self.highLatitudeRule = .middleOfNight
        }

        self.dhuhrPrecautionMin = defaults.object(forKey: "dhuhr_precaution") != nil ? defaults.integer(forKey: "dhuhr_precaution") : 1
        self.use24HourTime = defaults.bool(forKey: "use_24_hour")
        self.useGPSLocation = defaults.bool(forKey: "use_gps")

        // Load City
        if let cityData = defaults.data(forKey: "saved_city"),
           let decoded = try? JSONDecoder().decode(City.self, from: cityData) {
            self.selectedCity = decoded
        } else {
            self.selectedCity = City.default
        }

        // Load Offsets
        var loadedOffsets: [PrayerType: Int] = [:]
        for prayer in PrayerType.allCases {
            loadedOffsets[prayer] = defaults.integer(forKey: "offset_\(prayer.rawValue)")
        }
        self.prayerOffsets = loadedOffsets

        // Load Alarm Modes
        var loadedModes: [PrayerType: AlarmMode] = [:]
        for prayer in PrayerType.allCases {
            if let modeRaw = defaults.string(forKey: "alarm_\(prayer.rawValue)"),
               let mode = AlarmMode(rawValue: modeRaw) {
                loadedModes[prayer] = mode
            } else {
                loadedModes[prayer] = (prayer == .sunrise) ? .muted : .athan
            }
        }
        self.alarmModes = loadedModes

        // Android parity settings
        self.athanSound = defaults.string(forKey: "athan_sound") ?? "athan_general"
        self.prePrayerReminderEnabled = defaults.bool(forKey: "pre_reminder_enabled")
        self.prePrayerReminderMinutes = defaults.object(forKey: "pre_reminder_minutes") != nil ? defaults.integer(forKey: "pre_reminder_minutes") : 20
        self.prePrayerReminderSound = defaults.string(forKey: "pre_reminder_sound") ?? "chime"
        self.hijriDayOffset = defaults.integer(forKey: "hijri_day_offset")
    }

    public func cycleAlarmMode(for prayer: PrayerType) {
        let current = alarmModes[prayer] ?? .athan
        alarmModes[prayer] = current.next()
    }

    private func saveCity() {
        if let encoded = try? JSONEncoder().encode(selectedCity) {
            UserDefaults.standard.set(encoded, forKey: "saved_city")
        }
    }

    private func saveOffsets() {
        for (prayer, offset) in prayerOffsets {
            UserDefaults.standard.set(offset, forKey: "offset_\(prayer.rawValue)")
        }
    }

    private func saveAlarmModes() {
        for (prayer, mode) in alarmModes {
            UserDefaults.standard.set(mode.rawValue, forKey: "alarm_\(prayer.rawValue)")
        }
    }
}
