import SwiftUI
import CoreLocation
import AthanCore

public struct QiblaCompassView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var locationManager = LocationManager.shared

    @State private var feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    @State private var hasHapticTriggered: Bool = false

    private var activeCoordinates: (lat: Double, lon: Double) {
        if let loc = locationManager.userLocation, settings.useGPSLocation {
            return (loc.coordinate.latitude, loc.coordinate.longitude)
        } else {
            return (settings.selectedCity.latitude, settings.selectedCity.longitude)
        }
    }

    private var qiblaBearing: Double {
        let coords = activeCoordinates
        return QiblaCalculator.calculateBearing(fromLatitude: coords.lat, fromLongitude: coords.lon)
    }

    private var distanceKm: Double {
        let coords = activeCoordinates
        return QiblaCalculator.distanceToKaabaKm(fromLatitude: coords.lat, fromLongitude: coords.lon)
    }

    private var distanceMiles: Double {
        return distanceKm * 0.621371
    }

    // Relative needle angle from device heading
    private var relativeAngle: Double {
        var diff = qiblaBearing - locationManager.heading
        while diff < 0 { diff += 360 }
        while diff >= 360 { diff -= 360 }
        return diff
    }

    private var isFacingQibla: Bool {
        return relativeAngle <= 3.0 || relativeAngle >= 357.0
    }

    public var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header details
                VStack(spacing: 6) {
                    Text("Qibla Direction")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Bearing: \(String(format: "%.1f°", qiblaBearing)) from True North")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "0E3A2F"))

                    Text("Distance: \(Int(round(distanceKm))) km (\(Int(round(distanceMiles))) mi) to Kaaba")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 10)

                // Location mode indicator
                HStack(spacing: 6) {
                    Image(systemName: settings.useGPSLocation ? "location.fill" : "building.2.fill")
                        .font(.system(size: 12))
                    Text(settings.useGPSLocation ? "Live GPS Coordinates" : "\(settings.selectedCity.name), \(settings.selectedCity.country)")
                        .font(.system(size: 13, weight: .medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: "0E3A2F").opacity(0.1))
                .foregroundColor(Color(hex: "0E3A2F"))
                .clipShape(Capsule())

                Spacer()

                // Compass Rose & Needle
                ZStack {
                    // Outer decorative dial
                    Circle()
                        .stroke(
                            isFacingQibla ? Color(hex: "E6C280") : Color.secondary.opacity(0.2),
                            lineWidth: isFacingQibla ? 6 : 3
                        )
                        .frame(width: 280, height: 280)
                        .animation(.easeInOut(duration: 0.3), value: isFacingQibla)

                    // Compass Dial rotating with opposite device heading
                    ZStack {
                        // Degree ticks
                        ForEach(0..<12) { i in
                            Rectangle()
                                .fill(i % 3 == 0 ? Color.primary : Color.secondary.opacity(0.4))
                                .frame(width: i % 3 == 0 ? 3 : 1.5, height: i % 3 == 0 ? 14 : 8)
                                .offset(y: -126)
                                .rotationEffect(.degrees(Double(i) * 30))
                        }

                        // Cardinal points
                        Text("N")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.red)
                            .offset(y: -105)
                        Text("S")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .offset(y: 105)
                        Text("E")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .offset(x: 105)
                        Text("W")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .offset(x: -105)
                    }
                    .rotationEffect(.degrees(-locationManager.heading))
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: locationManager.heading)

                    // Qibla Pointer (Needle pointing directly to Kaaba)
                    ZStack {
                        // Golden Kaaba indicator at target angle
                        VStack(spacing: 0) {
                            Image(systemName: "square.fill")
                                .font(.system(size: 16))
                                .foregroundColor(isFacingQibla ? Color(hex: "E6C280") : Color(hex: "0E3A2F"))
                                .shadow(color: isFacingQibla ? Color(hex: "E6C280") : .clear, radius: 8)

                            // Needle shape
                            Path { path in
                                path.move(to: CGPoint(x: 10, y: 0))
                                path.addLine(to: CGPoint(x: 20, y: 70))
                                path.addLine(to: CGPoint(x: 10, y: 60))
                                path.addLine(to: CGPoint(x: 0, y: 70))
                                path.closeSubpath()
                            }
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "E6C280"), Color(hex: "0E3A2F")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 20, height: 70)

                            Spacer().frame(height: 110)
                        }
                    }
                    .rotationEffect(.degrees(relativeAngle))
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: relativeAngle)

                    // Center Hub
                    Circle()
                        .fill(Color(hex: "0E3A2F"))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "E6C280"), lineWidth: 2)
                        )
                }
                .frame(width: 300, height: 300)

                Spacer()

                // Facing status banner
                if isFacingQibla {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 18))
                        Text("You are facing the Qibla (Kaaba)!")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(hex: "0E3A2F"))
                    .foregroundColor(Color(hex: "E6C280"))
                    .clipShape(Capsule())
                    .shadow(radius: 6)
                    .onAppear {
                        if !hasHapticTriggered {
                            feedbackGenerator.impactOccurred()
                            hasHapticTriggered = true
                        }
                    }
                } else {
                    Text("Rotate your device until the needle points straight up")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .onAppear {
                            hasHapticTriggered = false
                        }
                }

                // Coordinates card footer
                VStack(spacing: 4) {
                    Text("Kaaba coordinates: 21.4225° N, 39.8262° E")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("Heading: \(String(format: "%.1f°", locationManager.heading))")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Qibla")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .onAppear {
                locationManager.startUpdatingHeading()
                locationManager.startUpdatingLocation()
            }
            .onDisappear {
                locationManager.stopUpdatingHeading()
            }
        }
    }
}
