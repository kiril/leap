//
//  GeoFence.swift
//  Leap
//
//  Created by Kiril Savino on 3/24/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import CoreLocation
import EventKit

class GeoFence: LeapModel {
    static func from(location: EKStructuredLocation?) -> GeoFence? {
        if let location = location, let coordinate = location.geoLocation?.coordinate {
            return GeoFence(value: ["radius": location.radius,
                                    "longitude": coordinate.latitude,
                                    "latitude": coordinate.latitude])
        }
        return nil
    }

    dynamic var name: String? = ""
    dynamic var radius: Double = 0.0
    dynamic var latitude: Double = 0.0
    dynamic var longitude: Double = 0.0

    func getCLLocation() -> CLLocation {
        return CLLocation(latitude: self.latitude, longitude: self.longitude)
    }
}
