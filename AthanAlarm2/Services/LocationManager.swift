import Foundation
import CoreLocation
import Combine

public class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    public static let shared = LocationManager()

    private let manager = CLLocationManager()

    @Published public var userLocation: CLLocation?
    @Published public var heading: Double = 0.0 // True or magnetic heading in degrees (0-360)
    @Published public var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published public var locationError: String?

    override private init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.headingFilter = 1.0 // update every 1 degree
    }

    public func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    public func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }

    public func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }

    public func startUpdatingHeading() {
        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        }
    }

    public func stopUpdatingHeading() {
        if CLLocationManager.headingAvailable() {
            manager.stopUpdatingHeading()
        }
    }

    // MARK: - CLLocationManagerDelegate

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
            if CLLocationManager.headingAvailable() {
                manager.startUpdatingHeading()
            }
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.userLocation = location
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Prefer true heading if available, fallback to magnetic heading
        if newHeading.trueHeading >= 0 {
            self.heading = newHeading.trueHeading
        } else {
            self.heading = newHeading.magneticHeading
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.locationError = error.localizedDescription
    }
}
