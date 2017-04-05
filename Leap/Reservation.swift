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
    dynamic var startTime: Int = 0
    dynamic var endTime: Int = 0
    dynamic var units: Int = 1
}
