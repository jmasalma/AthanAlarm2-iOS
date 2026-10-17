import WidgetKit
import SwiftUI
import AthanCore

struct PrayerTimelineEntry: TimelineEntry {
    let date: Date
    let nextPrayer: PrayerType
    let nextPrayerTime: String
    let city: String
    let countdownMinutes: Int
    let allPrayers: [(name: String, time: String, isNext: Bool)]
}

struct PrayerWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerTimelineEntry {
        PrayerTimelineEntry(
            date: Date(),
            nextPrayer: .asr,
            nextPrayerTime: "3:45 PM",
            city: "Waterloo",
            countdownMinutes: 45,
            allPrayers: [
                ("Fajr", "5:32 AM", false),
                ("Sunrise", "7:02 AM", false),
                ("Dhuhr", "1:15 PM", false),
                ("Asr", "3:45 PM", true),
                ("Maghrib", "6:20 PM", false),
                ("Isha", "7:50 PM", false)
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerTimelineEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerTimelineEntry>) -> Void) {
        let now = Date()
        let city = City.default
        let result = PrayerCalculationEngine.calculate(date: now, city: city)

        func fmt(_ t: (hour: Int, minute: Int)) -> String {
            let h12 = t.hour % 12 == 0 ? 12 : t.hour % 12
            let p = t.hour >= 12 ? "PM" : "AM"
            return String(format: "%d:%02d %@", h12, t.minute, p)
        }

        let prayers: [(PrayerType, (hour: Int, minute: Int))] = [
            (.fajr, result.fajr),
            (.sunrise, result.sunrise),
            (.dhuhr, result.dhuhr),
            (.asr, result.asr),
            (.maghrib, result.maghrib),
            (.isha, result.isha)
        ]

        let cal = Calendar.current
        let nowSec = cal.component(.hour, from: now) * 3600 + cal.component(.minute, from: now) * 60

        var next = prayers[0].0
        var nextTimeStr = fmt(prayers[0].1)
        var cdMinutes = 0

        for (p, t) in prayers {
            let sec = t.hour * 3600 + t.minute * 60
            if sec > nowSec {
                next = p
                nextTimeStr = fmt(t)
                cdMinutes = (sec - nowSec) / 60
                break
            }
        }

        let all = prayers.map { (p, t) in
            (p.englishName, fmt(t), p == next)
        }

        let entry = PrayerTimelineEntry(
            date: now,
            nextPrayer: next,
            nextPrayerTime: nextTimeStr,
            city: city.name,
            countdownMinutes: cdMinutes,
            allPrayers: all
        )

        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now.addingTimeInterval(900)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct PrayerWidgetEntryView: View {
    var entry: PrayerWidgetProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(entry.city)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "0E3A2F"))
                    Spacer()
                    Image(systemName: "clock.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "0E3A2F"))
                }

                Spacer()

                Text("NEXT PRAYER")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundColor(.secondary)

                Text(entry.nextPrayer.englishName)
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(Color(hex: "0E3A2F"))

                Text(entry.nextPrayerTime)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("in \(entry.countdownMinutes) min")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(12)

        case .systemMedium:
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.city)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "0E3A2F"))

                    Text("NEXT PRAYER")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(.secondary)

                    Text(entry.nextPrayer.englishName)
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(Color(hex: "0E3A2F"))

                    Text(entry.nextPrayerTime)
                        .font(.system(size: 16, weight: .bold, design: .rounded))

                    Text("in \(entry.countdownMinutes) minutes")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .frame(width: 120, alignment: .leading)

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(entry.allPrayers.prefix(5), id: \.name) { p in
                        HStack {
                            Text(p.name)
                                .font(.system(size: 11, weight: p.isNext ? .bold : .regular))
                                .foregroundColor(p.isNext ? Color(hex: "0E3A2F") : .secondary)
                            Spacer()
                            Text(p.time)
                                .font(.system(size: 11, weight: p.isNext ? .bold : .regular, design: .rounded))
                                .foregroundColor(p.isNext ? Color(hex: "0E3A2F") : .primary)
                        }
                    }
                }
            }
            .padding(12)

        default:
            VStack {
                Text(entry.nextPrayer.englishName)
                Text(entry.nextPrayerTime)
            }
        }
    }
}

@main
struct AthanAlarmWidgetsBundle: WidgetBundle {
    var body: some Widget {
        PrayerTimeWidget()
    }
}

struct PrayerTimeWidget: Widget {
    let kind: String = "PrayerTimeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerWidgetProvider()) { entry in
            PrayerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Prayer Times")
        .description("Quick glance at upcoming prayer time and countdown.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
