//
//  LocationService.swift
//
//  Created by Dave Neff
//

import Foundation
import CoreLocation

final class LocationService: NSObject {

    // Completion handler typealiases
    typealias AuthorizationRequestClosure = ((_ isAuthorized: Bool) -> Void)
    typealias LocationRequestClosure = ((CLLocation?, LocationError?) -> Void)

    // Properties
    private var locationManager: CLLocationManager?
    
    private var authorizationRequestHandler: AuthorizationRequestClosure?
    private var locationRequestHandler: LocationRequestClosure?
    
    private var isAuthorized: Bool {
        return CLLocationManager.authorizationStatus() == .authorizedWhenInUse
    }
    
    deinit {
        deinitialize()
    }

}

// MARK: - Manager init / deinit

extension LocationService {
    
    private func initializeLocationManager() {
        locationManager = CLLocationManager()
        locationManager!.delegate = self
    }
    
    private func deinitialize() {
        locationManager?.stopUpdatingLocation()
        locationManager?.delegate = nil
        locationManager = nil
        
        locationRequestHandler = nil
        authorizationRequestHandler = nil
    }
    
}

// MARK: - Public methods

extension LocationService {
    
    func requestAuthorization(_ completion: @escaping AuthorizationRequestClosure) {
        // If already authorized, return true
        if isAuthorized {
            completion(true)
        } else {
            // Initialize manager
            initializeLocationManager()
            
            // Set authorization handler as completion block
            authorizationRequestHandler = completion
            
            // Ask manager for authorization (authorization handler is called in CL delegate method)
            locationManager?.requestWhenInUseAuthorization()
        }
    }
    
    func requestLocation() {
        guard isAuthorized else { return }
        initializeLocationManager()
        locationManager?.requestLocation()
    }
    
    func requestLocationName(_ completion: @escaping (String?, LocationError?) -> Void) {
        guard isAuthorized else {
            completion(nil, .unauthorized("Location has not been authorized"))
            return
        }
        
        // Initialize manager
        initializeLocationManager()
        
        // If location has already been fetched, get its name
        if let location = locationManager?.location {
            
            reverseGeocode(location, { (name, error) in
                if let name = name {
                    completion(name, nil)
                } else if let error = error {
                    completion(nil, error)
                }
            })
        
        // Otherwise, fetch a new one
        } else {
            
            // Set request handler
            locationRequestHandler = { location, error in
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let location = location else {
                    completion(nil, .fetchFailed("Location failed"))
                    return
                }
                
                self.reverseGeocode(location) { name, error  in
                    if let name = name { completion(name, nil) } else
                    if let error = error { completion(nil, error) }
                }
            }
            
            // Ask manager for location (request handler is called in CL delegate method)
            locationManager?.requestLocation()
        }
    }
    
}

// MARK: - CLLocation delegate

extension LocationService: CLLocationManagerDelegate {
    
    internal func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            return
        case .authorizedWhenInUse:
            authorizationRequestHandler?(true)
        default:
            authorizationRequestHandler?(false)
        }
        
        deinitialize()
    }

    internal func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        locationRequestHandler?(location, nil)
        deinitialize()
    }

    internal func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationRequestHandler?(nil, .fetchFailed(error.localizedDescription))
        deinitialize()
    }
    
}

// MARK: - Private methods

extension LocationService {
    
    /** Takes a location and uses reverse geocoding to get the location name */
    private func reverseGeocode(_ location: CLLocation, _ completion: @escaping (String?, LocationError?) -> Void) {
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                completion(nil, .reverseGeocodeFailed(error.localizedDescription))
                return
            }
            
            guard let placemark = placemarks?.first else {
                completion(nil, .reverseGeocodeFailed("Failed to retrieve placemark"))
                return
            }
            
            // Creates and returns location string, in order of location granularity
            if let subLocality = placemark.subLocality, let city = placemark.locality {
                completion(subLocality + ", " + city, nil)
            } else if let city = placemark.locality, let state = placemark.administrativeArea {
                completion(city + ", " + state, nil)
            } else if let state = placemark.administrativeArea {
                completion(state, nil)
            } else if let country = placemark.country {
                completion(country, nil)
            } else {
                completion(nil, .reverseGeocodeFailed("Failed to parse placemark"))
            }
        }
    }
    
}
