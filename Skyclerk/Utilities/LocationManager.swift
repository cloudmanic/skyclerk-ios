//
// LocationManager.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import CoreLocation
import SwiftUI

/// Manages location services for tagging ledger entries with GPS coordinates.
/// This class wraps CLLocationManager and publishes the current latitude, longitude,
/// and authorization status so SwiftUI views can reactively respond to location changes.
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var latitude: Double = 0.0
    @Published var longitude: Double = 0.0
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    /// Initialize the location manager, configure it as the delegate,
    /// and set the desired accuracy to best available.
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    /// Request "when in use" location permission from the user and begin
    /// receiving location updates. If permission has already been granted,
    /// location updates will start immediately.
    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    /// Stop receiving location updates to conserve battery.
    /// Call this when the location is no longer needed.
    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    /// Called by CLLocationManager when new location data is available.
    /// Updates the published latitude and longitude with the most recent
    /// location fix, then stops updates to conserve battery.
    ///
    /// - Parameters:
    ///   - manager: The location manager providing the update.
    ///   - locations: An array of CLLocation objects in chronological order.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        manager.stopUpdatingLocation()
    }

    /// Called by CLLocationManager when the authorization status changes.
    /// Updates the published authorization status and automatically begins
    /// location updates if the user has granted permission.
    ///
    /// - Parameters:
    ///   - manager: The location manager reporting the change.
    ///   - status: The new authorization status.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    /// Called by CLLocationManager when a location request fails.
    /// Logs the error description to the console for debugging purposes.
    ///
    /// - Parameters:
    ///   - manager: The location manager reporting the error.
    ///   - error: The error that occurred during location retrieval.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
