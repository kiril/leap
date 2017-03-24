//
//  Address.swift
//  Leap
//
//  Created by Kiril Savino on 3/24/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

class Address: LeapModel {
    dynamic var title: String?
    dynamic var line1: String?
    dynamic var line2: String?
    dynamic var municipality: String?
    dynamic var state: String?
    dynamic var country: String?
    dynamic var code: String?
    dynamic var latitude: Float = 0.0
    dynamic var longitude: Float = 0.0
}
