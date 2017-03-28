//
//  Venue.swift
//  Leap
//
//  Created by Kiril Savino on 3/24/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

class Venue: LeapModel {
    dynamic var name: String = ""
    dynamic var location: Location?

    static func by(id: String) -> Venue? {
        return fetch(id: id)
    }
}
