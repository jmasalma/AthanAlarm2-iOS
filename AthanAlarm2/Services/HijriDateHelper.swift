import Foundation

public struct HijriDate: Codable, Equatable {
    public let day: Int
    public let month: Int // 1 to 12
    public let year: Int
    public let monthEnglish: String
    public let monthArabic: String

    public var formattedEnglish: String {
        return "\(day) \(monthEnglish) \(year) AH"
    }

    public var formattedArabic: String {
        return "\(day) \(monthArabic) \(year) هـ"
    }
}

public struct HijriDateHelper {
    private static let monthsEnglish = [
        "Muharram",
        "Safar",
        "Rabi' al-Awwal",
        "Rabi' al-Thani",
        "Jumada al-Awwal",
        "Jumada al-Thani",
        "Rajab",
        "Sha'ban",
        "Ramadan",
        "Shawwal",
        "Dhu al-Qi'dah",
        "Dhu al-Hijjah"
    ]

    private static let monthsArabic = [
        "محرم",
        "صفر",
        "ربيع الأول",
        "ربيع الثاني",
        "جمادى الأولى",
        "جمادى الآخرة",
        "رجب",
        "شعبان",
        "رمضان",
        "شوال",
        "ذو القعدة",
        "ذو الحجة"
    ]

    /// Converts Gregorian date to astronomical Hijri date matching Android HijriCalendarHelper
    /// Supports dayOffset (-2 to +2 days) for moon sighting alignment.
    public static func getHijriDate(
        from date: Date = Date(),
        dayOffset: Int = 0
    ) -> HijriDate {
        let cal = Calendar(identifier: .gregorian)
        var targetDate = date
        if dayOffset != 0, let shifted = cal.date(byAdding: .day, value: dayOffset, to: date) {
            targetDate = shifted
        }

        let comps = cal.dateComponents([.year, .month, .day], from: targetDate)
        var y = Double(comps.year ?? 2026)
        var m = Double(comps.month ?? 11)
        let d = Double(comps.day ?? 9)

        if m < 3.0 {
            y -= 1.0
            m += 12.0
        }

        let a = floor(y / 100.0)
        let b = 2.0 - a + floor(a / 4.0)
        let jd = floor(365.25 * (y + 4716.0)) + floor(30.6001 * (m + 1.0)) + d + b - 1524.5

        let epoch = 1948439.5
        let daysSinceEpoch = jd - epoch
        let cycles = floor(daysSinceEpoch / 10631.0)
        let remainingDays = daysSinceEpoch - cycles * 10631.0
        let yearInCycle = floor((remainingDays - 0.5) / 354.366)
        let hijriYear = Int(cycles * 30.0 + yearInCycle + 1.0)
        let dayOfYear = remainingDays - floor(yearInCycle * 354.366) - 0.5
        let rawMonth = Int(floor(dayOfYear / 29.5) + 1.0)
        let hijriMonth = min(12, max(1, rawMonth))
        let rawDay = Int(dayOfYear - floor(Double(hijriMonth - 1) * 29.5) + 1.0)
        let hijriDay = min(30, max(1, rawDay))

        return HijriDate(
            day: hijriDay,
            month: hijriMonth,
            year: hijriYear,
            monthEnglish: monthsEnglish[hijriMonth - 1],
            monthArabic: monthsArabic[hijriMonth - 1]
        )
    }

    public static func formattedHijriDate(from date: Date = Date(), dayOffset: Int = 0) -> String {
        return getHijriDate(from: date, dayOffset: dayOffset).formattedEnglish
    }

    public static func arabicHijriDate(from date: Date = Date(), dayOffset: Int = 0) -> String {
        return getHijriDate(from: date, dayOffset: dayOffset).formattedArabic
    }
}
