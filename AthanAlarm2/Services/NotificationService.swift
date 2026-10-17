import Foundation
import UserNotifications
#if canImport(AthanCore)
import AthanCore
#endif

public class NotificationService: NSObject, ObservableObject {
    public static let shared = NotificationService()

    @Published public var isAuthorized: Bool = false

    override private init() {
        super.init()
        checkAuthorization()
    }

    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
        }
    }

    public func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = (settings.authorizationStatus == .authorized)
            }
        }
    }

    public func schedulePrayerNotifications(
        result: PrayerCalculationResult,
        alarmModes: [PrayerType: AlarmMode],
        city: City
    ) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let prayers: [(PrayerType, (hour: Int, minute: Int))] = [
            (.fajr, result.fajr),
            (.sunrise, result.sunrise),
            (.dhuhr, result.dhuhr),
            (.asr, result.asr),
            (.maghrib, result.maghrib),
            (.isha, result.isha)
        ]

        for (prayer, time) in prayers {
            let mode = alarmModes[prayer] ?? .athan
            guard mode != .muted else { continue }

            let content = UNMutableNotificationContent()
            content.title = "\(prayer.englishName) Time • \(prayer.arabicName)"
            content.body = "It is now time for \(prayer.englishName) in \(city.name)."
            content.categoryIdentifier = "PRAYER_ALARM"

            switch mode {
            case .athan:
                content.sound = UNNotificationSound.default
            case .chime:
                content.sound = UNNotificationSound.default
            case .silent, .muted:
                content.sound = nil
            }

            var dateComponents = DateComponents()
            dateComponents.hour = time.hour
            dateComponents.minute = time.minute
            dateComponents.second = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "prayer_\(prayer.rawValue)",
                content: content,
                trigger: trigger
            )

            center.add(request) { error in
                if let error = error {
                    print("Error scheduling notification for \(prayer.rawValue): \(error.localizedDescription)")
                }
            }
        }
    }
}
