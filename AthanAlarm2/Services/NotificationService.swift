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
        city: City,
        preReminderEnabled: Bool = false,
        preReminderMinutes: Int = 20,
        preReminderSound: String = "chime"
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

            // 1. Pre-Prayer Countdown Reminder (e.g. 20 min before)
            if preReminderEnabled && prayer.isSalat && preReminderMinutes > 0 {
                let prayerTotalMin = (time.hour * 60) + time.minute
                let preTotalMin = ((prayerTotalMin - preReminderMinutes) % 1440 + 1440) % 1440
                let preHour = preTotalMin / 60
                let preMinute = preTotalMin % 60

                let preContent = UNMutableNotificationContent()
                preContent.title = "\(prayer.englishName) in \(preReminderMinutes) Minutes"
                preContent.body = "Prepare for \(prayer.englishName) prayer in \(city.name)."
                preContent.categoryIdentifier = "PRE_PRAYER_REMINDER"

                if preReminderSound != "silent" {
                    preContent.sound = UNNotificationSound.default
                } else {
                    preContent.sound = nil
                }

                var preDateComponents = DateComponents()
                preDateComponents.hour = preHour
                preDateComponents.minute = preMinute
                preDateComponents.second = 0

                let preTrigger = UNCalendarNotificationTrigger(dateMatching: preDateComponents, repeats: true)
                let preRequest = UNNotificationRequest(
                    identifier: "pre_prayer_\(prayer.rawValue)",
                    content: preContent,
                    trigger: preTrigger
                )
                center.add(preRequest)
            }

            // 2. Exact Athan Alarm
            let content = UNMutableNotificationContent()
            content.title = "\(prayer.englishName) Time • \(prayer.arabicName)"
            content.body = "It is now time for \(prayer.englishName) in \(city.name)."
            content.categoryIdentifier = "PRAYER_ALARM"

            switch mode {
            case .athan:
                if prayer == .fajr {
                    content.sound = UNNotificationSound(named: UNNotificationSoundName("athan_fajr.mp3"))
                } else {
                    content.sound = UNNotificationSound(named: UNNotificationSoundName("athan_general.mp3"))
                }
            case .chime:
                content.sound = UNNotificationSound(named: UNNotificationSoundName("athan_chime.mp3"))
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
