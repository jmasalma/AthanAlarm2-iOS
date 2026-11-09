import Foundation

public enum PrayerType: String, CaseIterable, Codable, Identifiable {
    case fajr = "FAJR"
    case sunrise = "SUNRISE"
    case dhuhr = "DHUHR"
    case asr = "ASR"
    case maghrib = "MAGHRIB"
    case isha = "ISHA"
    case nextFajr = "NEXT_FAJR"

    public var id: String { rawValue }

    public var englishName: String {
        switch self {
        case .fajr: return "Fajr"
        case .sunrise: return "Sunrise"
        case .dhuhr: return "Dhuhr"
        case .asr: return "Asr"
        case .maghrib: return "Maghrib"
        case .isha: return "Isha"
        case .nextFajr: return "Next Fajr"
        }
    }

    public var arabicName: String {
        switch self {
        case .fajr: return "الفجر"
        case .sunrise: return "الشروق"
        case .dhuhr: return "الظهر"
        case .asr: return "العصر"
        case .maghrib: return "المغرب"
        case .isha: return "العشاء"
        case .nextFajr: return "الفجر القادم"
        }
    }

    public var isSalat: BooleanLiteralType {
        return self != .sunrise
    }
}

public enum AlarmMode: String, CaseIterable, Codable {
    case athan = "ATHAN"
    case chime = "CHIME"
    case silent = "SILENT"
    case muted = "MUTED"

    public var title: String {
        switch self {
        case .athan: return "Full Athan"
        case .chime: return "Gentle Chime"
        case .silent: return "Notification Only"
        case .muted: return "Disabled"
        }
    }

    public func next() -> AlarmMode {
        switch self {
        case .athan: return .chime
        case .chime: return .silent
        case .silent: return .muted
        case .muted: return .athan
        }
    }
}

public enum CalculationMethod: String, CaseIterable, Codable, Identifiable {
    case mwl = "MWL"
    case isna = "ISNA"
    case egypt = "EGYPT"
    case makkah = "MAKKAH"
    case karachi = "KARACHI"
    case tehran = "TEHRAN"
    case gulf = "GULF"
    case kuwait = "KUWAIT"
    case qatar = "QATAR"
    case diyanet = "DIYANET"
    case france = "FRANCE"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .mwl: return "Muslim World League"
        case .isna: return "Islamic Society of North America (ISNA)"
        case .egypt: return "Egyptian General Authority of Survey"
        case .makkah: return "Umm Al-Qura University, Makkah"
        case .karachi: return "Univ. of Islamic Sciences, Karachi"
        case .tehran: return "Institute of Geophysics, Tehran"
        case .gulf: return "Gulf Region / UAE"
        case .kuwait: return "Kuwait"
        case .qatar: return "Qatar"
        case .diyanet: return "Diyanet İşleri Başkanlığı (Turkey)"
        case .france: return "Union of Islamic Organisations of France"
        }
    }

    public var fajrAngle: Double {
        switch self {
        case .mwl, .karachi, .kuwait, .qatar, .diyanet: return 18.0
        case .isna: return 15.0
        case .egypt, .gulf: return 19.5
        case .makkah: return 18.5
        case .tehran: return 17.7
        case .france: return 12.0
        }
    }

    public var ishaAngle: Double {
        switch self {
        case .mwl, .diyanet: return 17.0
        case .isna: return 15.0
        case .egypt, .kuwait: return 17.5
        case .makkah, .gulf, .qatar: return 0.0 // Uses interval
        case .karachi: return 18.0
        case .tehran: return 14.0
        case .france: return 12.0
        }
    }

    public var ishaIntervalMin: Int {
        switch self {
        case .makkah, .gulf, .qatar: return 90
        default: return 0
        }
    }

    public var maghribAngle: Double {
        switch self {
        case .tehran: return 4.5
        default: return 0.0
        }
    }
}

public enum JuristicMethod: String, CaseIterable, Codable {
    case standard = "STANDARD"
    case hanafi = "HANAFI"

    public var title: String {
        switch self {
        case .standard: return "Standard (Shafi'i, Maliki, Hanbali)"
        case .hanafi: return "Hanafi"
        }
    }

    public var shadowFactor: Double {
        return self == .hanafi ? 2.0 : 1.0
    }
}

public enum HighLatitudeRule: String, CaseIterable, Codable {
    case none = "NONE"
    case middleOfNight = "MIDDLE_OF_NIGHT"
    case oneSeventh = "ONE_SEVENTH"
    case angleBased = "ANGLE_BASED"

    public var title: String {
        switch self {
        case .none: return "None"
        case .middleOfNight: return "Middle of the Night"
        case .oneSeventh: return "One-Seventh of the Night"
        case .angleBased: return "Angle-Based"
        }
    }
}

public struct City: Codable, Identifiable, Equatable {
    public var id: String { "\(name)_\(country)" }
    public let name: String
    public let country: String
    public let latitude: Double
    public let longitude: Double
    public let timezone: Double
    public let elevation: Double
    public let timeZoneId: String

    public init(name: String, country: String, latitude: Double, longitude: Double, timezone: Double, elevation: Double = 0.0, timeZoneId: String = "America/Toronto") {
        self.name = name
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
        self.timezone = timezone
        self.elevation = elevation
        self.timeZoneId = timeZoneId
    }

    public func isAlberta() -> Bool {
        return name.caseInsensitiveCompare("Calgary") == .orderedSame ||
               name.caseInsensitiveCompare("Edmonton") == .orderedSame ||
               country.localizedCaseInsensitiveContains("Alberta") ||
               (latitude >= 48.99 && latitude <= 60.01 && longitude >= -120.01 && longitude <= -109.99)
    }

    public func isAlbertaPermanentTimeActive(date: Date = Date()) -> Bool {
        let cal = Calendar(identifier: .gregorian)
        let year = cal.component(.year, from: date)
        let month = cal.component(.month, from: date)
        let day = cal.component(.day, from: date)
        return year > 2026 || (year == 2026 && (month > 11 || (month == 11 && day >= 1)))
    }

    public func getEffectiveTimezone(date: Date = Date()) -> Double {
        if isAlberta() && isAlbertaPermanentTimeActive(date: date) {
            return -6.0
        }
        if !timeZoneId.isEmpty, let tz = TimeZone(identifier: timeZoneId) {
            return Double(tz.secondsFromGMT(for: date)) / 3600.0
        }
        if let matched = City.cities.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }),
           !matched.timeZoneId.isEmpty, let tz = TimeZone(identifier: matched.timeZoneId) {
            return Double(tz.secondsFromGMT(for: date)) / 3600.0
        }
        return timezone
    }

    public static let `default` = City(
        name: "Waterloo",
        country: "Ontario, Canada",
        latitude: 43.4643,
        longitude: -80.5204,
        timezone: -5.0,
        elevation: 329.0,
        timeZoneId: "America/Toronto"
    )

    public static let cities: [City] = [
        // Canada (Waterloo & Regional Cities first)
        City(name: "Waterloo", country: "Ontario, Canada", latitude: 43.4643, longitude: -80.5204, timezone: -5.0, elevation: 329.0, timeZoneId: "America/Toronto"),
        City(name: "Kitchener", country: "Ontario, Canada", latitude: 43.4516, longitude: -80.4925, timezone: -5.0, elevation: 320.0, timeZoneId: "America/Toronto"),
        City(name: "Cambridge", country: "Ontario, Canada", latitude: 43.3616, longitude: -80.3144, timezone: -5.0, elevation: 310.0, timeZoneId: "America/Toronto"),
        City(name: "Guelph", country: "Ontario, Canada", latitude: 43.5448, longitude: -80.2482, timezone: -5.0, elevation: 334.0, timeZoneId: "America/Toronto"),
        City(name: "Toronto", country: "Ontario, Canada", latitude: 43.6532, longitude: -79.3832, timezone: -5.0, elevation: 76.0, timeZoneId: "America/Toronto"),
        City(name: "Mississauga", country: "Ontario, Canada", latitude: 43.5890, longitude: -79.6441, timezone: -5.0, elevation: 156.0, timeZoneId: "America/Toronto"),
        City(name: "Hamilton", country: "Ontario, Canada", latitude: 43.2557, longitude: -79.8711, timezone: -5.0, elevation: 102.0, timeZoneId: "America/Toronto"),
        City(name: "London", country: "Ontario, Canada", latitude: 42.9849, longitude: -81.2453, timezone: -5.0, elevation: 251.0, timeZoneId: "America/Toronto"),
        City(name: "Windsor", country: "Ontario, Canada", latitude: 42.3149, longitude: -83.0364, timezone: -5.0, elevation: 190.0, timeZoneId: "America/Toronto"),
        City(name: "Ottawa", country: "Ontario, Canada", latitude: 45.4215, longitude: -75.6972, timezone: -5.0, elevation: 70.0, timeZoneId: "America/Toronto"),
        City(name: "Montreal", country: "Quebec, Canada", latitude: 45.5017, longitude: -73.5673, timezone: -5.0, elevation: 36.0, timeZoneId: "America/Toronto"),
        City(name: "Quebec City", country: "Quebec, Canada", latitude: 46.8139, longitude: -71.2080, timezone: -5.0, elevation: 98.0, timeZoneId: "America/Toronto"),
        City(name: "Calgary", country: "Alberta, Canada", latitude: 51.0447, longitude: -114.0719, timezone: -6.0, elevation: 1045.0, timeZoneId: "America/Edmonton"),
        City(name: "Edmonton", country: "Alberta, Canada", latitude: 53.5461, longitude: -113.4938, timezone: -6.0, elevation: 671.0, timeZoneId: "America/Edmonton"),
        City(name: "Red Deer", country: "Alberta, Canada", latitude: 52.2681, longitude: -113.8112, timezone: -6.0, elevation: 858.0, timeZoneId: "America/Edmonton"),
        City(name: "Lethbridge", country: "Alberta, Canada", latitude: 49.6956, longitude: -112.8451, timezone: -6.0, elevation: 910.0, timeZoneId: "America/Edmonton"),
        City(name: "Fort McMurray", country: "Alberta, Canada", latitude: 56.7264, longitude: -111.3803, timezone: -6.0, elevation: 243.0, timeZoneId: "America/Edmonton"),
        City(name: "Banff", country: "Alberta, Canada", latitude: 51.1784, longitude: -115.5708, timezone: -6.0, elevation: 1383.0, timeZoneId: "America/Edmonton"),
        City(name: "Vancouver", country: "BC, Canada", latitude: 49.2827, longitude: -123.1207, timezone: -8.0, elevation: 70.0, timeZoneId: "America/Vancouver"),
        City(name: "Victoria", country: "BC, Canada", latitude: 48.4284, longitude: -123.3656, timezone: -8.0, elevation: 23.0, timeZoneId: "America/Vancouver"),
        City(name: "Winnipeg", country: "Manitoba, Canada", latitude: 49.8951, longitude: -97.1384, timezone: -6.0, elevation: 238.0, timeZoneId: "America/Winnipeg"),
        City(name: "Halifax", country: "Nova Scotia, Canada", latitude: 44.6488, longitude: -63.5752, timezone: -4.0, elevation: 45.0, timeZoneId: "America/Halifax"),

        // United States
        City(name: "New York", country: "United States", latitude: 40.7128, longitude: -74.0060, timezone: -5.0, elevation: 10.0, timeZoneId: "America/New_York"),
        City(name: "Chicago", country: "United States", latitude: 41.8781, longitude: -87.6298, timezone: -6.0, elevation: 181.0, timeZoneId: "America/Chicago"),
        City(name: "Detroit", country: "United States", latitude: 42.3314, longitude: -83.0458, timezone: -5.0, elevation: 200.0, timeZoneId: "America/Detroit"),
        City(name: "Dearborn", country: "United States", latitude: 42.3223, longitude: -83.1763, timezone: -5.0, elevation: 180.0, timeZoneId: "America/Detroit"),
        City(name: "Buffalo", country: "United States", latitude: 42.8864, longitude: -78.8784, timezone: -5.0, elevation: 183.0, timeZoneId: "America/New_York"),
        City(name: "Los Angeles", country: "United States", latitude: 34.0522, longitude: -118.2437, timezone: -8.0, elevation: 89.0, timeZoneId: "America/Los_Angeles"),
        City(name: "San Francisco", country: "United States", latitude: 37.7749, longitude: -122.4194, timezone: -8.0, elevation: 16.0, timeZoneId: "America/Los_Angeles"),
        City(name: "Seattle", country: "United States", latitude: 47.6062, longitude: -122.3321, timezone: -8.0, elevation: 53.0, timeZoneId: "America/Los_Angeles"),
        City(name: "Houston", country: "United States", latitude: 29.7604, longitude: -95.3698, timezone: -6.0, elevation: 15.0, timeZoneId: "America/Chicago"),
        City(name: "Dallas", country: "United States", latitude: 32.7767, longitude: -96.7970, timezone: -6.0, elevation: 131.0, timeZoneId: "America/Chicago"),
        City(name: "Washington D.C.", country: "United States", latitude: 38.9072, longitude: -77.0369, timezone: -5.0, elevation: 20.0, timeZoneId: "America/New_York"),
        City(name: "Philadelphia", country: "United States", latitude: 39.9526, longitude: -75.1652, timezone: -5.0, elevation: 12.0, timeZoneId: "America/New_York"),
        City(name: "Boston", country: "United States", latitude: 42.3601, longitude: -71.0589, timezone: -5.0, elevation: 43.0, timeZoneId: "America/New_York"),
        City(name: "Minneapolis", country: "United States", latitude: 44.9778, longitude: -93.2650, timezone: -6.0, elevation: 264.0, timeZoneId: "America/Chicago"),
        City(name: "Atlanta", country: "United States", latitude: 33.7490, longitude: -84.3880, timezone: -5.0, elevation: 320.0, timeZoneId: "America/New_York"),

        // Islamic World & Middle East
        City(name: "Makkah", country: "Saudi Arabia", latitude: 21.4225, longitude: 39.8262, timezone: 3.0, elevation: 277.0, timeZoneId: "Asia/Riyadh"),
        City(name: "Madinah", country: "Saudi Arabia", latitude: 24.4672, longitude: 39.6111, timezone: 3.0, elevation: 608.0, timeZoneId: "Asia/Riyadh"),
        City(name: "Jerusalem", country: "Palestine", latitude: 31.7683, longitude: 35.2137, timezone: 3.0, elevation: 754.0, timeZoneId: "Asia/Jerusalem"),
        City(name: "Riyadh", country: "Saudi Arabia", latitude: 24.7136, longitude: 46.6753, timezone: 3.0, elevation: 612.0, timeZoneId: "Asia/Riyadh"),
        City(name: "Jeddah", country: "Saudi Arabia", latitude: 21.5433, longitude: 39.1728, timezone: 3.0, elevation: 12.0, timeZoneId: "Asia/Riyadh"),
        City(name: "Dubai", country: "United Arab Emirates", latitude: 25.2048, longitude: 55.2708, timezone: 4.0, elevation: 5.0, timeZoneId: "Asia/Dubai"),
        City(name: "Abu Dhabi", country: "United Arab Emirates", latitude: 24.4539, longitude: 54.3773, timezone: 4.0, elevation: 10.0, timeZoneId: "Asia/Dubai"),
        City(name: "Doha", country: "Qatar", latitude: 25.2854, longitude: 51.5310, timezone: 3.0, elevation: 13.0, timeZoneId: "Asia/Qatar"),
        City(name: "Kuwait City", country: "Kuwait", latitude: 29.3759, longitude: 47.9774, timezone: 3.0, elevation: 10.0, timeZoneId: "Asia/Kuwait"),
        City(name: "Amman", country: "Jordan", latitude: 31.9454, longitude: 35.9284, timezone: 3.0, elevation: 773.0, timeZoneId: "Asia/Amman"),
        City(name: "Cairo", country: "Egypt", latitude: 30.0444, longitude: 31.2357, timezone: 2.0, elevation: 23.0, timeZoneId: "Africa/Cairo"),
        City(name: "Istanbul", country: "Turkey", latitude: 41.0082, longitude: 28.9784, timezone: 3.0, elevation: 39.0, timeZoneId: "Europe/Istanbul"),
        City(name: "Karachi", country: "Pakistan", latitude: 24.8607, longitude: 67.0011, timezone: 5.0, elevation: 8.0, timeZoneId: "Asia/Karachi"),
        City(name: "Lahore", country: "Pakistan", latitude: 31.5497, longitude: 74.3436, timezone: 5.0, elevation: 217.0, timeZoneId: "Asia/Karachi"),
        City(name: "Islamabad", country: "Pakistan", latitude: 33.6844, longitude: 73.0479, timezone: 5.0, elevation: 507.0, timeZoneId: "Asia/Karachi"),
        City(name: "Dhaka", country: "Bangladesh", latitude: 23.8103, longitude: 90.4125, timezone: 6.0, elevation: 4.0, timeZoneId: "Asia/Dhaka"),
        City(name: "Jakarta", country: "Indonesia", latitude: -6.2088, longitude: 106.8456, timezone: 7.0, elevation: 8.0, timeZoneId: "Asia/Jakarta"),
        City(name: "Kuala Lumpur", country: "Malaysia", latitude: 3.1390, longitude: 101.6869, timezone: 8.0, elevation: 52.0, timeZoneId: "Asia/Kuala_Lumpur"),

        // Europe & Worldwide
        City(name: "London", country: "United Kingdom", latitude: 51.5074, longitude: -0.1278, timezone: 0.0, elevation: 11.0, timeZoneId: "Europe/London"),
        City(name: "Birmingham", country: "United Kingdom", latitude: 52.4862, longitude: -1.8904, timezone: 0.0, elevation: 140.0, timeZoneId: "Europe/London"),
        City(name: "Paris", country: "France", latitude: 48.8566, longitude: 2.3522, timezone: 1.0, elevation: 35.0, timeZoneId: "Europe/Paris"),
        City(name: "Berlin", country: "Germany", latitude: 52.5200, longitude: 13.4050, timezone: 1.0, elevation: 34.0, timeZoneId: "Europe/Berlin"),
        City(name: "Sydney", country: "Australia", latitude: -33.8688, longitude: 151.2093, timezone: 10.0, elevation: 19.0, timeZoneId: "Australia/Sydney"),
        City(name: "Melbourne", country: "Australia", latitude: -37.8136, longitude: 144.9631, timezone: 10.0, elevation: 31.0, timeZoneId: "Australia/Sydney")
    ]
}
