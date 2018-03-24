//
//  LocationService.swift
//
//  Created by Dave Neff
//

import Foundation

enum LocationError: Error {
    
    case fetchFailed(String)
    case reverseGeocodeFailed(String)
    case unauthorized(String)
    
}

extension LocationError {
    
    var message: String {
        switch self {
        case .fetchFailed(let message),
             .reverseGeocodeFailed(let message),
             .unauthorized(let message):
            return message
        }
    }
    
}
