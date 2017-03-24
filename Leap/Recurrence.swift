//
//  Recurrence.swift
//  Leap
//
//  Created by Kiril Savino on 3/24/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

class Recurrence: LeapModel {
    dynamic var startTime: Date?
    dynamic var endTime: Date?
    dynamic var recurCount: Int = 0
}
