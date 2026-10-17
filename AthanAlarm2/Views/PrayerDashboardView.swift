import SwiftUI
#if canImport(AthanCore)
import AthanCore
#endif

public struct PrayerDashboardView: View {
    @ObservedObject var viewModel: PrayerDashboardViewModel
    @ObservedObject var settings: AppSettings
    @ObservedObject var audioService = AudioService.shared

    @State private var showingCitySheet: Bool = false

    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Top City & Dates Header
                    VStack(spacing: 6) {
                        Button(action: { showingCitySheet = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "0E3A2F"))

                                Text("\(settings.selectedCity.name), \(settings.selectedCity.country)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.primary)

                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Text(viewModel.currentHijriDateString)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "B38B3F")) // Golden accent

                        Text(viewModel.currentGregorianDateString)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)

                    // Hero Next Prayer Countdown Card
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("NEXT PRAYER")
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(1.2)
                                    .foregroundColor(Color(hex: "E0F2FE"))

                                HStack(spacing: 8) {
                                    Text(viewModel.nextPrayer.englishName)
                                        .font(.system(size: 28, weight: .heavy))
                                        .foregroundColor(.white)

                                    Text(viewModel.nextPrayer.arabicName)
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(Color(hex: "E6C280"))
                                }
                            }

                            Spacer()

                            // Sound Preview Button
                            Button(action: {
                                if audioService.isPlaying {
                                    audioService.stop()
                                } else {
                                    audioService.previewAthan()
                                }
                            }) {
                                Image(systemName: audioService.isPlaying ? "stop.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(Color(hex: "E6C280"))
                            }
                        }

                        // Countdown Timer
                        VStack(spacing: 6) {
                            Text(viewModel.countdownString)
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .monospacedDigit()

                            Text("time remaining")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: "E0F2FE"))
                        }

                        // Progress bar towards next prayer
                        VStack(spacing: 4) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(height: 6)

                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: "E6C280"), Color(hex: "F7DF94")],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * CGFloat(viewModel.progressToNextPrayer), height: 6)
                                }
                            }
                            .frame(height: 6)
                        }
                    }
                    .padding(20)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "0E3A2F"), Color(hex: "174D3F")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(24)
                    .shadow(color: Color(hex: "0E3A2F").opacity(0.25), radius: 12, x: 0, y: 6)
                    .padding(.horizontal)

                    // Daily Prayer Times List
                    VStack(spacing: 10) {
                        ForEach(viewModel.prayerItems) { item in
                            PrayerRowCard(
                                item: item,
                                alarmMode: settings.alarmModes[item.type] ?? .athan,
                                onCycleAlarm: {
                                    settings.cycleAlarmMode(for: item.type)
                                    viewModel.recalculate()
                                },
                                onPreviewSound: {
                                    audioService.previewChime()
                                }
                            )
                        }
                    }
                    .padding(.horizontal)

                    // Tahajjud & Midnight Info Card
                    if let result = viewModel.calculationResult {
                        VStack(spacing: 12) {
                            HStack {
                                Text("NIGHT PRAYERS & VIGIL")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .tracking(0.8)
                                Spacer()
                            }

                            HStack(spacing: 16) {
                                // Midnight
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Islamic Midnight")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Text(viewModel.formatTime(hour: result.midnight.hour, minute: result.midnight.minute, use24Hour: settings.use24HourTime))
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .cornerRadius(12)

                                // Last Third
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Last 1/3 (Tahajjud)")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Text(viewModel.formatTime(hour: result.lastThird.hour, minute: result.lastThird.minute, use24Hour: settings.use24HourTime))
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(hex: "0E3A2F"))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("AthanAlarm2")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .sheet(isPresented: $showingCitySheet) {
                CitySelectionSheet(settings: settings, onSelected: {
                    viewModel.recalculate()
                })
            }
        }
    }
}

public struct CitySelectionSheet: View {
    @ObservedObject var settings: AppSettings
    public let onSelected: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""

    public var filteredCities: [City] {
        if searchText.isEmpty {
            return AppSettings.predefinedCities
        } else {
            return AppSettings.predefinedCities.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.country.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    public var body: some View {
        NavigationView {
            List {
                Section(header: Text("Current Selected")) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(settings.selectedCity.name)
                                .font(.headline)
                            Text(settings.selectedCity.country)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "0E3A2F"))
                    }
                }

                Section(header: Text("Global Cities")) {
                    ForEach(filteredCities) { city in
                        Button(action: {
                            settings.selectedCity = city
                            onSelected()
                            dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(city.name)
                                        .foregroundColor(.primary)
                                        .font(.system(size: 16, weight: .medium))
                                    Text(city.country)
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 13))
                                }
                                Spacer()
                                if city.id == settings.selectedCity.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color(hex: "0E3A2F"))
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search city or country")
            .navigationTitle("Select City")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
