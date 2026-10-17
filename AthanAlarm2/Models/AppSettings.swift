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

    public static let predefinedCities: [City] = [
        City(name: "Waterloo", country: "Canada", latitude: 43.4643, longitude: -80.5204, timezone: -5.0, elevation: 329.0, timeZoneId: "America/Toronto"),
        City(name: "Toronto", country: "Canada", latitude: 43.6532, longitude: -79.3832, timezone: -5.0, elevation: 76.0, timeZoneId: "America/Toronto"),
        City(name: "New York", country: "United States", latitude: 40.7128, longitude: -74.0060, timezone: -5.0, elevation: 10.0, timeZoneId: "America/New_York"),
        City(name: "Chicago", country: "United States", latitude: 41.8781, longitude: -87.6298, timezone: -6.0, elevation: 181.0, timeZoneId: "America/Chicago"),
        City(name: "Los Angeles", country: "United States", latitude: 34.0522, longitude: -118.2437, timezone: -8.0, elevation: 71.0, timeZoneId: "America/Los_Angeles"),
        City(name: "London", country: "United Kingdom", latitude: 51.5074, longitude: -0.1278, timezone: 0.0, elevation: 11.0, timeZoneId: "Europe/London"),
        City(name: "Paris", country: "France", latitude: 48.8566, longitude: 2.3522, timezone: 1.0, elevation: 35.0, timeZoneId: "Europe/Paris"),
        City(name: "Makkah", country: "Saudi Arabia", latitude: 21.4225, longitude: 39.8262, timezone: 3.0, elevation: 277.0, timeZoneId: "Asia/Riyadh"),
        City(name: "Madinah", country: "Saudi Arabia", latitude: 24.5247, longitude: 39.5692, timezone: 3.0, elevation: 608.0, timeZoneId: "Asia/Riyadh"),
        City(name: "Cairo", country: "Egypt", latitude: 30.0444, longitude: 31.2357, timezone: 2.0, elevation: 23.0, timeZoneId: "Africa/Cairo"),
        City(name: "Istanbul", country: "Turkey", latitude: 41.0082, longitude: 28.9784, timezone: 3.0, elevation: 40.0, timeZoneId: "Europe/Istanbul"),
        City(name: "Dubai", country: "United Arab Emirates", latitude: 25.2048, longitude: 55.2708, timezone: 4.0, elevation: 5.0, timeZoneId: "Asia/Dubai"),
        City(name: "Riyadh", country: "Saudi Arabia", latitude: 24.7136, longitude: 46.6753, timezone: 3.0, elevation: 612.0, timeZoneId: "Asia/Riyadh"),
        City(name: "Karachi", country: "Pakistan", latitude: 24.8607, longitude: 67.0011, timezone: 5.0, elevation: 8.0, timeZoneId: "Asia/Karachi"),
        City(name: "Kuala Lumpur", country: "Malaysia", latitude: 3.1390, longitude: 101.6869, timezone: 8.0, elevation: 22.0, timeZoneId: "Asia/Kuala_Lumpur"),
        City(name: "Jakarta", country: "Indonesia", latitude: -6.2088, longitude: 106.8456, timezone: 7.0, elevation: 8.0, timeZoneId: "Asia/Jakarta"),
        City(name: "Sydney", country: "Australia", latitude: -33.8688, longitude: 151.2093, timezone: 10.0, elevation: 19.0, timeZoneId: "Australia/Sydney"),
        City(name: "Tokyo", country: "Japan", latitude: 35.6762, longitude: 139.6503, timezone: 9.0, elevation: 40.0, timeZoneId: "Asia/Tokyo")
    ]

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
                loadedModes[prayer] = (prayer == .sunrise) ? .silent : .athan
            }
        }
        self.alarmModes = loadedModes
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
