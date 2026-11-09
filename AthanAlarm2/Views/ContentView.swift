import SwiftUI

public struct ContentView: View {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var dashboardViewModel = PrayerDashboardViewModel(settings: .shared)

    @State private var selectedTab: Int = 0

    public var body: some View {
        TabView(selection: $selectedTab) {
            PrayerDashboardView(viewModel: dashboardViewModel, settings: settings)
                .tabItem {
                    Label("Prayers", systemImage: "clock.fill")
                }
                .tag(0)

            QiblaCompassView(settings: settings)
                .tabItem {
                    Label("Qibla", systemImage: "safari.fill")
                }
                .tag(1)

            AthkarView()
                .tabItem {
                    Label("Adhkar", systemImage: "heart.text.square.fill")
                }
                .tag(2)

            MonthlyCalendarView(settings: settings)
                .tabItem {
                    Label("Timetable", systemImage: "calendar")
                }
                .tag(3)

            SettingsView(settings: settings)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .accentColor(Color(hex: "0E3A2F"))
        .onAppear {
            NotificationService.shared.requestAuthorization()
        }
    }
}
