import SwiftUI
import AthanCore

public struct MonthlyCalendarView: View {
    @ObservedObject var settings: AppSettings

    @State private var selectedDate: Date = Date()
    @State private var showingDatePicker: Bool = false

    private var calendar: Calendar {
        Calendar.current
    }

    private var monthYearTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }

    private var daysInMonth: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: selectedDate),
              let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate)) else {
            return []
        }

        return range.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }

    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Month Selector Bar
                HStack {
                    Button(action: { changeMonth(by: -1) }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: "0E3A2F"))
                    }

                    Spacer()

                    Text(monthYearTitle)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)

                    Spacer()

                    Button(action: { changeMonth(by: 1) }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: "0E3A2F"))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color(uiColor: .secondarySystemGroupedBackground))

                // Table Header
                HStack(spacing: 0) {
                    Text("Day")
                        .frame(width: 44, alignment: .leading)
                    Spacer()
                    Text("Fajr")
                        .frame(width: 48, alignment: .center)
                    Spacer()
                    Text("Sun")
                        .frame(width: 48, alignment: .center)
                    Spacer()
                    Text("Dhuhr")
                        .frame(width: 48, alignment: .center)
                    Spacer()
                    Text("Asr")
                        .frame(width: 48, alignment: .center)
                    Spacer()
                    Text("Maghrib")
                        .frame(width: 52, alignment: .center)
                    Spacer()
                    Text("Isha")
                        .frame(width: 48, alignment: .trailing)
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(uiColor: .systemGroupedBackground))

                Divider()

                // List of Days
                List {
                    ForEach(daysInMonth, id: \.self) { date in
                        let dayNum = calendar.component(.day, from: date)
                        let isToday = calendar.isDateInToday(date)
                        let result = PrayerCalculationEngine.calculate(
                            date: date,
                            city: settings.selectedCity,
                            method: settings.calculationMethod,
                            juristic: settings.juristicMethod,
                            highLatRule: settings.highLatitudeRule,
                            offsets: settings.prayerOffsets,
                            dhuhrPrecautionMin: settings.dhuhrPrecautionMin
                        )

                        HStack(spacing: 0) {
                            Text("\(dayNum)")
                                .font(.system(size: 14, weight: isToday ? .heavy : .medium))
                                .foregroundColor(isToday ? Color(hex: "0E3A2F") : .primary)
                                .frame(width: 44, alignment: .leading)

                            Spacer()

                            Text(timeStr(result.fajr))
                                .frame(width: 48, alignment: .center)
                            Spacer()
                            Text(timeStr(result.sunrise))
                                .frame(width: 48, alignment: .center)
                            Spacer()
                            Text(timeStr(result.dhuhr))
                                .frame(width: 48, alignment: .center)
                            Spacer()
                            Text(timeStr(result.asr))
                                .frame(width: 48, alignment: .center)
                            Spacer()
                            Text(timeStr(result.maghrib))
                                .frame(width: 52, alignment: .center)
                            Spacer()
                            Text(timeStr(result.isha))
                                .frame(width: 48, alignment: .trailing)
                        }
                        .font(.system(size: 12, weight: isToday ? .bold : .regular, design: .monospaced))
                        .padding(.vertical, 4)
                        .listRowBackground(isToday ? Color(hex: "0E3A2F").opacity(0.12) : Color.clear)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Prayer Timetable")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Today") {
                        selectedDate = Date()
                    }
                    .foregroundColor(Color(hex: "0E3A2F"))
                }
            }
        }
    }

    private func changeMonth(by amount: Int) {
        if let newDate = calendar.date(byAdding: .month, value: amount, to: selectedDate) {
            selectedDate = newDate
        }
    }

    private func timeStr(_ tuple: (hour: Int, minute: Int)) -> String {
        if settings.use24HourTime {
            return String(format: "%02d:%02d", tuple.hour, tuple.minute)
        } else {
            let h12 = tuple.hour % 12 == 0 ? 12 : tuple.hour % 12
            return String(format: "%d:%02d", h12, tuple.minute)
        }
    }
}
