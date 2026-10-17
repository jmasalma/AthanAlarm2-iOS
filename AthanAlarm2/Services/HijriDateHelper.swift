import Foundation

public struct HijriDateHelper {
    public static func formattedHijriDate(from date: Date = Date(), locale: Locale = Locale(identifier: "en")) -> String {
        let islamicCalendar = Calendar(identifier: .islamicUmmAlQura)
        let formatter = DateFormatter()
        formatter.calendar = islamicCalendar
        formatter.locale = locale
        formatter.dateFormat = "d MMMM yyyy AH"
        return formatter.string(from: date)
    }

    public static func arabicHijriDate(from date: Date = Date()) -> String {
        let islamicCalendar = Calendar(identifier: .islamicUmmAlQura)
        let formatter = DateFormatter()
        formatter.calendar = islamicCalendar
        formatter.locale = Locale(identifier: "ar")
        formatter.dateFormat = "d MMMM yyyy هـ"
        return formatter.string(from: date)
    }
}
