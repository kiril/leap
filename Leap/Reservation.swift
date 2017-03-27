//
//  Reservation.swift
//  Leap
//
//  Created by Kiril Savino on 3/27/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

class Reservation: LeapModel {
    dynamic var resource: Resource?
    dynamic var startTime: Date?
    dynamic var endTime: Date?
    dynamic var units: Int = 1
}
