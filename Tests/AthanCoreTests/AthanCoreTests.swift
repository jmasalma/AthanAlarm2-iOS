import XCTest
@testable import AthanCore

final class AthanCoreTests: XCTestCase {

    func testQiblaBearingWaterloo() {
        // Waterloo: 43.4643° N, 80.5204° W
        let bearing = QiblaCalculator.calculateBearing(fromLatitude: 43.4643, fromLongitude: -80.5204)
        // From North America, Qibla bearing goes North-East (~51° to 56°)
        XCTAssertGreaterThan(bearing, 45.0)
        XCTAssertLessThan(bearing, 65.0)
    }

    func testDistanceToKaaba() {
        let dist = QiblaCalculator.distanceToKaabaKm(fromLatitude: 43.4643, fromLongitude: -80.5204)
        XCTAssertGreaterThan(dist, 9000.0)
        XCTAssertLessThan(dist, 11000.0)
    }

    func testPrayerTimesCalculation() {
        let city = City.default
        let date = Date()
        let result = PrayerCalculationEngine.calculate(
            date: date,
            city: city,
            method: .isna,
            juristic: .standard
        )

        // Ensure reasonable order: Fajr < Sunrise < Dhuhr < Asr < Maghrib < Isha
        let fajrMin = result.fajr.hour * 60 + result.fajr.minute
        let sunriseMin = result.sunrise.hour * 60 + result.sunrise.minute
        let dhuhrMin = result.dhuhr.hour * 60 + result.dhuhr.minute
        let asrMin = result.asr.hour * 60 + result.asr.minute
        let maghribMin = result.maghrib.hour * 60 + result.maghrib.minute
        let ishaMin = result.isha.hour * 60 + result.isha.minute

        XCTAssertLessThan(fajrMin, sunriseMin)
        XCTAssertLessThan(sunriseMin, dhuhrMin)
        XCTAssertLessThan(dhuhrMin, asrMin)
        XCTAssertLessThan(asrMin, maghribMin)
        XCTAssertLessThan(maghribMin, ishaMin)
    }

    func testAllCalculationMethods() {
        let city = City.default
        let date = Date()
        for method in CalculationMethod.allCases {
            let result = PrayerCalculationEngine.calculate(date: date, city: city, method: method)
            XCTAssertGreaterThanOrEqual(result.fajr.hour, 0)
            XCTAssertLessThan(result.fajr.hour, 24)
            XCTAssertGreaterThanOrEqual(result.isha.hour, 0)
            XCTAssertLessThan(result.isha.hour, 24)
        }
    }
}
