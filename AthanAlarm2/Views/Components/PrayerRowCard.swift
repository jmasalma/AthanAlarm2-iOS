import SwiftUI
import AthanCore

public struct PrayerRowCard: View {
    public let item: PrayerDisplayItem
    public let alarmMode: AlarmMode
    public let onCycleAlarm: () -> Void
    public let onPreviewSound: () -> Void

    public var body: some View {
        HStack(spacing: 14) {
            // Prayer Icon & Names
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Image(systemName: iconForPrayer(item.type))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(item.isNext ? Color(hex: "0E3A2F") : .secondary)

                    Text(item.englishName)
                        .font(.system(size: 17, weight: item.isNext ? .bold : .semibold))
                        .foregroundColor(item.isNext ? Color(hex: "0E3A2F") : .primary)
                }

                Text(item.arabicName)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Time Display
            Text(item.timeFormatted)
                .font(.system(size: 18, weight: item.isNext ? .bold : .medium, design: .rounded))
                .foregroundColor(item.isNext ? Color(hex: "0E3A2F") : .primary)

            // Alarm Mode Button
            Button(action: onCycleAlarm) {
                HStack(spacing: 4) {
                    Image(systemName: iconForAlarmMode(alarmMode))
                        .font(.system(size: 13, weight: .semibold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(alarmColor(alarmMode).opacity(0.15))
                .foregroundColor(alarmColor(alarmMode))
                .clipShape(Capsule())
            }
            .buttonStyle(.borderless)
            .help(alarmMode.title)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(item.isNext ? Color(hex: "0E3A2F").opacity(0.08) : Color(uiColor: .secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(item.isNext ? Color(hex: "0E3A2F") : Color.clear, lineWidth: 1.5)
        )
        .contentShape(Rectangle())
    }

    private func iconForPrayer(_ type: PrayerType) -> String {
        switch type {
        case .fajr: return "sun.and.horizon.fill"
        case .sunrise: return "sunrise.fill"
        case .dhuhr: return "sun.max.fill"
        case .asr: return "sun.haze.fill"
        case .maghrib: return "sunset.fill"
        case .isha: return "moon.stars.fill"
        case .nextFajr: return "sun.and.horizon"
        }
    }

    private func iconForAlarmMode(_ mode: AlarmMode) -> String {
        switch mode {
        case .athan: return "speaker.wave.3.fill"
        case .chime: return "bell.fill"
        case .silent: return "bell.slash"
        case .muted: return "speaker.slash.fill"
        }
    }

    private func alarmColor(_ mode: AlarmMode) -> Color {
        switch mode {
        case .athan: return Color(hex: "0E3A2F")
        case .chime: return Color.orange
        case .silent: return Color.purple
        case .muted: return Color.gray
        }
    }
}

// Simple Color Hex helper
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
