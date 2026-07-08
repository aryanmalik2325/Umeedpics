// LocationManager.swift
// Handles device location and reverse geocoding

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    
    @Published var currentLocation: CLLocation?
    @Published var locationName: String = "Fetching location..."
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdating() {
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdating() {
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - Reverse Geocoding
    func reverseGeocode(location: CLLocation) async -> String {
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                var parts: [String] = []
                if let subLocality = placemark.subLocality { parts.append(subLocality) }
                if let locality = placemark.locality { parts.append(locality) }
                if let administrativeArea = placemark.administrativeArea { parts.append(administrativeArea) }
                return parts.joined(separator: ", ")
            }
        } catch {
            print("Geocoding error: \(error)")
        }
        return "Unknown location"
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.currentLocation = location
        }
        
        Task { @MainActor in
            self.locationName = await reverseGeocode(location: location)
            // Update user location in Firebase
            try? await FirebaseManager.shared.updateUserLocation(location)
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    // MARK: - Distance Helper
    func distance(from location: CLLocation) -> String {
        guard let current = currentLocation else { return "" }
        let distanceMeters = current.distance(from: location)
        
        if distanceMeters < 1000 {
            return "\(Int(distanceMeters))m away"
        } else {
            let km = distanceMeters / 1000
            return String(format: "%.1fkm away", km)
        }
    }
}
