//
//  Location.swift
//  Leap
//
//  Created by Kiril Savino on 3/23/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

class Location: LeapModel {
    dynamic var name: String?
    dynamic var address: Address?
    dynamic var timeZone: TimeZone?
    dynamic var latitude: Float = 0.0
    dynamic var longitude: Float = 0.0
}
