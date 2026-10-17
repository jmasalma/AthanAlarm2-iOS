import Foundation
import Combine
#if canImport(AthanCore)
import AthanCore
#endif

public struct PrayerDisplayItem: Identifiable, Equatable {
    public var id: String { type.rawValue }
    public let type: PrayerType
    public let englishName: String
    public let arabicName: String
    public let hour: Int
    public let minute: Int
    public let timeFormatted: String
    public let isNext: Bool
    public let isCurrent: Bool
    public let isPassed: Bool
}

public class PrayerDashboardViewModel: ObservableObject {
    @Published public var calculationResult: PrayerCalculationResult?
    @Published public var prayerItems: [PrayerDisplayItem] = []
    @Published public var nextPrayer: PrayerType = .fajr
    @Published public var countdownString: String = "--:--:--"
    @Published public var timeRemainingSeconds: Int = 0
    @Published public var progressToNextPrayer: Double = 0.0 // 0.0 to 1.0
    @Published public var currentGregorianDateString: String = ""
    @Published public var currentHijriDateString: String = ""
    @Published public var qiblaBearing: Double = 0.0
    @Published public var qiblaDistanceKm: Double = 0.0

    private var timerSubscription: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    private let settings: AppSettings

    public init(settings: AppSettings = .shared) {
        self.settings = settings

        // Observe settings changes
        settings.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.recalculate()
                }
            }
            .store(in: &cancellables)

        recalculate()

        // 1-second reactive timer for countdown
        timerSubscription = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateCountdown()
            }
    }

    public func recalculate() {
        let now = Date()
        let city = settings.selectedCity

        // Format dates
        let gregorianFormatter = DateFormatter()
        gregorianFormatter.dateStyle = .full
        self.currentGregorianDateString = gregorianFormatter.string(from: now)
        self.currentHijriDateString = HijriDateHelper.formattedHijriDate(from: now)

        // Qibla
        self.qiblaBearing = QiblaCalculator.calculateBearing(fromLatitude: city.latitude, fromLongitude: city.longitude)
        self.qiblaDistanceKm = QiblaCalculator.distanceToKaabaKm(fromLatitude: city.latitude, fromLongitude: city.longitude)

        // Calculate Prayer Times
        let result = PrayerCalculationEngine.calculate(
            date: now,
            city: city,
            method: settings.calculationMethod,
            juristic: settings.juristicMethod,
            highLatRule: settings.highLatitudeRule,
            offsets: settings.prayerOffsets,
            dhuhrPrecautionMin: settings.dhuhrPrecautionMin
        )
        self.calculationResult = result

        updateCountdown()

        // Schedule notifications if enabled
        NotificationService.shared.schedulePrayerNotifications(
            result: result,
            alarmModes: settings.alarmModes,
            city: city
        )
    }

    public func updateCountdown() {
        guard let result = calculationResult else { return }

        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentSecond = calendar.component(.second, from: now)
        let nowTotalSeconds = (currentHour * 3600) + (currentMinute * 60) + currentSecond

        let prayerList: [(PrayerType, (hour: Int, minute: Int))] = [
            (.fajr, result.fajr),
            (.sunrise, result.sunrise),
            (.dhuhr, result.dhuhr),
            (.asr, result.asr),
            (.maghrib, result.maghrib),
            (.isha, result.isha)
        ]

        var foundNext: (prayer: PrayerType, seconds: Int, prevSeconds: Int)? = nil

        for i in 0..<prayerList.count {
            let (pType, time) = prayerList[i]
            let pSeconds = (time.hour * 3600) + (time.minute * 60)

            if pSeconds > nowTotalSeconds {
                let prevPSeconds: Int
                if i > 0 {
                    let (_, prevTime) = prayerList[i - 1]
                    prevPSeconds = (prevTime.hour * 3600) + (prevTime.minute * 60)
                } else {
                    // Previous is Isha of yesterday (~-4 to -6 hours)
                    let (_, ishaTime) = prayerList.last!
                    prevPSeconds = (ishaTime.hour * 3600) + (ishaTime.minute * 60) - 86400
                }
                foundNext = (pType, pSeconds, prevPSeconds)
                break
            }
        }

        // If after Isha, next is tomorrow's Fajr
        if foundNext == nil {
            let tomorrowFajrSeconds = (result.fajr.hour * 3600) + (result.fajr.minute * 60) + 86400
            let ishaSeconds = (result.isha.hour * 3600) + (result.isha.minute * 60)
            foundNext = (.fajr, tomorrowFajrSeconds, ishaSeconds)
        }

        guard let nextInfo = foundNext else { return }

        self.nextPrayer = nextInfo.prayer
        let diffSeconds = max(0, nextInfo.seconds - nowTotalSeconds)
        self.timeRemainingSeconds = diffSeconds

        let hours = diffSeconds / 3600
        let minutes = (diffSeconds % 3600) / 60
        let seconds = diffSeconds % 60
        self.countdownString = String(format: "%02d:%02d:%02d", hours, minutes, seconds)

        let totalInterval = max(1, nextInfo.seconds - nextInfo.prevSeconds)
        let elapsed = max(0, nowTotalSeconds - nextInfo.prevSeconds)
        self.progressToNextPrayer = min(1.0, max(0.0, Double(elapsed) / Double(totalInterval)))

        // Build display items
        var items: [PrayerDisplayItem] = []
        for (pType, time) in prayerList {
            let pSec = (time.hour * 3600) + (time.minute * 60)
            let isNext = (pType == nextPrayer)
            let isPassed = pSec < nowTotalSeconds
            let formatted = formatTime(hour: time.hour, minute: time.minute, use24Hour: settings.use24HourTime)

            items.append(
                PrayerDisplayItem(
                    type: pType,
                    englishName: pType.englishName,
                    arabicName: pType.arabicName,
                    hour: time.hour,
                    minute: time.minute,
                    timeFormatted: formatted,
                    isNext: isNext,
                    isCurrent: !isPassed && !isNext,
                    isPassed: isPassed
                )
            )
        }
        self.prayerItems = items
    }

    public func formatTime(hour: Int, minute: Int, use24Hour: Bool) -> String {
        if use24Hour {
            return String(format: "%02d:%02d", hour, minute)
        } else {
            let period = hour >= 12 ? "PM" : "AM"
            let h12 = hour % 12 == 0 ? 12 : hour % 12
            return String(format: "%d:%02d %@", h12, minute, period)
        }
    }
}
