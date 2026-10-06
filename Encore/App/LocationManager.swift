//
//  LocationManager.swift
//  Encore
//

import Foundation
import CoreLocation
import SwiftUI

@MainActor
final class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()

    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var authStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var cityName: String?
    @Published private(set) var countryCode: String?   // ISO 3166-1 alpha-2, e.g. "CR", "US"
    @Published var isLocating = false

    private let manager = CLLocationManager()
    private var onLocationUpdate: ((CLLocation) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authStatus = manager.authorizationStatus
    }

    // MARK: - Request

    /// Requests one-shot location update. Calls back on the main actor.
    func requestLocation(completion: ((CLLocation?) -> Void)? = nil) {
        switch manager.authorizationStatus {
        case .notDetermined:
            onLocationUpdate = { [weak self] loc in
                completion?(loc)
                self?.onLocationUpdate = nil
            }
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            isLocating = true
            onLocationUpdate = { [weak self] loc in
                completion?(loc)
                self?.onLocationUpdate = nil
            }
            manager.requestLocation()
        default:
            completion?(nil)
        }
    }

    // MARK: - Reverse geocode

    /// Reverse-geocodes a CLLocation into city name + ISO country code.
    func reverseGeocode(_ location: CLLocation) async -> (city: String?, countryCode: String?) {
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            let pm = placemarks.first
            let city = pm?.locality ?? pm?.administrativeArea
            let code = pm?.isoCountryCode
            await MainActor.run {
                cityName = city
                countryCode = code
            }
            return (city, code)
        } catch {
            print("[LocationManager] reverseGeocode failed: \(error)")
            return (nil, nil)
        }
    }

    // MARK: - Helpers

    /// Returns the dial code for an ISO country code using device locale data.
    static func dialCode(for isoCode: String) -> String? {
        CountryDialCode.all.first(where: { $0.isoCode == isoCode })?.dialCode
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = loc
            self.isLocating = false
            self.onLocationUpdate?(loc)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.isLocating = false
            self.onLocationUpdate?(self.currentLocation ?? CLLocation())
            print("[LocationManager] failed: \(error)")
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse ||
               manager.authorizationStatus == .authorizedAlways {
                self.isLocating = true
                manager.requestLocation()
            }
        }
    }
}

// MARK: - Haversine distance

extension CLLocation {
    /// Distance in kilometres between two coordinates using the haversine formula.
    func kilometersFrom(latitude: Double, longitude: Double) -> Double {
        let other = CLLocation(latitude: latitude, longitude: longitude)
        return distance(from: other) / 1000.0
    }
}
